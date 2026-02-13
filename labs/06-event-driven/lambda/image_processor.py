"""
Image Processor Lambda Function

Triggered by SQS messages originating from S3 upload events.
Logs the details of the uploaded file for processing.
In a real-world scenario, this would perform image transformations,
thumbnail generation, metadata extraction, etc.
"""

import json
import logging
import os

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handler(event, context):
    """
    Process SQS messages containing S3 upload event details.

    Args:
        event: SQS event containing one or more messages
        context: Lambda context object
    """
    logger.info("Image processor invoked with %d record(s)", len(event.get("Records", [])))

    processed = 0
    errors = 0

    for record in event.get("Records", []):
        try:
            # Parse the message body (S3 event from EventBridge via SNS)
            body = json.loads(record["body"])

            # Extract S3 object details from the EventBridge event
            detail = body.get("detail", body)
            bucket_name = detail.get("bucket", {}).get("name", "unknown")
            object_key = detail.get("object", {}).get("key", "unknown")
            object_size = detail.get("object", {}).get("size", 0)

            logger.info(
                "Processing image - Bucket: %s, Key: %s, Size: %d bytes",
                bucket_name,
                object_key,
                object_size,
            )

            # Simulate image processing logic
            # In production, this would:
            # - Download the image from S3
            # - Generate thumbnails
            # - Extract EXIF metadata
            # - Store results in DynamoDB
            logger.info(
                "Image processing complete for %s/%s",
                bucket_name,
                object_key,
            )

            processed += 1

        except Exception as e:
            logger.error("Error processing record: %s", str(e))
            errors += 1
            raise  # Re-raise to send message to DLQ after max retries

    logger.info(
        "Batch complete - Processed: %d, Errors: %d",
        processed,
        errors,
    )

    return {
        "statusCode": 200,
        "body": json.dumps({
            "processed": processed,
            "errors": errors,
        }),
    }
