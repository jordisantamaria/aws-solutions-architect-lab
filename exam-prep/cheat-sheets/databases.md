# Databases - Quick Cheat Sheet

## RDS vs Aurora vs DynamoDB

| Feature | RDS | Aurora | DynamoDB |
|---------|-----|--------|----------|
| **Type** | Relational (SQL) | Relational (SQL) | NoSQL (Key-Value / Document) |
| **Engines** | MySQL, PostgreSQL, MariaDB, Oracle, SQL Server | MySQL, PostgreSQL | AWS proprietary |
| **Max storage** | 64 TB | 128 TB (auto-scaling) | Unlimited |
| **Read Replicas** | Up to 15 (5 by default) | Up to 15 (auto-scaling) | Global Tables (multi-region) |
| **Multi-AZ** | Standby (failover) | Native Multi-AZ (6 copies in 3 AZs) | Native Multi-AZ (3 AZs) |
| **Failover** | 1-2 minutes | **< 30 seconds** | Automatic (transparent) |
| **Auto-scaling storage** | Manual (up to 64TB) | **Automatic** (10GB increments) | Automatic (on-demand mode) |
| **Serverless** | No | **Yes (Aurora Serverless v2)** | **Yes (on-demand mode)** |
| **Backups** | Automatic (35 days max) | Automatic (35 days) + backtrack | Continuous backups (PITR 35 days) |
| **Price** | Lower | ~20% more than RDS | Per read/write + storage |
| **Ideal case** | Relational apps, specific engines | High availability, auto-scaling relational | Massive scale, low latency, key-value |

---

## Available RDS Engines

| Engine | Notable Versions | Exam Notes |
|--------|------------------|------------|
| **MySQL** | 5.7, 8.0 | Compatible with Aurora MySQL |
| **PostgreSQL** | 13, 14, 15, 16 | Compatible with Aurora PostgreSQL |
| **MariaDB** | 10.x | MySQL fork, not compatible with Aurora |
| **Oracle** | SE2, EE | Requires license (BYOL or License Included) |
| **SQL Server** | SE, EE, Express, Web | Requires license. Multi-AZ uses mirroring/Always On |
| **Db2** | 11.5 | IBM Db2 managed on RDS |

> **Exam key:** If they ask for **Oracle or SQL Server** on AWS managed → only **RDS** (not Aurora). If they ask for MySQL/PostgreSQL with better performance → **Aurora**.

---

## Aurora - Quick Features

| Feature | Description |
|---------|-------------|
| **6 copies in 3 AZs** | Data replicated automatically. Tolerates loss of 2 copies for writes, 3 for reads |
| **Storage auto-scaling** | Grows automatically from 10 GB to 128 TB in 10 GB increments |
| **Up to 15 Read Replicas** | With Auto Scaling. Automatic failover to replica with highest priority |
| **Aurora Serverless v2** | Automatically scales compute capacity (ACUs). Pay for actual use |
| **Aurora Global Database** | Cross-region replication in < 1 second. RPO of 1s, RTO < 1 min |
| **Backtrack** | Rewind the database to a point in time **without restoring from backup** (MySQL only) |
| **Multi-Master** | Multiple write nodes (use case: continuous writes without failover) |
| **Cloning** | Create a copy of the DB using copy-on-write — fast with no initial storage cost |
| **Custom Endpoints** | Direct traffic to subgroups of replicas (e.g.: analytics to larger replicas) |
| **Parallel Query** | Distributes query processing to the storage layer for large analytical queries |

> **Exam trick:** "Relational database with **auto-scaling**, **high availability** and **serverless**" → **Aurora Serverless v2**.

---

## DynamoDB - Capacity Modes and Limits

### Capacity Modes

| Mode | Description | When to Use |
|------|-------------|-------------|
| **On-Demand** | Pay per actual read/write. No planning | Unpredictable workloads, new apps, variable traffic |
| **Provisioned** | You define RCU/WCU. More economical for stable workloads | Predictable traffic, cost optimization |

### Capacity Units

| Unit | Definition |
|------|-----------|
| **1 RCU** | 1 strongly consistent read of up to 4 KB/s **OR** 2 eventually consistent reads of up to 4 KB/s |
| **1 WCU** | 1 write of up to 1 KB/s |

### Important Limits

| Parameter | Limit |
|-----------|-------|
| **Max item size** | 400 KB |
| **Partition key** | Up to 2,048 bytes |
| **Sort key** | Up to 1,024 bytes |
| **GSI per table** | 20 (default) |
| **LSI per table** | 5 (must be created when creating the table) |
| **Query/Scan result size** | 1 MB per call (paginate if more) |
| **Transactions** | Up to 100 items or 4 MB per transaction |

> **Exam keys:**
> - **DAX** (DynamoDB Accelerator): In-memory cache for DynamoDB. Microsecond latency. For read-intensive workloads.
> - **Global Tables**: Multi-region active-active replication. Requires DynamoDB Streams enabled.
> - **DynamoDB Streams**: Captures changes (CDC). Integrates with Lambda for triggers.

---

## ElastiCache: Redis vs Memcached

| Feature | Redis | Memcached |
|---------|-------|-----------|
| **Persistence** | **Yes** (snapshots, AOF) | No |
| **Replication** | **Yes** (Multi-AZ with failover) | No |
| **Clustering** | Yes (up to 500 nodes) | Yes (simple sharding) |
| **Data types** | Strings, hashes, lists, sets, sorted sets, streams | Simple strings |
| **Pub/Sub** | **Yes** | No |
| **Lua scripting** | **Yes** | No |
| **Multi-threaded** | No (single-threaded) | **Yes** |
| **Backup/Restore** | **Yes** | No |
| **Use case** | Sessions, leaderboards, queues, HA cache, real-time analytics | Simple cache, large objects, pure horizontal scaling |

> **Exam rule:**
> - If you need **persistence, replication, or complex data types** → **Redis**
> - If you only need a **simple and multi-threaded cache** → **Memcached**
> - **Almost always the answer is Redis** on the exam (unless they explicitly ask for simple multi-threading).

---

## When to Use Each Database

| Service | When to Use (1 line) |
|---------|---------------------|
| **RDS** | Need a managed relational database with a specific engine (Oracle, SQL Server, etc.) |
| **Aurora** | Relational with auto-scaling, high availability, and performance superior to standard RDS |
| **DynamoDB** | NoSQL key-value with millisecond latency at any scale, flexible schema |
| **ElastiCache** | In-memory cache to reduce latency of frequent reads from the database |
| **Redshift** | Data warehouse for analytics and OLAP queries over petabytes of data |
| **Neptune** | Graph database for complex relationships (social networks, fraud detection) |
| **DocumentDB** | Document database compatible with MongoDB managed on AWS |
| **QLDB** | Immutable ledger with cryptographically verifiable history (finance, supply chain) |
| **Timestream** | Time series for IoT, application metrics, sensor data |
| **Keyspaces** | Apache Cassandra-compatible managed — existing wide-column workloads |
| **MemoryDB** | Redis-compatible with durability (multi-AZ) — replaces Redis + database |

---

## Read Replicas vs Multi-AZ

| Feature | Read Replicas | Multi-AZ |
|---------|---------------|----------|
| **Purpose** | **Performance** (scale reads) | **Availability** (automatic failover) |
| **Replication type** | **Asynchronous** | **Synchronous** |
| **Read access** | **Yes** — can be used for reads | **No** — standby does not accept traffic |
| **Regions** | Same region or **cross-region** | Same region (different AZ) |
| **Automatic failover** | No (can be promoted manually) | **Yes** (automatic DNS) |
| **Max number** | Up to 15 (Aurora) / 5 (RDS) | 1 standby per instance |
| **Network cost** | Free in same region. Cross-region cost | Free (same region) |
| **Use case** | Reports, analytics, distribute read load | Production HA, intra-region disaster recovery |

```
                    ┌─────────────┐
    Writes ────────→│   PRIMARY   │
                    │  (Master)   │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │ Synchronous │            │ Asynchronous
              ▼            │            ▼
     ┌────────────┐        │    ┌──────────────┐
     │  STANDBY   │        │    │ READ REPLICA │ ← Reads
     │ (Multi-AZ) │        │    │  (scaling)   │
     │ NO traffic │        │    └──────────────┘
     └────────────┘        │
                           │ Asynchronous
                           ▼
                   ┌──────────────┐
                   │ READ REPLICA │ ← Reads
                   │ (cross-region)│
                   └──────────────┘
```

> **Exam key:** "Improve read performance" → **Read Replicas**. "High availability / disaster recovery" → **Multi-AZ**. You can have **both** at the same time.

---

## Quick Decision Summary - Databases

```
EXAM QUESTION                                        → ANSWER
────────────────────────────────────────────────────────────────────
"Relational DB, high availability, auto-scaling"      → Aurora
"Relational DB, Oracle or SQL Server"                 → RDS
"NoSQL, key-value, ms latency, massive scale"         → DynamoDB
"In-memory cache to reduce latency"                   → ElastiCache Redis
"Data warehouse, OLAP, analytics over PBs"            → Redshift
"Complex relationships, graphs"                       → Neptune
"MongoDB-compatible managed"                          → DocumentDB
"Immutable ledger, cryptographic auditing"            → QLDB
"Time series, IoT, metrics"                           → Timestream
"Multi-region relational replication"                 → Aurora Global Database
"DynamoDB cache with microsecond latency"             → DAX
```
