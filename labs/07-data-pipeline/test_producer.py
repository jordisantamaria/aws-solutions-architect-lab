#!/usr/bin/env python3
"""
Test Producer for Kinesis Data Stream

Sends simulated sensor data records to the Kinesis Data Stream
for testing the data pipeline.

Usage:
    python test_producer.py
    python test_producer.py --stream-name my-stream --region eu-west-1
    python test_producer.py --continuous --interval 1
    python test_producer.py --count 500
"""

import argparse
import json
import random
import sys
import time
import uuid
from datetime import datetime, timezone

import boto3
from botocore.exceptions import ClientError

# Simulated sensor configuration
SENSORS = [
    {"sensor_id": "sensor-001", "location": "warehouse-A"},
    {"sensor_id": "sensor-002", "location": "warehouse-A"},
    {"sensor_id": "sensor-003", "location": "warehouse-B"},
    {"sensor_id": "sensor-004", "location": "warehouse-B"},
    {"sensor_id": "sensor-005", "location": "office-1"},
    {"sensor_id": "sensor-006", "location": "office-2"},
    {"sensor_id": "sensor-007", "location": "server-room"},
    {"sensor_id": "sensor-008", "location": "loading-dock"},
]


def generate_sensor_record():
    """
    Generate a simulated sensor data record.

    Returns:
        dict: Sensor reading with temperature, humidity, timestamp, etc.
    """
    sensor = random.choice(SENSORS)

    # Generate realistic temperature values (with occasional anomalies)
    base_temp = {
        "warehouse-A": 22.0,
        "warehouse-B": 24.0,
        "office-1": 21.0,
        "office-2": 22.0,
        "server-room": 18.0,
        "loading-dock": 15.0,
    }.get(sensor["location"], 20.0)

    # 5% chance of anomalous reading
    if random.random() < 0.05:
        temperature = base_temp + random.uniform(15.0, 25.0)
    else:
        temperature = base_temp + random.uniform(-3.0, 3.0)

    # Generate humidity values
    humidity = random.uniform(30.0, 80.0)
    if sensor["location"] == "server-room":
        humidity = random.uniform(40.0, 55.0)  # Controlled environment

    record = {
        "sensor_id": sensor["sensor_id"],
        "temperature": round(temperature, 2),
        "humidity": round(humidity, 2),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "location": sensor["location"],
        "event_id": str(uuid.uuid4()),
    }

    return record


def send_records(kinesis_client, stream_name, count=100):
    """
    Send a batch of records to the Kinesis stream.

    Args:
        kinesis_client: boto3 Kinesis client
        stream_name: Name of the Kinesis Data Stream
        count: Number of records to send

    Returns:
        tuple: (success_count, error_count)
    """
    success_count = 0
    error_count = 0

    # Kinesis PutRecords supports up to 500 records per call
    batch_size = 500
    records_to_send = []

    for i in range(count):
        record = generate_sensor_record()
        records_to_send.append({
            "Data": json.dumps(record).encode("utf-8"),
            "PartitionKey": record["sensor_id"],  # Partition by sensor for ordering
        })

        # Send batch when full or at the end
        if len(records_to_send) >= batch_size or i == count - 1:
            try:
                response = kinesis_client.put_records(
                    StreamName=stream_name,
                    Records=records_to_send,
                )

                # Check for failed records
                failed = response.get("FailedRecordCount", 0)
                success_count += len(records_to_send) - failed
                error_count += failed

                if failed > 0:
                    print(f"  Warning: {failed} records failed in batch")

                records_to_send = []

            except ClientError as e:
                print(f"  Error sending batch: {e}")
                error_count += len(records_to_send)
                records_to_send = []

    return success_count, error_count


def main():
    parser = argparse.ArgumentParser(
        description="Send test sensor data to Kinesis Data Stream"
    )
    parser.add_argument(
        "--stream-name",
        default="lab07-data-pipeline-data-stream",
        help="Name of the Kinesis Data Stream (default: lab07-data-pipeline-data-stream)",
    )
    parser.add_argument(
        "--region",
        default="eu-west-1",
        help="AWS region (default: eu-west-1)",
    )
    parser.add_argument(
        "--count",
        type=int,
        default=100,
        help="Number of records to send (default: 100)",
    )
    parser.add_argument(
        "--continuous",
        action="store_true",
        help="Send records continuously",
    )
    parser.add_argument(
        "--interval",
        type=float,
        default=1.0,
        help="Seconds between records in continuous mode (default: 1.0)",
    )

    args = parser.parse_args()

    # Create Kinesis client
    kinesis_client = boto3.client("kinesis", region_name=args.region)

    # Verify the stream exists
    try:
        response = kinesis_client.describe_stream_summary(
            StreamName=args.stream_name
        )
        stream_status = response["StreamDescriptionSummary"]["StreamStatus"]
        shard_count = response["StreamDescriptionSummary"]["OpenShardCount"]
        print(f"Stream: {args.stream_name}")
        print(f"Status: {stream_status}")
        print(f"Shards: {shard_count}")
        print("-" * 50)
    except ClientError as e:
        print(f"Error: Could not find stream '{args.stream_name}': {e}")
        sys.exit(1)

    if args.continuous:
        # Continuous mode: send one record at a time
        print(f"Sending records continuously (interval: {args.interval}s)")
        print("Press Ctrl+C to stop")
        print("-" * 50)

        total_sent = 0
        try:
            while True:
                record = generate_sensor_record()
                try:
                    kinesis_client.put_record(
                        StreamName=args.stream_name,
                        Data=json.dumps(record).encode("utf-8"),
                        PartitionKey=record["sensor_id"],
                    )
                    total_sent += 1
                    print(
                        f"[{total_sent}] Sent: sensor={record['sensor_id']}, "
                        f"temp={record['temperature']}C, "
                        f"humidity={record['humidity']}%, "
                        f"location={record['location']}"
                    )
                except ClientError as e:
                    print(f"Error sending record: {e}")

                time.sleep(args.interval)

        except KeyboardInterrupt:
            print(f"\nStopped. Total records sent: {total_sent}")
    else:
        # Batch mode: send N records
        print(f"Sending {args.count} records to stream '{args.stream_name}'...")
        start_time = time.time()

        success, errors = send_records(kinesis_client, args.stream_name, args.count)

        elapsed = time.time() - start_time
        print(f"\nResults:")
        print(f"  Successful: {success}")
        print(f"  Failed:     {errors}")
        print(f"  Time:       {elapsed:.2f}s")
        print(f"  Rate:       {success / elapsed:.1f} records/s")

    # Print a sample record for reference
    print("\nSample record format:")
    sample = generate_sensor_record()
    print(json.dumps(sample, indent=2))


if __name__ == "__main__":
    main()
