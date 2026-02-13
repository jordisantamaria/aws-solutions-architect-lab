"""
Process Payment Lambda Function

Triggered by SQS messages from the orders queue.
Processes payment for each order and sends notifications via SNS.

Architecture flow:
  SQS (order message) -> Lambda (process payment) -> SNS (notification)
                                                   -> Aurora (update status)

If processing fails, SQS will retry up to 3 times before
sending the message to the Dead Letter Queue (DLQ).
"""

import json
import logging
import os
from datetime import datetime, timezone

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Environment variables
DB_HOST = os.environ.get("DB_HOST", "localhost")
DB_NAME = os.environ.get("DB_NAME", "ecommerce")
SNS_TOPIC_ARN = os.environ.get("SNS_TOPIC_ARN", "")

# AWS clients
sns = boto3.client("sns")


def handler(event, context):
    """
    Process payment for orders from SQS queue.

    Each SQS message contains an order that needs payment processing.
    On success, sends an SNS notification and updates the order status.
    On failure, lets the message return to the queue for retry.

    Args:
        event: SQS event with batch of messages
        context: Lambda context

    Returns:
        dict with batch item failures for partial batch responses
    """
    logger.info("Processing %d order(s) from SQS", len(event.get("Records", [])))

    batch_item_failures = []

    for record in event.get("Records", []):
        message_id = record.get("messageId", "unknown")

        try:
            # Parse order from SQS message
            order = json.loads(record.get("body", "{}"))
            order_id = order.get("order_id", "unknown")
            user_email = order.get("user_email", "unknown")
            total = order.get("total", 0)

            logger.info(
                "Processing payment for order %s, total: $%.2f",
                order_id, total
            )

            # --- Step 1: Process payment ---
            # In production, integrate with a payment provider (Stripe, etc.)
            payment_result = process_payment_mock(order)

            if not payment_result["success"]:
                raise Exception(
                    f"Payment failed for order {order_id}: "
                    f"{payment_result.get('error', 'Unknown error')}"
                )

            logger.info(
                "Payment successful for order %s, transaction: %s",
                order_id,
                payment_result.get("transaction_id"),
            )

            # --- Step 2: Update order status in Aurora ---
            # In production:
            # conn = psycopg2.connect(host=DB_HOST, dbname=DB_NAME, ...)
            # cursor = conn.cursor()
            # cursor.execute(
            #     "UPDATE orders SET status = %s, payment_id = %s, updated_at = %s "
            #     "WHERE order_id = %s",
            #     ("PAID", payment_result["transaction_id"],
            #      datetime.now(timezone.utc).isoformat(), order_id)
            # )
            # conn.commit()

            logger.info("Order %s status updated to PAID (mock)", order_id)

            # --- Step 3: Send SNS notification ---
            if SNS_TOPIC_ARN:
                notification = {
                    "order_id": order_id,
                    "status": "PAID",
                    "total": total,
                    "user_email": user_email,
                    "transaction_id": payment_result.get("transaction_id"),
                    "processed_at": datetime.now(timezone.utc).isoformat(),
                }

                sns.publish(
                    TopicArn=SNS_TOPIC_ARN,
                    Subject=f"Order {order_id} - Payment Confirmed",
                    Message=json.dumps(notification, indent=2),
                    MessageAttributes={
                        "event_type": {
                            "DataType": "String",
                            "StringValue": "ORDER_PAID",
                        },
                        "order_id": {
                            "DataType": "String",
                            "StringValue": order_id,
                        },
                    },
                )
                logger.info("Notification sent for order %s", order_id)
            else:
                logger.warning("SNS_TOPIC_ARN not set, skipping notification")

        except Exception as e:
            logger.error(
                "Failed to process message %s: %s", message_id, str(e)
            )
            # Report this message as failed for partial batch response
            # SQS will make it visible again for retry
            batch_item_failures.append({
                "itemIdentifier": message_id
            })

    # Return partial batch failures
    # Messages not in this list are considered successfully processed
    result = {
        "batchItemFailures": batch_item_failures
    }

    logger.info(
        "Batch processing complete. Success: %d, Failures: %d",
        len(event.get("Records", [])) - len(batch_item_failures),
        len(batch_item_failures),
    )

    return result


def process_payment_mock(order):
    """
    Mock payment processing.

    In production, this would call a payment provider API like Stripe:
        stripe.PaymentIntent.create(
            amount=int(order["total"] * 100),
            currency="usd",
            customer=order["user_id"],
        )

    Args:
        order: Order dict with total, user_id, items, etc.

    Returns:
        dict with success status and transaction details
    """
    import uuid

    order_id = order.get("order_id", "unknown")
    total = order.get("total", 0)

    # Simulate payment processing
    # In a real scenario, this would validate card, check funds, etc.
    if total <= 0:
        return {
            "success": False,
            "error": "Invalid order total",
        }

    # Simulate a 95% success rate
    import random
    if random.random() < 0.05:
        return {
            "success": False,
            "error": "Payment declined by provider",
        }

    return {
        "success": True,
        "transaction_id": f"TXN-{uuid.uuid4().hex[:12].upper()}",
        "amount_charged": total,
        "currency": "USD",
        "payment_method": "card_mock",
        "processed_at": datetime.now(timezone.utc).isoformat(),
    }
