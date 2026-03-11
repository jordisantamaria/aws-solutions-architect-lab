# Decision Tree: Analytics Service Selection

## What do you need to do with the data?

```
What do you need to do?
│
├── QUERY data
│   ├── Where is the data?
│   │   ├── In S3 → Ad-hoc or recurring query?
│   │   │   ├── Ad-hoc, pay-per-query → Athena
│   │   │   └── Complex, recurring queries, massive joins → Redshift (or Redshift Spectrum on S3)
│   │   ├── In multiple sources (S3 + RDS + DynamoDB) → Athena Federated Query
│   │   └── Logs in CloudWatch → CloudWatch Logs Insights
│   │
│   └── Do you need full-text search?
│       └── Yes → OpenSearch
│
├── TRANSFORM data (ETL)
│   ├── Serverless or cluster control?
│   │   ├── Serverless, integrated with catalog → Glue ETL
│   │   ├── Serverless, Spark without managing → EMR Serverless
│   │   ├── Full control (custom Spark/Hadoop) → EMR on EC2
│   │   └── Simple transformation (< 15 min) → Lambda
│   │
│   └── No-code?
│       └── Glue DataBrew
│
├── STREAMING data
│   ├── Kafka or AWS-native?
│   │   ├── Kafka (portability, existing ecosystem) → MSK
│   │   ├── Kafka serverless → MSK Serverless
│   │   ├── AWS-native, simple integration with Lambda/S3 → Kinesis Data Streams
│   │   └── Delivery to S3/Redshift/OpenSearch without code → Kinesis Data Firehose
│   │
│   └── Real-time SQL analysis on stream?
│       └── Kinesis Data Analytics (Apache Flink)
│
├── VISUALIZE data (dashboards)
│   └── QuickSight
│       ├── Standard: basic
│       └── Enterprise: row-level security, embedded, AD integration
│
├── CATALOG data
│   ├── Metastore only → Glue Data Catalog
│   ├── Discover schema automatically → Glue Crawler
│   └── Governance + column/row-level security → Lake Formation
│
└── MOVE data
    ├── Database → database → DMS
    ├── On-premises → S3 (network) → DataSync
    ├── On-premises → S3 (physical, TB/PB) → Snow Family
    └── Kafka → S3/OpenSearch → MSK Connect
```

## Frequent Exam Comparisons

### Athena vs Redshift

| Criterion | Athena | Redshift |
|-----------|--------|----------|
| Model | Serverless | Cluster (or Serverless) |
| Data | In S3 (does not move it) | Loaded into Redshift (or Spectrum on S3) |
| Best for | Ad-hoc queries, exploratory analysis | Data warehouse, complex recurring queries |
| Cost | $5/TB scanned | Per node-hour (fixed) |
| Performance | Good for simple queries | Superior for massive joins and complex queries |

### Glue vs EMR

| Criterion | Glue | EMR |
|-----------|------|-----|
| Model | Serverless | Managed cluster (or serverless) |
| Engine | Spark (managed) | Spark, Hadoop, Hive, Presto, Flink... |
| Control | Limited | Full (you can install libraries, configure cluster) |
| Integration | Native Data Catalog | Any Hadoop ecosystem |
| Best for | Standard ETL, format conversion | Complex big data, ML with Spark, custom frameworks |

### Kinesis vs MSK

| Criterion | Kinesis | MSK |
|-----------|---------|-----|
| Protocol | AWS proprietary API | Apache Kafka (open source) |
| Model | Shards (serverless-like) | Brokers (cluster) or Serverless |
| Portability | AWS lock-in | Multi-cloud (standard Kafka) |
| Integration | Lambda, Firehose, Analytics (native AWS) | Kafka Connect, Kafka Streams, KSQL |
| Best for | Simple integration with AWS | Teams with Kafka experience, portability |

### OpenSearch vs CloudWatch Logs Insights

| Criterion | OpenSearch | CloudWatch Logs Insights |
|-----------|-----------|------------------------|
| Model | Cluster (or serverless) | Serverless (pay per query) |
| Functionality | Full-text search, dashboards, alerts | Ad-hoc log queries |
| Setup | Medium-high | Zero (already integrated with CloudWatch) |
| Best for | Large-scale logs with real-time dashboards | Quick log analysis without additional infra |
