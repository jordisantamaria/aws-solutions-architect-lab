# Lab 07: Data Pipeline - Streaming and Batch

## Objective

Build a complete data pipeline that processes data both in streaming (real-time) and batch, using AWS analytics services.

## Architecture

```
                                    +------------------+
                                    |   Lambda         |
                                    |   (real-time     |
                                    |    processing)   |
                                    +--------^---------+
                                             |
+-----------+    +------------------+    +----+-------------+    +------------------+
| Producers |-->| Kinesis Data     |--->| Kinesis Data     |--->| S3 Data Lake     |
| (apps,    |    | Streams          |    | Firehose         |    | (raw/processed)  |
| sensors)  |    | (1 shard)        |    | (buffer 60s)     |    |                  |
+-----------+    +------------------+    +------------------+    +--------+---------+
                                                                          |
                                                                  +-------v--------+
                                                                  | AWS Glue       |
                                                                  | Catalog        |
                                                                  | (schema)       |
                                                                  +-------+--------+
                                                                          |
                                                                  +-------v--------+
                                                                  | Amazon Athena  |
                                                                  | (SQL queries)  |
                                                                  +----------------+
```

## What you will learn

- **Kinesis Data Streams**: streaming data ingestion with shards and partitions
- **Kinesis Data Firehose**: automatic data delivery to destinations (S3, Redshift, etc.)
- **Data Lake on S3**: centralized data storage with lifecycle policies
- **AWS Glue Catalog**: metadata catalog for defining data schemas
- **Amazon Athena**: serverless SQL queries on data in S3
- **Lambda with Kinesis**: real-time event processing from the stream

## Deployed Components

| Resource | Description | Estimated cost |
|---------|-------------|----------------|
| Kinesis Data Stream | 1 shard for ingestion | ~$0.36/day |
| Kinesis Firehose | Delivery stream to S3 | ~$0.01/GB |
| S3 Data Lake | Data storage | ~$0.023/GB/month |
| Lambda | Real-time processor | Free tier |
| Glue Catalog | Metadata catalog | Free (first 1M objects) |
| Athena | SQL queries | ~$5/TB scanned |

## Estimated Total Cost

**~$1-2/day** (mainly due to the Kinesis shard active 24/7)

> **Note**: The Kinesis shard has a fixed hourly cost. Destroy the infrastructure when you are not using it.

## How to Deploy

```bash
# Initialize Terraform
terraform init

# View the execution plan
terraform plan

# Deploy the infrastructure
terraform apply

# When finished, destroy everything
terraform destroy
```

## How to Send Test Data to the Stream

Use the included `test_producer.py` script to send simulated sensor events:

```bash
# Install dependencies
pip install boto3

# Send 100 test records
python test_producer.py

# Send records continuously (1 per second)
python test_producer.py --continuous
```

The script sends JSON records in this format:

```json
{
  "sensor_id": "sensor-001",
  "temperature": 23.5,
  "humidity": 65.2,
  "timestamp": "2024-01-15T10:30:00Z",
  "location": "warehouse-A"
}
```

## Query Data with Athena

Once Firehose has delivered data to S3 (wait at least 60 seconds for the buffer):

```sql
-- Query the latest records
SELECT * FROM sensor_data
ORDER BY timestamp DESC
LIMIT 10;

-- Average temperature per sensor
SELECT sensor_id, AVG(temperature) as avg_temp
FROM sensor_data
GROUP BY sensor_id;

-- High temperature alerts
SELECT sensor_id, temperature, timestamp
FROM sensor_data
WHERE temperature > 30.0
ORDER BY timestamp DESC;
```

## Key Concepts for the Exam

1. **Kinesis Data Streams vs Firehose**: Streams requires custom consumers, Firehose automatically delivers to destinations
2. **Shards**: each shard supports 1MB/s input and 2MB/s output
3. **Partition Key**: determines which shard each record goes to
4. **Firehose Buffer**: configurable by time (60-900s) and size (1-128MB)
5. **Athena**: serverless, pay per data scanned, use columnar format (Parquet) to optimize
6. **Glue Catalog**: compatible with Hive metastore, central for analytics services

## Cleanup

```bash
terraform destroy
```

> **Important**: Verify that S3 buckets are empty. Terraform may fail when deleting buckets with objects.
