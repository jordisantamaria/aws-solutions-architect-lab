# Databases in AWS

## Table of Contents

- [Amazon RDS](#amazon-rds)
- [RDS Proxy](#rds-proxy)
- [Amazon Aurora](#amazon-aurora)
- [Amazon DynamoDB](#amazon-dynamodb)
- [DynamoDB Advanced](#dynamodb-advanced)
- [Amazon ElastiCache](#amazon-elasticache)
- [Amazon Redshift](#amazon-redshift)
- [Amazon Neptune](#amazon-neptune)
- [Amazon DocumentDB](#amazon-documentdb)
- [Amazon Keyspaces](#amazon-keyspaces)
- [Amazon QLDB](#amazon-qldb)
- [Amazon Timestream](#amazon-timestream)
- [Database Decision Tree](#database-decision-tree)
- [Exam Tips](#exam-tips)

---

## Amazon RDS

Amazon Relational Database Service is a managed relational database service.

### Supported Engines

| Engine | Notes |
|---|---|
| **MySQL** | Compatible with Aurora |
| **PostgreSQL** | Compatible with Aurora |
| **MariaDB** | MySQL fork |
| **Oracle** | License included or BYOL |
| **Microsoft SQL Server** | License included |

### Main Features

- **Managed service**: AWS manages patches, backups, monitoring, scaling.
- **No SSH access** to the underlying instance.
- Storage backed by EBS (gp2, gp3, io1).

### Multi-AZ (High Availability)

- **Synchronous** replica in another AZ of the same region.
- **Automatic failover** on failures (automatic DNS, no app changes required).
- The standby instance **does NOT serve read traffic** (failover only).
- Can be converted from Single-AZ to Multi-AZ **without downtime** (internal snapshot -> restore in another AZ -> synchronization).

```
                    +------------------+
                    |   Application    |
                    +--------+---------+
                             |
                    +--------v---------+
                    |  RDS Master      | <---- DNS Endpoint
                    |   (AZ-a)         |       (automatic failover)
                    +--------+---------+
                             | SYNCHRONOUS Replication
                    +--------v---------+
                    |  RDS Standby     |
                    |   (AZ-b)         |
                    +------------------+
```

### Read Replicas (Read Scaling)

- Up to **15 read replicas** (within AZ, cross-AZ, cross-Region).
- **ASYNCHRONOUS** replication (eventually consistent).
- Replicas can be **promoted to independent DB**.
- The application must update the connection string to use replicas.
- **Network cost**: No charge for replication within the same region. Cross-Region does have a charge.

**Use cases**: Reporting, analytics, read-intensive workloads.

> **Key**: Multi-AZ = high availability (HA). Read Replicas = read scalability. They are complementary, not mutually exclusive.

### Storage Auto Scaling

- Automatically increases storage when approaching the limit.
- A **Maximum Storage Threshold** (maximum limit) is set.
- Triggers when:
  - Free space is < 10% of allocated storage.
  - The condition persists for 5 minutes.
  - At least 6 hours have passed since the last modification.
- Useful for unpredictable workloads.

### Backup and Restore

**Automated Backups:**
- Enabled by default.
- Daily full backup (during the maintenance window).
- Transaction logs every 5 minutes.
- Retention from 1 to 35 days (0 to disable).
- Restoration to **any point in time** (Point-in-Time Recovery) with 5-minute granularity.

**Manual Snapshots:**
- Manually initiated by the user.
- Retained indefinitely until deleted.
- Can be copied between regions.

> **Key**: Restoring a backup or snapshot **always creates a new RDS instance** with a new endpoint.

### IAM DB Authentication

Authentication method that replaces username/password with temporary tokens generated via IAM. Supported on **MySQL** and **PostgreSQL**.

**Traditional authentication vs IAM DB Auth:**

```
Traditional:
  App on EC2 --> connects with username="admin" password="s3cret123"
                 (password stored in config or Secrets Manager)

IAM DB Auth:
  1. EC2 has an IAM Role with rds-db:connect permission
  2. App requests token --> RDS API generates token signed with IAM Role credentials
  3. App connects with username="iam_user" password=TOKEN
                   (the token expires in 15 minutes)
```

**The token is not stored.** The app generates a new token each time it needs a connection. If the connection is already open, it keeps working. For a new connection, it requests another token.

**Benefits:**
- No passwords to manage, rotate, or that can leak.
- Traffic is encrypted with SSL automatically.
- Centralized access control with IAM policies (who can connect to which DB).
- On EC2: uses the **instance profile** (IAM Role) credentials automatically, without additional configuration.

**Limitations:**
- Only MySQL and PostgreSQL (not Oracle, SQL Server or MariaDB on RDS).
- Maximum **256 connections per second** with IAM auth (not for high connection throughput).
- The token lasts **15 minutes** (but already established connections are not cut).

> **Exam tip:** If the question says "authentication token" or "profile credentials of EC2" to connect to RDS -> **IAM DB Authentication**. Do not confuse with simply assigning an IAM Role to EC2 (that gives permissions to the AWS API, not direct database authentication). Do not confuse with SSL (which encrypts the connection but does not change the authentication method).

### Private RDS Access (for development and maintenance)

RDS should be in a private subnet (no direct access from the Internet). To connect from your laptop with tools like pgAdmin or DBeaver, there are several options from less to more complexity:

| Method | Needs EC2? | Needs VPN? | Complexity |
|---|---|---|---|
| **EC2 Instance Connect Endpoint** | No | No | Low |
| **SSM Port Forwarding** | Yes (private, no SSH) | No | Low |
| **Client VPN** | No | Yes | Medium |
| **Bastion + SSH tunnel** | Yes (public, with SSH) | No | High |

#### EC2 Instance Connect Endpoint (recommended)

Allows creating a direct tunnel to private resources **without needing intermediary EC2 instances or VPN**. Created as an endpoint within the VPC and access is controlled exclusively with IAM and Security Groups.

```
Your laptop --> EC2 Instance Connect Endpoint --> RDS (private subnet)
                (secure tunnel via AWS API)
                No bastion, no VPN, no SSH
```

Used with the AWS CLI:
```bash
aws ec2-instance-connect open-tunnel \
  --instance-connect-endpoint-id eice-xxxx \
  --remote-host-address mydb.xxxx.rds.amazonaws.com \
  --remote-port 5432 \
  --local-port 5432

# pgAdmin connects to localhost:5432 as if RDS were local
```

**Requirements:**
- Create an EC2 Instance Connect Endpoint in a VPC subnet.
- Security Group of the endpoint with access to the RDS port.
- IAM permissions for `ec2-instance-connect:OpenTunnel`.

#### SSM Session Manager with Port Forwarding

Requires a private EC2 instance with SSM Agent (comes pre-installed by default), but **does not need a bastion or open SSH ports**:

```
Your laptop --> SSM Session Manager --> EC2 (private) --> RDS
                (tunnel via AWS API)   (only needs SSM Agent)
```

> **Exam tip:** If the question says "secure access to private resources without bastion or SSH" -> **SSM Session Manager** or **EC2 Instance Connect Endpoint**. If it says "access to private RDS without intermediary EC2" -> **EC2 Instance Connect Endpoint**.

---

## RDS Proxy

Managed database proxy that sits between the application and RDS.

### Benefits

- **Connection pooling**: Reduces and reuses database connections.
- **Lower failover time**: Reduces Multi-AZ failover time by up to **66%**.
- Supports **IAM authentication** for the DB connection.
- Credentials are stored in **AWS Secrets Manager**.
- **Never publicly accessible** (only from within the VPC).

### When to Use RDS Proxy

| Scenario | Problem Without Proxy | Solution With Proxy |
|---|---|---|
| **Lambda + RDS** | Each Lambda invocation opens a connection. With high concurrency, connections are exhausted | The proxy manages a shared connection pool |
| **Multi-AZ Failover** | Failover time of ~60-120 seconds | Reduces to ~30 seconds |
| **Many microservices** | Each service opens its own connections | Shared pool reduces total connections |

> **Key for the exam**: If a question mentions Lambda + RDS with connection problems, the answer is almost always RDS Proxy.

---

## Amazon Aurora

AWS proprietary relational database, compatible with **MySQL** and **PostgreSQL**. Up to **5x better performance than MySQL** and **3x better than PostgreSQL**.

### Architecture

- Storage distributed and auto-replicated in **6 copies** across **3 AZs**.
  - Only needs 4/6 copies for writes.
  - Only needs 3/6 copies for reads.
  - Self-healing with peer-to-peer replication.
- **Auto-scaling** storage from 10 GB to **128 TB**.
- **Instant failover** (< 30 seconds).

```
    +-------------+      +-------------+
    |   Writer     |      |  Reader(s)  |
    |  Endpoint    |      |  Endpoint   |
    +------+------+      +------+------+
           |                     |
    +------v---------------------v------+
    |     Shared Storage Volume         |
    |  (Auto-scaling, 6 copies, 3 AZs) |
    |  10 GB ------------------> 128 TB |
    +-----------------------------------+
```

### Aurora Replicas

- Up to **15 read replicas** with low-latency replication (< 10 ms lag).
- Automatic failover to any replica (priority can be configured with **tiers**).
- **Reader Endpoint**: Automatic connection-level load balancing across replicas.
- **Custom Endpoints**: Direct traffic to a subset of replicas (e.g., more powerful replicas for analytics).

### Aurora Global Database

- **1 primary region** (read/write).
- Up to **5 secondary regions** (read-only).
- Up to 16 read replicas per secondary region.
- Replication latency < **1 second** cross-region.
- **Cross-region failover** with RTO < 1 minute.
- Use case: Global disaster recovery, low latency for global reads.

### Aurora Serverless v2

- Automatic compute capacity scaling based on load.
- A range of **ACUs (Aurora Capacity Units)** is defined: minimum and maximum.
- Scales in granular increments (not in discrete steps like v1).
- Supports Multi-AZ.
- **Use case**: Unpredictable workloads, development, environments with intermittent traffic.

### Aurora Machine Learning

- Direct integration with **SageMaker** and **Amazon Comprehend**.
- Run ML inferences directly from SQL queries.
- Use case: Fraud detection, sentiment analysis, recommendations.

### Aurora Native Functions and Stored Procedures (invoking Lambda)

Aurora can **call AWS Lambda directly from within the database**, using native functions or stored procedures. This allows reacting to data changes (INSERT, UPDATE, DELETE) from the DB itself.

```
App deletes a record --> Aurora executes trigger/stored procedure
                              |
                              v
                         Calls Lambda (native function)
                              |
                              v
                         Lambda processes (sends to SQS, SNS, etc.)
```

**Example (Aurora MySQL):**
```sql
-- Stored procedure that invokes Lambda when deleting a car:
CALL mysql.lambda_async(
    'arn:aws:lambda:eu-west-1:123456:function:process-sale',
    '{"car_id": 123, "action": "sold"}'
);
```

**Requirements:**
- Aurora MySQL or Aurora PostgreSQL (standard RDS does not support it).
- The Aurora cluster needs an IAM Role with permissions to invoke Lambda.
- Network connectivity between Aurora and Lambda (NAT Gateway or VPC endpoint for Lambda).

#### RDS Event Subscription vs Native Functions

| | RDS Event Subscription | Native Function / Stored Procedure |
|---|---|---|
| **Detects** | **Operational** events (failover, backup, maintenance) | **Data** changes (INSERT, UPDATE, DELETE) |
| **Example** | "The instance was restarted" | "The record with id=123 was deleted" |
| **Destination** | SNS | Lambda (directly from the DB) |
| **Aurora only?** | No (works with any RDS) | **Yes** (only Aurora can invoke Lambda) |

> **Exam tip:** If the question says "react when a record is modified/deleted in Aurora" -> **native function or stored procedure that invokes Lambda**. Do not confuse with RDS Event Subscription, which only detects infrastructure events (failovers, backups), not data changes.

### Other Aurora Features

| Feature | Description |
|---|---|
| **Backtracking** | Rewind the database to a point in time without restoring from backup. Aurora MySQL only. Does not create a new instance. |
| **Cloning** | Create a copy of the DB using copy-on-write. Fast and storage-efficient. Ideal for testing in production. |
| **Database Activity Streams** | Real-time auditing of DB activity. Sent to Kinesis Data Streams. |

> **Key**: Aurora Backtracking "rewinds" the existing DB in-place. Restoring from backup creates a new instance. They are different concepts.

---

## Amazon DynamoDB

Serverless NoSQL database, fully managed, with single-digit millisecond performance.

### Fundamental Concepts

- **Tables**: Collection of items.
- **Items**: Each record (similar to a row). Maximum size: **400 KB**.
- **Attributes**: Fields of the item.

### Keys

| Key Type | Description | Example |
|---|---|---|
| **Partition Key (PK)** | Simple primary key. Must be unique. | `user_id` |
| **Partition Key + Sort Key (PK + SK)** | Composite key. The combination must be unique. | `user_id` + `timestamp` |

The **Partition Key** determines which partition the item is stored in. DynamoDB applies an internal hash function on the PK value to decide which physical partition each item goes to.

### Partition Key Cardinality (Hot Partitions)

The choice of PK is the most important design decision in DynamoDB. Provisioned capacity (RCU/WCU) is distributed **evenly across partitions**. If one partition receives more traffic than others, **throttling** occurs even if the table has surplus total capacity.

**High cardinality** = many distinct values = good distribution:

```
PK = user_id  ->  millions of distinct values  ->  traffic spread across many partitions
PK = order_id ->  millions of distinct values  ->  traffic spread across many partitions
```

**Low cardinality** = few distinct values = "hot partition":

```
PK = status ("active"/"inactive")  ->  only 2 values  ->  all traffic goes to 2 partitions
PK = country_code                  ->  ~200 values     ->  US/CN partitions receive 80% of traffic
```

**Numerical example:**
- Table with 10,000 provisioned WCU and 10 partitions -> each partition receives 1,000 WCU.
- If you use `status` as PK (2 values), 90% of writes go to the "active" partition -> that partition has 1,000 WCU but receives 9,000 -> **throttling**, even though the table has 9,000 WCU unused in other partitions.

**Solutions for hot partitions:**
- Choose a PK with **high cardinality** (user_id, order_id, session_id).
- **Write Sharding**: Add a random suffix to the PK (e.g., `status#1`, `status#2`, ..., `status#10`) to force distribution.
- Use composite keys (PK + SK) for more unique combinations.

> **Exam tip:** If they ask "distribute workload evenly" or "use throughput efficiently" in DynamoDB -> **partition key with high cardinality**. If they say "hot partition" or "throttling with surplus capacity" -> the problem is a PK with low cardinality.

### Secondary Indexes

| Type | Description | Creation | Limit |
|---|---|---|---|
| **GSI (Global Secondary Index)** | Alternative PK and SK. Can query on non-key attributes. Has its own projected table. | At any time | 20 per table |
| **LSI (Local Secondary Index)** | Same PK as the table, but different SK. | Only at table creation | 5 per table |

**Important notes about GSI:**

- If the GSI has throttling, the base table also suffers throttling.
- The GSI consumes its own read/write capacity (separate WCU/RCU).
- It is recommended to carefully choose the GSI PK to avoid hot partitions.

### Capacity Modes

| Mode | Description | Price | Use Case |
|---|---|---|---|
| **Provisioned** | RCU and WCU are defined in advance. Optional auto scaling. | More economical for predictable workloads | Stable, predictable traffic |
| **On-Demand** | Scales automatically without planning. No throttling by capacity. | ~2.5x more expensive than provisioned | Unpredictable traffic, new tables, spiky |

**Capacity units:**

- **1 RCU** = 1 strongly consistent read of up to 4 KB/s, or 2 eventually consistent reads of up to 4 KB/s.
- **1 WCU** = 1 write of up to 1 KB/s.

> **Calculation example**: Read 10 items of 6 KB each per second (strongly consistent):
> Each item needs ceil(6/4) = 2 RCU -> 10 * 2 = **20 RCU**.

---

## DynamoDB Advanced

### DAX (DynamoDB Accelerator)

- In-memory cache for DynamoDB, fully managed.
- **Microsecond** latency (vs milliseconds from DynamoDB).
- Compatible with existing DynamoDB API (minimal code change).
- Default TTL of **5 minutes**.
- Cluster of up to 11 nodes, Multi-AZ.
- **Does not work for writes**, only for cached reads.

**DAX vs ElastiCache for DynamoDB:**

| | DAX | ElastiCache |
|---|---|---|
| **Integration** | Native with DynamoDB | Requires application logic |
| **Cache type** | Individual items and query results | Computed/aggregated results |
| **Use case** | Cache for DynamoDB reads | Store results of complex calculations |

### DynamoDB Streams

- Ordered stream of changes (inserts, updates, deletions) in the table.
- **24-hour** retention.
- Can be processed with **Lambda** or **Kinesis Data Streams** (more recent option with 1-year retention).
- Use cases: React to changes in real time, cross-region replication, analytics.

### DynamoDB Global Tables

- Tables replicated in **multiple regions**.
- **Active-active** replication (read and write in any region).
- **Not automatic by default**: Must be explicitly configured by adding regions to the table.
- Requires **DynamoDB Streams enabled** (mandatory prerequisite).
- Typical replication latency: **< 1 second**.
- Conflict resolution: **Last writer wins** (based on timestamp).
- Use case: Low-latency global applications, multi-region DR.

> **Exam trap:** DynamoDB Global Tables are NOT enabled by default. You must configure them explicitly and DynamoDB Streams must be enabled first.

### TTL (Time To Live)

- Automatically deletes expired items without consuming WCU.
- A TTL attribute is defined with a Unix timestamp (epoch) for expiration.
- Actual deletion can take up to **48 hours** after expiration.
- Expired items appear in DynamoDB Streams.
- Use case: User sessions, temporary data, logs with retention.

### Backup and Restore

| Type | Description |
|---|---|
| **On-demand backup** | Full backup, retained until deleted. No performance impact. |
| **Point-in-time recovery (PITR)** | Continuous restoration to any point in the last 35 days. Must be explicitly enabled. |

> **Note**: Restoring always creates a **new table**.

### DynamoDB - Design Patterns for the Exam

- **Write Sharding**: Add a random suffix to the PK to distribute writes.
- **Sparse Index**: GSI on attributes that only exist in some items for efficient queries.
- **Composite Key**: Use hierarchical SK (e.g., `COUNTRY#US#STATE#CA#CITY#LA`).

---

## Amazon ElastiCache

Managed in-memory cache service. Supports two engines:

### Redis vs Memcached

| Feature | Redis | Memcached |
|---|---|---|
| **Data model** | Complex structures (strings, hashes, lists, sets, sorted sets) | Simple key-value |
| **Persistence** | Yes (AOF, RDB) | No |
| **Replication** | Yes (Read Replicas) | No |
| **High availability** | Multi-AZ with automatic failover | No |
| **Backup and restore** | Yes | No |
| **Pub/Sub** | Yes | No |
| **Clustering** | Cluster mode (data partitioning) | Multi-node partitioning |
| **Multi-thread** | No (single-threaded) | Yes (multi-threaded) |
| **Use case** | Sessions, leaderboards, pub/sub, geospatial, HA required | Simple cache, high concurrency |

> **Exam rule**: If the question needs HA, persistence, or complex data structures -> **Redis**. If it only needs simple multi-threaded cache -> **Memcached**.

### Caching Strategies

| Strategy | Description | Pros | Cons |
|---|---|---|---|
| **Lazy Loading** | Loads data into cache only when requested (cache miss -> read DB -> write cache) | Only necessary data is cached. Resilient to cache failures | Cache miss = 3 calls (penalty). Data can become stale |
| **Write-Through** | Writes to cache every time the DB is updated | Data always fresh in cache | Write penalty (2 writes). Cache can fill with unread data |
| **Session Store** | Use ElastiCache to store user sessions with TTL | Stateless applications. Automatic expiration | Requires application logic |

**Recommended combination**: Lazy Loading + TTL for data that can be stale for a reasonable time.

### ElastiCache - Security

ElastiCache Redis has three independent security layers:

| Layer | What it protects | How |
|---|---|---|
| **At-rest encryption** | Data stored on disk/memory | Encryption with KMS. Enabled at cluster creation. |
| **In-transit encryption** | Data in transit between client and Redis | TLS. Enabled with `--transit-encryption-enabled`. |
| **Authentication** | Who can execute commands | Redis AUTH or IAM authentication. |

#### Redis AUTH vs IAM Authentication

| | Redis AUTH | IAM Authentication |
|---|---|---|
| **Credential** | Static password (auth-token) | Temporary token generated via IAM |
| **Duration** | Long-lived (doesn't expire until you change it) | Short-lived (expires automatically) |
| **Requirement** | **Requires in-transit encryption (TLS)** | Requires in-transit encryption (TLS) |
| **Management** | You manage the password | IAM manages credentials |
| **Use case** | Apps that need fixed credentials | Apps that already use IAM Roles (EC2, Lambda) |

```
Redis AUTH:
  Client --> AUTH my-password --> Redis accepts --> MULTI / SET / EXEC work
              (fixed password, long-lived, requires TLS enabled)

IAM Authentication:
  App --> generates IAM token --> AUTH temporary-token --> Redis accepts
          (token expires, short-lived)
```

**Important:** Redis AUTH **does not work without in-transit encryption**. The `--auth-token` flag can only be used together with `--transit-encryption-enabled`. If you only enable at-rest encryption or only TLS without auth-token, there is no user authentication.

- Security Groups for network control (who can connect to the Redis port).

---

## Amazon Redshift

Data warehouse based on PostgreSQL, designed for **OLAP** (Online Analytical Processing) at petabyte scale.

### Main Features

- **Columnar** storage (not row-based).
- Columnar data compression.
- **MPP (Massively Parallel Processing)**: Distributes queries across nodes.
- **Leader** nodes (plan queries) and **Compute** nodes (execute queries).
- Not Multi-AZ (cluster in a single AZ).
- Data loading from S3, DynamoDB, DMS, or others.

### Redshift Spectrum

- Executes queries directly on data in **S3** without loading it.
- Compute nodes do not participate; thousands of dedicated Spectrum nodes are used.
- Use case: Query historical data in S3 without moving it to Redshift.

### Snapshots and DR

- Snapshots are stored internally in S3.
- Incremental snapshots.
- Can be automatically copied to **another region** for DR.
- A snapshot can be restored to a new cluster.

### Redshift Serverless

- Scales automatically based on load.
- No cluster infrastructure management needed.
- Pay per RPU (Redshift Processing Units) consumed.
- Ideal for intermittent or unpredictable analytics workloads.

### Redshift and Latency: Not Real-Time

Redshift is for **batch analytics**, not for real-time queries. Complex queries take **seconds to minutes**. On the exam, "near real-time analytics" with Redshift means data arrives via Kinesis Firehose in micro-batches (~60s), but queries are not instant.

| Service | Query Latency | Type |
|---|---|---|
| **DynamoDB** | Milliseconds | Real-time (individual CRUD) |
| **OpenSearch** | Seconds | Near real-time (search/logs) |
| **Athena** | Seconds | Ad-hoc queries on S3 |
| **Redshift** | Seconds to minutes | Complex analytics (JOINs, GROUP BY, aggregations) |

> **Key for the exam**: Redshift is for analytics/OLAP, NOT for OLTP. If the question is about a data warehouse or BI, think Redshift. If it says "real-time IoT dashboard with millions of reads per second" -> **DynamoDB** (for ingestion) + **Kinesis** (for streaming). If it needs data from S3 without moving it -> Redshift Spectrum.

---

## Amazon Neptune

Fully managed **graph** database.

### Features

- High availability with replication across up to 3 AZs, 15 read replicas.
- Optimized for complex relationships between data.
- Supports graph models: **Property Graph** (Gremlin) and **RDF** (SPARQL).
- Millisecond latency for graph queries.
- Stores billions of relationships.

### Use Cases

| Use Case | Description |
|---|---|
| **Social networks** | Relationships between users, friends, likes, posts |
| **Recommendation engine** | "Users who bought this also bought..." |
| **Fraud detection** | Suspicious transaction patterns |
| **Knowledge graphs** | Relationships between entities (Wikipedia, etc.) |
| **Network management** | Network topology, dependencies |

> **Key**: If the question mentions "graphs", "complex relationships between entities", or "social network", the answer is **Neptune**.

---

## Amazon DocumentDB

Document database compatible with **MongoDB**.

### Features

- Fully managed, high availability with replication across 3 AZs.
- Auto-scaling storage from 10 GB to 64 TB.
- Up to 15 read replicas with latency < 10 ms.
- Scales automatically for millions of requests per second.

### When to Use

- Migration of **MongoDB** workloads to AWS.
- Applications that need JSON document storage.
- When you don't want to manage MongoDB manually.

> **Key**: If the question mentions "MongoDB" or "MongoDB migration", the answer is **DocumentDB**.

---

## Amazon Keyspaces

Database compatible with **Apache Cassandra**, serverless and fully managed.

### Features

- API compatible with CQL (Cassandra Query Language).
- Serverless: scales automatically based on demand.
- Tables replicated 3 times across multiple AZs.
- Capacity modes: **On-demand** and **Provisioned** (with auto scaling).
- At-rest encryption and continuous backup with PITR (35 days).

### When to Use

- Migration of **Apache Cassandra** workloads to AWS.
- IoT applications with time series data and high write volume.

> **Key**: If the question mentions "Cassandra" or "Cassandra migration", the answer is **Keyspaces**.

---

## Amazon QLDB

Quantum Ledger Database: fully managed **ledger** database.

### Features

- **Immutable**: Data cannot be modified or deleted (append-only).
- Complete and cryptographically verifiable history of all changes.
- 2-3x better performance than traditional blockchain frameworks.
- Uses a transaction journal with a verifiable **hash chain**.
- Centralized (unlike blockchain which is decentralized).

### When to Use

- Financial records, transaction auditing.
- History of changes in critical data (supply chain).
- Systems where verifiable immutability is needed.

> **Key**: If the question mentions "ledger", "immutable record", "cryptographically verifiable audit" and control is **centralized** -> QLDB. If it needs **decentralization** -> Amazon Managed Blockchain.

---

## Amazon Timestream

Serverless and fully managed **time series** database.

### Features

- Up to **1000x faster and 1/10 the cost** of relational databases for time series data.
- Automatic tiered storage: recent data in memory, historical data in magnetic storage.
- Built-in time series analytics functions (interpolation, smoothing, etc.).
- At-rest and in-transit encryption.
- Integration with Grafana, QuickSight for visualization.

### When to Use

- IoT and sensor data.
- Application and DevOps metrics.
- Click-stream data and real-time analysis.
- Any data with a natural timestamp and temporal patterns.

> **Key**: If the question mentions "time series", "IoT metrics", "large-scale temporal data", the answer is **Timestream**.

---

## Database Decision Tree

### Selection by Data Type and Use Case

```
What type of data?
|
|-- RELATIONAL data (SQL, ACID transactions)
|   |-- Need MySQL/PostgreSQL compatibility with better performance?
|   |   +-- Amazon Aurora
|   |-- Need Oracle, SQL Server, MariaDB?
|   |   +-- Amazon RDS
|   +-- Analytical data (OLAP, data warehouse)?
|       +-- Amazon Redshift
|
|-- NON-RELATIONAL data (NoSQL)
|   |-- Key-Value / Documents with low latency
|   |   +-- Amazon DynamoDB
|   |-- JSON Documents (MongoDB compatible)
|   |   +-- Amazon DocumentDB
|   |-- Wide-column (Cassandra compatible)
|   |   +-- Amazon Keyspaces
|   +-- Graphs (complex relationships)
|       +-- Amazon Neptune
|
|-- In-memory CACHE data
|   |-- Need persistence, HA, complex structures?
|   |   +-- ElastiCache for Redis
|   +-- Just simple multi-threaded cache?
|       +-- ElastiCache for Memcached
|
|-- TIME SERIES data
|   +-- Amazon Timestream
|
|-- LEDGER (immutable, auditable)
|   +-- Amazon QLDB
|
+-- BLOCKCHAIN (decentralized)
    +-- Amazon Managed Blockchain
```

### Quick Selection by Keywords

| Keyword in the Question | Service |
|---|---|
| "Relational", "SQL", "ACID transactions" | RDS or Aurora |
| "MySQL/PostgreSQL with high performance" | Aurora |
| "Oracle", "SQL Server" | RDS |
| "Data warehouse", "OLAP", "analytics", "BI" | Redshift |
| "NoSQL", "key-value", "low latency", "serverless DB" | DynamoDB |
| "MongoDB" | DocumentDB |
| "Cassandra" | Keyspaces |
| "Graphs", "relationships between entities" | Neptune |
| "Cache", "sessions", "leaderboard" | ElastiCache Redis |
| "Time series", "IoT", "metrics" | Timestream |
| "Ledger", "immutable", "audit" | QLDB |
| "Lambda + RDS", "connection problems" | RDS Proxy |
| "Heterogeneous DB migration" | DMS + SCT |

---

## Exam Tips

### RDS

1. **"High availability for RDS"** -> Multi-AZ (synchronous, automatic failover).
2. **"Scale reads in RDS"** -> Read Replicas (asynchronous).
3. **"Lower RDS failover time"** -> RDS Proxy.
4. **"Lambda + RDS with connection problems"** -> RDS Proxy (connection pooling).
5. **"Restore RDS"** -> Always creates a NEW instance.
6. **"Encrypt existing unencrypted RDS"** -> Snapshot -> copy with encryption -> restore.
7. **"Authentication with token / EC2 profile credentials to RDS"** -> IAM DB Authentication (not a plain IAM Role, not SSL).

### Aurora

7. **"MySQL/PostgreSQL with high performance and HA"** -> Aurora.
8. **"Rewind the DB to a previous point without creating a new instance"** -> Aurora Backtracking (MySQL only).
9. **"Clone DB for testing"** -> Aurora Cloning (copy-on-write).
10. **"Global cross-region reads with < 1s lag"** -> Aurora Global Database.
11. **"Variable capacity, serverless relational"** -> Aurora Serverless v2.
12. **"React to data changes in Aurora (INSERT/UPDATE/DELETE)"** -> Native function or stored procedure that invokes Lambda. Do not confuse with RDS Event Subscription (infrastructure events only).

### DynamoDB

12. **"Serverless NoSQL database"** -> DynamoDB.
13. **"Cache for DynamoDB"** -> DAX (not ElastiCache for DynamoDB).
14. **"Multi-region active-active NoSQL replication"** -> DynamoDB Global Tables.
15. **"React to changes in DynamoDB"** -> DynamoDB Streams + Lambda.
16. **"Unpredictable access pattern in DynamoDB"** -> On-Demand mode.
17. **"Automatic item expiration"** -> TTL.

### ElastiCache

18. **"Cache with HA and persistence"** -> ElastiCache Redis.
19. **"Simple cache, multi-threaded"** -> ElastiCache Memcached.
20. **"Stateless user sessions"** -> ElastiCache Redis (or DynamoDB).
21. **"Authenticate users with password before executing Redis commands"** -> Redis AUTH (`--auth-token` + `--transit-encryption-enabled`). Both flags are mandatory together.
22. **"Short-lived credentials for Redis"** -> IAM Authentication. **"Long-lived credentials"** -> Redis AUTH.

### Redshift

21. **"Large-scale data warehouse"** -> Redshift.
22. **"Query data in S3 from Redshift without loading it"** -> Redshift Spectrum.
23. **"OLAP, not OLTP"** -> Redshift (OLAP) vs RDS/Aurora (OLTP).

### Purpose-Specific Databases

24. **"Graphs"** -> Neptune.
25. **"MongoDB"** -> DocumentDB.
26. **"Cassandra"** -> Keyspaces.
27. **"Immutable ledger"** -> QLDB.
28. **"Time series"** -> Timestream.
29. **"Decentralized blockchain"** -> Managed Blockchain.
