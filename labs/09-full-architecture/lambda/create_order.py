"""
Create Order Lambda Function

Creates a new order in Aurora PostgreSQL and sends a message
to SQS for asynchronous payment processing.

This decoupled architecture ensures:
- Fast API response (order created immediately)
- Reliable payment processing (SQS guarantees delivery)
- Retry handling via DLQ if payment fails
"""

import json
import logging
import os
import uuid
from datetime import datetime, timezone

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Environment variables
DB_HOST = os.environ.get("DB_HOST", "localhost")
DB_NAME = os.environ.get("DB_NAME", "ecommerce")
SQS_QUEUE_URL = os.environ.get("SQS_QUEUE_URL", "")

# SQS client
sqs = boto3.client("sqs")


def handler(event, context):
    """
    Handle POST /orders request.

    Creates an order record and sends it to SQS for payment processing.

    Args:
        event: API Gateway proxy event
        context: Lambda context

    Returns:
        API Gateway proxy response
    """
    logger.info("Create order request received")

    try:
        # Parse request body
        body = json.loads(event.get("body", "{}"))

        # Extract user info from Cognito authorizer
        claims = event.get("requestContext", {}).get("authorizer", {}).get("claims", {})
        user_id = claims.get("sub", "anonymous")
        user_email = claims.get("email", "unknown@example.com")

        # Validate required fields
        items = body.get("items", [])
        if not items:
            return response(400, {"error": "Order must contain at least one item"})

        shipping_address = body.get("shipping_address")
        if not shipping_address:
            return response(400, {"error": "Shipping address is required"})

        # Generate order ID
        order_id = f"ORD-{uuid.uuid4().hex[:8].upper()}"

        # Calculate order total
        total = sum(
            item.get("price", 0) * item.get("quantity", 1)
            for item in items
        )

        # Build order object
        order = {
            "order_id": order_id,
            "user_id": user_id,
            "user_email": user_email,
            "items": items,
            "total": round(total, 2),
            "shipping_address": shipping_address,
            "status": "PENDING",
            "created_at": datetime.now(timezone.utc).isoformat(),
        }

        logger.info("Creating order: %s for user: %s, total: $%.2f",
                     order_id, user_id, total)

        # --- Step 1: Save order to Aurora ---
        # In production, use psycopg2 to insert into the orders table:
        # import psycopg2
        # conn = psycopg2.connect(host=DB_HOST, dbname=DB_NAME, ...)
        # cursor = conn.cursor()
        # cursor.execute(
        #     "INSERT INTO orders (order_id, user_id, total, status, items, shipping_address, created_at) "
        #     "VALUES (%s, %s, %s, %s, %s, %s, %s)",
        #     (order_id, user_id, total, "PENDING",
        #      json.dumps(items), json.dumps(shipping_address),
        #      order["created_at"])
        # )
        # conn.commit()

        logger.info("Order %s saved to database (mock)", order_id)

        # --- Step 2: Send to SQS for payment processing ---
        if SQS_QUEUE_URL:
            sqs_response = sqs.send_message(
                QueueUrl=SQS_QUEUE_URL,
                MessageBody=json.dumps(order),
                MessageAttributes={
                    "OrderId": {
                        "DataType": "String",
                        "StringValue": order_id,
                    },
                    "UserId": {
                        "DataType": "String",
                        "StringValue": user_id,
                    },
                },
                # Use order_id as deduplication for FIFO queues
                # MessageGroupId=user_id,  # For FIFO queues
            )
            logger.info(
                "Order %s sent to SQS, MessageId: %s",
                order_id,
                sqs_response.get("MessageId"),
            )
        else:
            logger.warning("SQS_QUEUE_URL not set, skipping queue")

        # Return success response
        return response(201, {
            "message": "Order created successfully",
            "order": {
                "order_id": order_id,
                "total": total,
                "status": "PENDING",
                "created_at": order["created_at"],
            },
        })

    except json.JSONDecodeError:
        logger.error("Invalid JSON in request body")
        return response(400, {"error": "Invalid JSON in request body"})
    except Exception as e:
        logger.error("Error creating order: %s", str(e))
        return response(500, {"error": "Internal server error"})


def response(status_code, body):
    """Build API Gateway proxy response."""
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type,Authorization",
        },
        "body": json.dumps(body),
    }
