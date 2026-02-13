"""
Lambda handler for CRUD operations on DynamoDB items table.
Receives events from API Gateway (Lambda Proxy Integration).
"""

import json
import os
import uuid
from datetime import datetime

import boto3
from botocore.exceptions import ClientError

# Initialize DynamoDB resource
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])


def lambda_handler(event, context):
    """
    Main entry point for the Lambda function.
    Routes requests based on HTTP method and resource path.
    """
    http_method = event["httpMethod"]
    path = event["resource"]

    try:
        if path == "/items" and http_method == "GET":
            return get_all_items()
        elif path == "/items" and http_method == "POST":
            return create_item(event)
        elif path == "/items/{id}" and http_method == "GET":
            item_id = event["pathParameters"]["id"]
            return get_item(item_id)
        elif path == "/items/{id}" and http_method == "PUT":
            item_id = event["pathParameters"]["id"]
            return update_item(item_id, event)
        elif path == "/items/{id}" and http_method == "DELETE":
            item_id = event["pathParameters"]["id"]
            return delete_item(item_id)
        else:
            return build_response(404, {"error": "Route not found"})

    except ClientError as e:
        print(f"DynamoDB error: {e.response['Error']['Message']}")
        return build_response(500, {"error": "Internal server error"})
    except Exception as e:
        print(f"Unexpected error: {str(e)}")
        return build_response(500, {"error": "Internal server error"})


def get_all_items():
    """Scan the table and return all items."""
    response = table.scan()
    items = response.get("Items", [])

    return build_response(200, {"items": items, "count": len(items)})


def get_item(item_id):
    """Get a single item by its ID."""
    response = table.get_item(Key={"id": item_id})
    item = response.get("Item")

    if not item:
        return build_response(404, {"error": f"Item {item_id} not found"})

    return build_response(200, item)


def create_item(event):
    """Create a new item with an auto-generated UUID."""
    body = json.loads(event.get("body", "{}"))

    if not body:
        return build_response(400, {"error": "Request body is required"})

    item_id = str(uuid.uuid4())
    timestamp = datetime.utcnow().isoformat()

    item = {
        "id": item_id,
        "createdAt": timestamp,
        "updatedAt": timestamp,
    }

    # Add all fields from the request body
    for key, value in body.items():
        if key != "id":  # Prevent overriding the generated ID
            item[key] = value

    table.put_item(Item=item)

    return build_response(201, {"message": "Item created", "item": item})


def update_item(item_id, event):
    """Update an existing item."""
    body = json.loads(event.get("body", "{}"))

    if not body:
        return build_response(400, {"error": "Request body is required"})

    # Check if the item exists
    existing = table.get_item(Key={"id": item_id})
    if "Item" not in existing:
        return build_response(404, {"error": f"Item {item_id} not found"})

    # Build the update expression dynamically
    update_expression_parts = ["#updatedAt = :updatedAt"]
    expression_attribute_names = {"#updatedAt": "updatedAt"}
    expression_attribute_values = {":updatedAt": datetime.utcnow().isoformat()}

    for key, value in body.items():
        if key not in ("id", "createdAt"):  # Prevent updating immutable fields
            placeholder = f"#{key}"
            value_placeholder = f":{key}"
            update_expression_parts.append(f"{placeholder} = {value_placeholder}")
            expression_attribute_names[placeholder] = key
            expression_attribute_values[value_placeholder] = value

    update_expression = "SET " + ", ".join(update_expression_parts)

    response = table.update_item(
        Key={"id": item_id},
        UpdateExpression=update_expression,
        ExpressionAttributeNames=expression_attribute_names,
        ExpressionAttributeValues=expression_attribute_values,
        ReturnValues="ALL_NEW",
    )

    return build_response(200, {
        "message": "Item updated",
        "item": response["Attributes"],
    })


def delete_item(item_id):
    """Delete an item by its ID."""
    # Check if the item exists
    existing = table.get_item(Key={"id": item_id})
    if "Item" not in existing:
        return build_response(404, {"error": f"Item {item_id} not found"})

    table.delete_item(Key={"id": item_id})

    return build_response(200, {"message": f"Item {item_id} deleted"})


def build_response(status_code, body):
    """Build a standardized API Gateway response."""
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type",
        },
        "body": json.dumps(body, default=str),
    }
