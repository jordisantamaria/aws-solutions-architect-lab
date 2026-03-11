# Analytics and Big Data in AWS

## Table of Contents

- [Amazon Athena](#amazon-athena)
- [AWS Glue](#aws-glue)
- [Amazon EMR](#amazon-emr)
- [Amazon QuickSight](#amazon-quicksight)
- [Amazon OpenSearch Service](#amazon-opensearch-service)
- [Amazon MSK (Managed Streaming for Apache Kafka)](#amazon-msk)
- [AWS Lake Formation](#aws-lake-formation)
- [Reference Architecture: Data Lake on AWS](#reference-architecture-data-lake-on-aws)
- [Decision Tree: Choosing the Right Analytics Service](#decision-tree-choosing-the-right-analytics-service)
- [Analytics Exam Tips](#analytics-exam-tips)

---

## Amazon Athena

**Serverless** interactive query service that lets you run SQL directly on data stored in **S3**.

### Key Features

| Feature | Detail |
|---------|--------|
| **Model** | Serverless (no infrastructure to manage) |
| **Language** | Standard SQL (based on Presto/Trino) |
| **Data source** | S3 (primary), also connectors to other sources via Federated Query |
| **Supported formats** | CSV, JSON, Parquet, ORC, Avro, TSV |
| **Pricing** | $5 per TB scanned |
| **Integration** | Glue Data Catalog as metastore, QuickSight for visualization |

### Cost and Performance Optimization

Athena pricing is based on **data scanned**, so reducing scans = reducing cost:

| Technique | Savings | How |
|-----------|---------|-----|
| **Columnar formats (Parquet/ORC)** | Up to 90% | Only reads the columns you need, not the entire row |
| **Compression (gzip, snappy, zstd)** | 50-80% | Fewer bytes to read |
| **Partitioning** | Variable (huge) | Splits data by date/region/etc. Athena only reads relevant partitions |
| **Bucketing** | Variable | Groups data within a partition for more efficient queries |

**Partitioning example in S3:**

```
s3://mi-datalake/ventas/
    year=2024/month=01/data.parquet
    year=2024/month=02/data.parquet
    year=2025/month=01/data.parquet
```

```sql
-- Only scans the January 2025 partition, not the entire bucket
SELECT * FROM ventas WHERE year = 2025 AND month = 1;
```

### Athena Federated Query

- Allows running SQL on data sources **beyond S3**: DynamoDB, RDS, Redshift, CloudWatch Logs, on-premises (via JDBC).
- Uses **Lambda connectors** to connect to each source.
- Use case: queries that join data from S3 with data in DynamoDB or RDS without moving it.

### Main Use Cases

- Ad-hoc analysis of logs in S3 (VPC Flow Logs, ALB logs, CloudTrail logs).
- Business queries on a data lake in S3.
- Reporting that doesn't justify a permanent data warehouse (Redshift).
- Complement to QuickSight for dashboards.

> **Exam tip:** If the question says "analyze data in S3 with SQL", "serverless query", "no infrastructure", "pay per query" → **Athena**. If it says "data warehouse with complex queries, massive joins, structured data at large scale" → **Redshift**.

---

## AWS Glue

**Serverless** ETL (Extract, Transform, Load) service and data catalog.

### Components

| Component | Description |
|-----------|-------------|
| **Glue Data Catalog** | Centralized metastore. Stores table definitions, schemas, data locations. Used by Athena, Redshift Spectrum, EMR |
| **Glue Crawlers** | Scan data sources (S3, RDS, DynamoDB) and automatically discover the schema, creating tables in the Data Catalog |
| **Glue ETL Jobs** | Scripts (Python/Scala with Apache Spark) that transform data between sources |
| **Glue DataBrew** | Visual (no-code) tool for cleaning and normalizing data |
| **Glue Studio** | Visual interface for creating ETL jobs without writing code |

### Glue Data Catalog

```
Data sources (S3, RDS, DynamoDB)
    │
    ▼
Glue Crawler (scans and discovers schema)
    │
    ▼
Glue Data Catalog (centralized metastore)
    │
    ├── Athena uses the catalog to know what tables exist in S3
    ├── Redshift Spectrum uses the catalog for external queries
    └── EMR uses the catalog as Hive metastore
```

- The Data Catalog is the **glue** that connects analytics services.
- It is compatible with Apache Hive Metastore.
- Stores: databases, tables, partitions, column definitions, locations.

### Glue ETL Jobs

- Run on Apache Spark (serverless, AWS manages the cluster).
- Sources: S3, RDS, Redshift, DynamoDB, JDBC.
- Destinations: S3 (Parquet, ORC, JSON, CSV), Redshift, RDS, Glue Data Catalog.
- Supports **job bookmarks** to process only new data (incremental ETL).
- Transformations: map columns, filter, join, aggregate, change formats.

### Glue vs Other ETL Services

| Service | When to use |
|---------|-------------|
| **Glue ETL** | Serverless ETL, Spark transformations, integrated with Data Catalog |
| **EMR** | ETL with full cluster control, complex Spark/Hadoop workloads |
| **Lambda** | Simple and lightweight transformations (< 15 min, < 10 GB) |
| **Kinesis Data Firehose** | Lightweight transformations in streaming (near real-time) |
| **DMS** | Database-to-database migration (not complex transformation) |

> **Exam tip:** If the question mentions "automatically discover schema", "data catalog", "serverless ETL" → **Glue**. If it says "ETL with Spark/Hadoop and cluster control" → **EMR**. The Glue Data Catalog frequently appears as an answer when a centralized metastore is needed.

---

## Amazon EMR

Amazon EMR (Elastic MapReduce) is a managed service for running **Big Data** frameworks like Apache Hadoop, Spark, Hive, HBase, Presto, Flink.

### Deployment Modes

| Mode | Description | Use Case |
|------|-------------|----------|
| **EMR on EC2** | Cluster of EC2 instances managed by EMR | Full control, complex workloads, GPU |
| **EMR on EKS** | Spark jobs on an existing EKS cluster | Teams already using Kubernetes |
| **EMR Serverless** | No cluster to manage, pay per use | Ad-hoc jobs, teams that don't want to manage infra |

### EMR on EC2 Cluster Architecture

```
EMR Cluster
├── Master Node (1)      → Coordinates the cluster, runs YARN ResourceManager
├── Core Nodes (N)       → Store data in HDFS + execute tasks
└── Task Nodes (N)       → Only execute tasks (no HDFS). Ideal for Spot Instances
```

- **Master Node**: Always On-Demand (if it fails, you lose the cluster).
- **Core Nodes**: On-Demand or Reserved (store HDFS data).
- **Task Nodes**: **Spot Instances** (compute only, don't store data, tolerant to interruption).

### Storage in EMR

| Option | Description | Persistence |
|--------|-------------|-------------|
| **HDFS** | On the cluster's core nodes | Lost when the cluster terminates |
| **EMRFS (S3)** | Uses S3 as the file system | Persistent. Recommended for data lakes |
| **EBS** | Volumes attached to nodes | Lost when the cluster terminates |

> **Recommendation:** Use EMRFS (S3) for persistent data and HDFS only for temporary intermediate data that needs low latency.

### Use Cases

- Large-scale machine learning (Spark MLlib).
- Log processing and massive ETL.
- Genomic data analysis.
- Financial data analysis.
- Geospatial data processing.

### EMR vs Glue vs Athena

| Question | Service |
|----------|---------|
| "I want to run SQL on data in S3 without infra" | **Athena** |
| "I need serverless ETL integrated with Data Catalog" | **Glue** |
| "I need Spark/Hadoop with cluster control and custom libraries" | **EMR on EC2** |
| "I need serverless Spark without managing a cluster" | **EMR Serverless** or **Glue** |

> **Exam tip:** If the question mentions "Hadoop", "Spark", "Hive", "HBase", "Presto", "big data processing", "machine learning with Spark" → **EMR**. If it mentions "Spot Instances for big data" → EMR Task Nodes with Spot.

---

## Amazon QuickSight

**Serverless Business Intelligence (BI)** service for creating interactive dashboards and visualizations.

### Key Features

| Feature | Detail |
|---------|--------|
| **Model** | Serverless, pay per session or per user |
| **SPICE** | In-memory engine (Super-fast, Parallel, In-memory Calculation Engine). Imports data for fast queries |
| **Data sources** | Athena, S3, RDS, Aurora, Redshift, DynamoDB, OpenSearch, Salesforce, JDBC/ODBC |
| **Capabilities** | Dashboards, ad-hoc analysis, ML Insights (anomalies, forecasting), alerts |
| **Security** | Integration with IAM, row-level security (RLS), column-level security (CLS) |

### Typical Architecture

```
Data (S3, RDS, Redshift, Athena)
    │
    ▼
QuickSight (imports to SPICE or direct query)
    │
    ▼
Interactive dashboards (shared with users)
```

### Editions

| Feature | Standard | Enterprise |
|---------|----------|------------|
| **Authentication** | IAM, email | IAM, email, Active Directory, SAML |
| **Row-level security** | No | Yes |
| **Column-level security** | No | Yes |
| **Private VPC access** | No | Yes |
| **Embedded dashboards** | No | Yes |
| **ML Insights** | Limited | Full |

> **Exam tip:** If the question says "BI", "dashboards", "data visualization", "business users" → **QuickSight**. If it says "SPICE" → QuickSight. If it needs row-level security → QuickSight Enterprise.

---

## Amazon OpenSearch Service

Managed **OpenSearch** service (Elasticsearch fork) for search, log analytics, and observability.

### Key Features

| Feature | Detail |
|---------|--------|
| **Model** | Managed cluster (not serverless, although OpenSearch Serverless exists) |
| **Capabilities** | Full-text search, log analytics, dashboards (OpenSearch Dashboards / Kibana) |
| **Ingestion** | Kinesis Data Firehose, CloudWatch Logs, Lambda, Logstash, FluentBit |
| **Deployment** | Multi-AZ (up to 3 AZs), encryption at rest and in transit |

### Common Patterns

**Real-time log analytics:**

```
CloudWatch Logs / Kinesis Data Firehose / IoT
    │
    ▼
OpenSearch cluster (indexes and enables search)
    │
    ▼
OpenSearch Dashboards (real-time visualization)
```

**Full-text search in an application:**

```
DynamoDB (source of truth)
    │
    ▼ (DynamoDB Streams → Lambda)
OpenSearch (search index)
    │
    ▼
Application searches in OpenSearch, reads details from DynamoDB
```

### OpenSearch vs CloudWatch Logs Insights vs Athena

| Question | Service |
|----------|---------|
| "Full-text search on logs/documents" | **OpenSearch** |
| "Quick ad-hoc log analysis, no infra" | **CloudWatch Logs Insights** |
| "SQL on logs in S3, pay per query" | **Athena** |
| "Real-time log dashboards with KQL" | **OpenSearch Dashboards** |

### OpenSearch Serverless

- Serverless version of OpenSearch (no clusters to manage).
- Auto-scales based on load.
- Two modes: **Time Series** (logs, metrics) and **Search** (full-text search).
- Simpler but with less control than the managed cluster.

> **Exam tip:** If the question mentions "full-text search", "Elasticsearch", "Kibana", "real-time log analytics with dashboards" → **OpenSearch**. If it says "search" in the context of an application → probably OpenSearch as a search index.

---

## Amazon MSK

Amazon MSK (Managed Streaming for Apache Kafka) is a managed **Apache Kafka** service for data streaming.

### Kafka in 30 Seconds

```
Producers (send data) → Kafka Topics (organized in partitions) → Consumers (read data)
```

- **Topic**: Named data channel (e.g.: "orders", "clickstream").
- **Partition**: Subdivision of a topic for parallelism.
- **Broker**: Kafka server that stores and serves data.
- **Consumer Group**: Group of consumers that share partitions.

### MSK vs Kinesis Data Streams

| Feature | Amazon MSK | Kinesis Data Streams |
|---------|-----------|---------------------|
| **Protocol** | Apache Kafka (open source) | AWS proprietary API |
| **Model** | Managed cluster (brokers) | Serverless (shards) |
| **Retention** | Unlimited (disk) | 1-365 days |
| **Max message** | 1 MB (default), configurable higher | 1 MB |
| **Consumers** | Kafka Consumer API, Connect | Kinesis Client Library, Lambda |
| **Ecosystem** | Kafka Connect, Kafka Streams, KSQL | Native AWS integration |
| **Portability** | High (Kafka is open source, works on any cloud) | AWS lock-in |
| **Cost** | Pay per broker (instance) | Pay per shard/hour + data |
| **When to use** | Already using Kafka, need Kafka ecosystem, portability | AWS-native solution, simple integration with Lambda/S3 |

### MSK Serverless

- Serverless version of MSK (no brokers to manage).
- Auto-scales based on load.
- Pay per data and partitions, not per instances.
- Ideal for variable loads or teams that don't want to manage Kafka.

### MSK Connect

- Managed **Kafka Connect** service for moving data between Kafka and other systems.
- Pre-built connectors: S3 Sink, Elasticsearch Sink, Debezium (CDC), JDBC.
- Example: MSK → S3 automatically without code.

> **Exam tip:** If the question mentions "Kafka", "Kafka ecosystem", "migrate Kafka to AWS", "portability" → **MSK**. If it says "AWS-native data streaming" without mentioning Kafka → **Kinesis**. If it says "serverless Kafka streaming" → **MSK Serverless**.

---

## AWS Lake Formation

Service for creating, managing, and securing **data lakes** in S3.

### What Problem It Solves

Without Lake Formation, setting up a data lake requires:
- Configuring S3 permissions per bucket/prefix manually.
- Managing complex IAM policies for each team/user.
- Implementing column-level or row-level security manually.

Lake Formation **centralizes all of this**.

### Components

| Component | Description |
|-----------|-------------|
| **Data Catalog** | Uses the Glue Data Catalog as its base |
| **Security** | Centralized permissions at the database, table, column, and row level |
| **Blueprints** | Predefined workflows for ingesting data from RDS, CloudTrail, etc. to S3 |
| **Data Filters** | Row-level and column-level security on catalog tables |
| **Governed Tables** | Tables with ACID support (transactions on S3) |

### Security Model

```
Without Lake Formation:
    IAM Policies + S3 Bucket Policies + KMS Policies = complex, decentralized

With Lake Formation:
    Lake Formation Permissions (SQL-like GRANT/REVOKE)
        → "User X can see columns A,B,C of table Y"
        → "Team Z can only see rows where region='EU'"
```

- Centralizes permissions in a single place (instead of IAM + S3 + Glue policies).
- Supports **column-level** and **row-level security**.
- Integrates with: Athena, Redshift Spectrum, EMR, Glue.

### Typical Architecture

```
Sources (RDS, S3, on-premises)
    │
    ▼
Lake Formation (ingestion via Blueprints, centralized security)
    │
    ▼
Data Lake in S3 (Parquet, cataloged in Glue Data Catalog)
    │
    ├── Athena (ad-hoc queries)
    ├── Redshift Spectrum (analytics)
    ├── EMR (big data processing)
    └── QuickSight (dashboards)
```

> **Exam tip:** If the question mentions "centralized data lake security", "column/row-level permissions on S3", "data governance" → **Lake Formation**. If you only need a metastore → **Glue Data Catalog** (without Lake Formation).

---

## Reference Architecture: Data Lake on AWS

How all the services fit together:

```
INGESTION                  STORAGE                 PROCESSING               CONSUMPTION
─────────                  ───────                 ──────────               ───────────
Kinesis Data Streams  ─┐
Kinesis Firehose      ─┤
MSK (Kafka)           ─┤                                                   Athena (ad-hoc SQL)
IoT Core              ─┤                                                      │
DMS (databases)       ─┼──► S3 (Data Lake) ──► Glue ETL / EMR ──────────► QuickSight (BI)
API Gateway + Lambda  ─┤       │                                              │
Glue Crawlers         ─┤       │                                           Redshift (DW)
DataSync (on-prem)    ─┘       │                                              │
                               ▼                                           OpenSearch (search)
                        Glue Data Catalog                                     │
                        Lake Formation                                     SageMaker (ML)
                        (centralized security)
```

---

## Decision Tree: Choosing the Right Analytics Service

```
What do you need to do?
│
├── Run SQL on data in S3
│   ├── Ad-hoc queries, pay per query → Athena
│   └── Data warehouse with structured data, complex queries, massive joins → Redshift
│
├── Transform data (ETL)
│   ├── Serverless, integrated with Data Catalog → Glue
│   ├── Spark/Hadoop with full cluster control → EMR
│   └── Simple and lightweight transformation → Lambda or Kinesis Firehose
│
├── Data streaming
│   ├── AWS-native, integration with Lambda → Kinesis
│   └── Kafka ecosystem, portability → MSK
│
├── Visualize data (dashboards)
│   └── QuickSight
│
├── Full-text search / real-time log analytics
│   └── OpenSearch
│
├── Centralized data catalog
│   └── Glue Data Catalog
│
└── Data lake governance and security (column/row-level permissions)
    └── Lake Formation
```

---

## Analytics Exam Tips

### Athena

1. **"SQL on S3 without infrastructure"** → Athena.
2. **"Reduce Athena costs"** → Columnar format (Parquet/ORC) + partitioning + compression.
3. **"Analyze CloudTrail logs / VPC Flow Logs / ALB logs with SQL"** → Athena on logs in S3.
4. **"Query that joins data from S3 with RDS"** → Athena Federated Query.

### Glue

5. **"Automatically discover schema of data in S3"** → Glue Crawler.
6. **"Centralized data catalog"** → Glue Data Catalog.
7. **"Serverless ETL"** → Glue ETL Jobs.
8. **"Transform data without code"** → Glue DataBrew.
9. **"Convert CSV to Parquet"** → Glue ETL Job.

### EMR

10. **"Hadoop, Spark, Hive, HBase, Presto"** → EMR.
11. **"Big data with Spot Instances"** → EMR Task Nodes with Spot.
12. **"Machine learning with Spark MLlib"** → EMR.
13. **"Spark without managing a cluster"** → EMR Serverless or Glue.

### QuickSight

14. **"Dashboards", "BI", "visualization"** → QuickSight.
15. **"SPICE"** → QuickSight (in-memory engine).
16. **"Row-level security in dashboards"** → QuickSight Enterprise.
17. **"Embedded analytics in web app"** → QuickSight Enterprise (embedded dashboards).

### OpenSearch

18. **"Full-text search"** → OpenSearch.
19. **"Elasticsearch", "Kibana", "ELK stack"** → OpenSearch.
20. **"Real-time log analytics with dashboards"** → OpenSearch + OpenSearch Dashboards.
21. **"Search index complementing DynamoDB"** → DynamoDB Streams → Lambda → OpenSearch.

### MSK

22. **"Kafka", "migrate Kafka to AWS"** → MSK.
23. **"Streaming with multi-cloud portability"** → MSK (Kafka is open source).
24. **"Kafka without managing brokers"** → MSK Serverless.
25. **"Kinesis vs MSK"** → Kinesis = AWS-native, simple. MSK = Kafka ecosystem, portable.

### Lake Formation

26. **"Centralized data lake security"** → Lake Formation.
27. **"Column-level permissions on S3"** → Lake Formation.
28. **"Row-level security on data lake"** → Lake Formation Data Filters.
29. **"Simplify IAM + S3 permissions for data"** → Lake Formation.

### Recurring Patterns

30. **Typical analytics pipeline:** S3 → Glue Crawler (catalogs) → Athena (query) → QuickSight (visualize).
31. **Streaming to analytics:** Kinesis/MSK → Firehose → S3 → Athena / Redshift.
32. **ETL + Data Lake:** Glue ETL (transforms) → S3 (Parquet) → Lake Formation (security) → Athena/Redshift (query).
33. **Real-time logs:** CloudWatch Logs → Subscription Filter → OpenSearch → Dashboards.
