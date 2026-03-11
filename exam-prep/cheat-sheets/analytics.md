# Analytics and Big Data - Cheat Sheet

## When to Use Each Service

| Need | Service | Key to Remember |
|------|---------|-----------------|
| SQL on S3 without infra | **Athena** | Serverless, $5/TB scanned |
| Centralized data catalog | **Glue Data Catalog** | Metastore for Athena/EMR/Redshift |
| Automatically discover schema | **Glue Crawler** | Scans S3/RDS → creates tables in catalog |
| Serverless ETL | **Glue ETL** | Spark under the hood |
| No-code visual ETL | **Glue DataBrew** | Cleaning and normalization |
| Big data (Hadoop/Spark/Hive) | **EMR** | Managed cluster, Task Nodes with Spot |
| Spark without cluster | **EMR Serverless** or **Glue** | No infra |
| Dashboards / BI | **QuickSight** | SPICE = in-memory engine |
| Full-text search | **OpenSearch** | Ex-Elasticsearch |
| Real-time log analytics | **OpenSearch** + Dashboards | Ex-Kibana |
| AWS-native streaming | **Kinesis** | Data Streams + Firehose |
| Kafka streaming | **MSK** | Portable, Kafka ecosystem |
| Data lake governance | **Lake Formation** | Column/row-level permissions on S3 |
| SQL data warehouse | **Redshift** | MPP, columnar, petabyte-scale |
| Convert CSV → Parquet | **Glue ETL** | Columnar format = cheaper Athena |

## Quick Differentiators

| Exam Question | Answer |
|---------------|--------|
| "Analyze data in S3 with SQL" | Athena |
| "Data warehouse with complex joins" | Redshift |
| "Serverless ETL" | Glue |
| "Hadoop, Spark, Hive, HBase" | EMR |
| "BI, dashboards, visualization" | QuickSight |
| "Elasticsearch, Kibana, search" | OpenSearch |
| "Kafka on AWS" | MSK |
| "Column-level security in data lake" | Lake Formation |
| "Discover schema in S3" | Glue Crawler |
| "Data catalog" | Glue Data Catalog |
| "Streaming to S3 near real-time" | Kinesis Firehose |
| "SPICE" | QuickSight |
| "Reduce Athena cost" | Parquet + partitioning + compression |
| "Spot Instances for big data" | EMR Task Nodes |
| "Row-level security in dashboards" | QuickSight Enterprise |

## Typical Data Lake Pipeline

```
Ingestion → Storage → Catalog → Processing → Consumption

Kinesis/MSK → S3 (raw) → Glue Crawler → Glue ETL → S3 (Parquet)
                          (Data Catalog)              ↓
                                                Lake Formation (security)
                                                      ↓
                                          Athena / Redshift / QuickSight
```

## Costs

| Service | Pricing Model |
|---------|---------------|
| **Athena** | $5/TB scanned (reduce with Parquet/partitioning) |
| **Glue** | DPU-hour (Data Processing Unit). Crawlers: by execution time |
| **EMR** | EC2 instances in the cluster + EMR fee (~15-25% on top of EC2) |
| **QuickSight** | Per user/month (Standard ~$9, Enterprise ~$18) or per session |
| **OpenSearch** | Cluster instances + storage |
| **MSK** | Per broker-hour + storage |
| **Lake Formation** | Free (you pay for underlying services: S3, Glue, etc.) |
| **Redshift** | Per node-hour (or Redshift Serverless: per RPU) |
