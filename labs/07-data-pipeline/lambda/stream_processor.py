"""
Kinesis Stream Processor Lambda Function

Processes records from a Kinesis Data Stream in real-time.
Each record is base64-decoded, parsed as JSON, and can be
transformed or used to trigger alerts.

This function is triggered by the Kinesis event source mapping.
"""

import base64
import json
import logging
import os
from datetime import datetime

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Environment variables
PROJECT_NAME = os.environ.get("PROJECT_NAME", "data-pipeline")


def handler(event, context):
    """
    Process Kinesis stream records in real-time.

    Args:
        event: Kinesis event containing batch of records
        context: Lambda context object

    Returns:
        dict with processing results
    """
    records_processed = 0
    records_failed = 0
    high_temp_alerts = []

    logger.info(
        "Received %d records from Kinesis", len(event.get("Records", []))
    )

    for record in event.get("Records", []):
        try:
            # Decode the Kinesis record data (base64 encoded)
            payload = base64.b64decode(record["kinesis"]["data"]).decode("utf-8")
            data = json.loads(payload)

            # Log the received record
            logger.info(
                "Processing record: sensor_id=%s, partition_key=%s",
                data.get("sensor_id", "unknown"),
                record["kinesis"].get("partitionKey", "unknown"),
            )

            # === Real-time processing logic ===

            # Example 1: Check for high temperature alerts
            temperature = data.get("temperature", 0)
            if temperature > 35.0:
                alert = {
                    "sensor_id": data.get("sensor_id"),
                    "temperature": temperature,
                    "timestamp": data.get("timestamp"),
                    "location": data.get("location"),
                    "alert_type": "HIGH_TEMPERATURE",
                }
                high_temp_alerts.append(alert)
                logger.warning(
                    "HIGH TEMPERATURE ALERT: sensor=%s, temp=%.1f, location=%s",
                    data.get("sensor_id"),
                    temperature,
                    data.get("location"),
                )

            # Example 2: Check for humidity anomalies
            humidity = data.get("humidity", 0)
            if humidity > 90.0 or humidity < 10.0:
                logger.warning(
                    "HUMIDITY ANOMALY: sensor=%s, humidity=%.1f",
                    data.get("sensor_id"),
                    humidity,
                )

            # Example 3: Data enrichment (add processing metadata)
            enriched_data = {
                **data,
                "processed_at": datetime.utcnow().isoformat(),
                "processor": context.function_name,
                "stream_shard": record["kinesis"].get("partitionKey"),
                "sequence_number": record["kinesis"].get("sequenceNumber"),
            }

            # In a real scenario, you could:
            # - Write enriched data to DynamoDB
            # - Send alerts via SNS
            # - Update a real-time dashboard via API Gateway WebSocket
            # - Aggregate metrics in CloudWatch

            logger.debug("Enriched record: %s", json.dumps(enriched_data))
            records_processed += 1

        except json.JSONDecodeError as e:
            logger.error("Failed to parse JSON from record: %s", str(e))
            records_failed += 1
        except KeyError as e:
            logger.error("Missing expected field in record: %s", str(e))
            records_failed += 1
        except Exception as e:
            logger.error("Unexpected error processing record: %s", str(e))
            records_failed += 1

    # Log processing summary
    result = {
        "records_processed": records_processed,
        "records_failed": records_failed,
        "high_temp_alerts": len(high_temp_alerts),
        "batch_size": len(event.get("Records", [])),
    }

    logger.info("Processing complete: %s", json.dumps(result))

    # If there were alerts, log them for CloudWatch Insights
    if high_temp_alerts:
        logger.info(
            "Temperature alerts: %s", json.dumps(high_temp_alerts)
        )

    return result
