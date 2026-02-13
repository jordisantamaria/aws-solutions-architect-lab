"""
Audit Logger Lambda Function

Triggered by SQS messages originating from S3 upload events or API Gateway.
Logs audit information about the event for compliance and tracking purposes.
In a real-world scenario, this would write to DynamoDB, Timestream,
or an external audit system.
"""

import json
import logging
import os
from datetime import datetime, timezone

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handler(event, context):
    """
    Process SQS messages and log audit information.

    Args:
        event: SQS event containing one or more messages
        context: Lambda context object
    """
    environment = os.environ.get("ENVIRONMENT", "unknown")
    source = os.environ.get("SOURCE", "s3-events")

    logger.info(
        "Audit logger invoked - Environment: %s, Source: %s, Records: %d",
        environment,
        source,
        len(event.get("Records", [])),
    )

    audit_entries = []

    for record in event.get("Records", []):
        try:
            # Parse the message body
            body = json.loads(record["body"])

            # Build audit entry
            audit_entry = {
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "environment": environment,
                "source": source,
                "message_id": record.get("messageId", "unknown"),
                "event_source": record.get("eventSource", "unknown"),
            }

            # Extract details based on event source
            if "detail" in body:
                # EventBridge event (from S3 via SNS)
                detail = body["detail"]
                audit_entry.update({
                    "event_type": "s3_upload",
                    "bucket": detail.get("bucket", {}).get("name", "unknown"),
                    "object_key": detail.get("object", {}).get("key", "unknown"),
                    "object_size": detail.get("object", {}).get("size", 0),
                    "source_ip": detail.get("source-ip-address", "unknown"),
                })
            else:
                # Direct message (from API Gateway)
                audit_entry.update({
                    "event_type": "api_message",
                    "payload": body,
                })

            logger.info("Audit entry: %s", json.dumps(audit_entry))
            audit_entries.append(audit_entry)

            # In production, this would:
            # - Write to DynamoDB audit table
            # - Send to Kinesis Data Firehose for S3 archival
            # - Forward to external compliance system

        except Exception as e:
            logger.error("Error processing audit record: %s", str(e))
            raise  # Re-raise to send message to DLQ after max retries

    logger.info("Audit logging complete - %d entries recorded", len(audit_entries))

    return {
        "statusCode": 200,
        "body": json.dumps({
            "audit_entries": len(audit_entries),
        }),
    }
