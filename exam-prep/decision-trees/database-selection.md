# Decision Tree: Database Selection

## Main Question: What type of database do you need?

```
What type of data and queries do you need?
│
├── RELATIONAL (SQL, joins, ACID transactions, fixed schema)
│   │
│   ├── Do you need auto-scaling, superior high availability and performance?
│   │   │
│   │   ├── YES ──→ Amazon Aurora
│   │   │   │
│   │   │   ├── MySQL compatible? ──→ Aurora MySQL
│   │   │   ├── PostgreSQL compatible? ──→ Aurora PostgreSQL
│   │   │   │
│   │   │   ├── Variable/unpredictable workload? ──→ Aurora Serverless v2
│   │   │   ├── Multi-region replication? ──→ Aurora Global Database
│   │   │   └── Multiple writers? ──→ Aurora Multi-Master
│   │   │
│   │   └── NO (or I need a specific engine)
│   │       │
│   │       └──→ Amazon RDS
│   │           │
│   │           ├── MySQL? ──→ RDS MySQL
│   │           ├── PostgreSQL? ──→ RDS PostgreSQL
│   │           ├── MariaDB? ──→ RDS MariaDB
│   │           ├── Oracle? ──→ RDS Oracle (BYOL or License Included)
│   │           ├── SQL Server? ──→ RDS SQL Server
│   │           └── Db2? ──→ RDS Db2
│   │
│   └── Do you need more read performance?
│       ├── Read Replicas (up to 5 RDS / 15 Aurora)
│       └── ElastiCache in front of the DB
│
├── KEY-VALUE / DOCUMENT (NoSQL, flexible schema, massive scale)
│   │
│   └──→ Amazon DynamoDB
│        │
│        ├── Predictable workload? ──→ Provisioned Capacity (more economical)
│        ├── Variable workload?   ──→ On-Demand Capacity
│        │
│        ├── Need microsecond latency? ──→ DynamoDB + DAX
│        ├── Multi-region active-active? ──→ DynamoDB Global Tables
│        └── Event-driven (react to changes)? ──→ DynamoDB Streams + Lambda
│
├── IN-MEMORY CACHE (microsecond latency, temporary data)
│   │
│   └──→ Amazon ElastiCache
│        │
│        ├── Need persistence, replication, complex data types?
│        │   └──→ Redis
│        │       ├── User sessions
│        │       ├── Leaderboards (sorted sets)
│        │       ├── Rate limiting
│        │       └── Real-time Pub/Sub
│        │
│        └── Just simple cache, multi-threaded?
│            └──→ Memcached
│                └── Large object cache, thread pool
│
├── GRAPH (complex relationships between entities)
│   │
│   └──→ Amazon Neptune
│        ├── Social networks (friends of friends)
│        ├── Fraud detection (transaction patterns)
│        ├── Knowledge graphs
│        └── Relationship-based recommendation engines
│
├── DOCUMENT (JSON, MongoDB compatible)
│   │
│   └──→ Amazon DocumentDB
│        ├── Compatible with MongoDB API
│        ├── Migration from on-prem MongoDB
│        └── Scalable and managed
│
├── TIME SERIES (data with timestamps, IoT, metrics)
│   │
│   └──→ Amazon Timestream
│        ├── IoT sensor data
│        ├── Application metrics
│        ├── Timestamped logs
│        └── Automatic retention by tiers (memory → magnetic)
│
├── LEDGER / IMMUTABLE (verifiable history, auditing)
│   │
│   └──→ Amazon QLDB (Quantum Ledger Database)
│        ├── Financial transaction history
│        ├── Supply chain tracking
│        ├── Immutable regulatory records
│        └── Verifiable cryptographic hash (journal)
│
├── WIDE-COLUMN (Cassandra compatible)
│   │
│   └──→ Amazon Keyspaces
│        ├── Migration from Apache Cassandra
│        ├── Large-scale IoT workloads
│        └── Time-series with Cassandra model
│
└── DATA WAREHOUSE / ANALYTICS (OLAP, massive analytical queries)
    │
    └──→ Amazon Redshift
         ├── SQL queries over petabytes
         ├── BI dashboards (QuickSight, Tableau)
         ├── Data in S3? ──→ Redshift Spectrum (query without loading data)
         ├── Variable workload? ──→ Redshift Serverless
         └── Machine Learning? ──→ Redshift ML
```

---

## Quick Decision Table

| Requirement | Service | Main Reason |
|-------------|---------|-------------|
| SQL + maximum HA + auto-scaling | **Aurora** | 6 copies, 3 AZs, failover < 30s, storage auto-scaling |
| SQL + Oracle or SQL Server | **RDS** | Only managed service for these engines |
| NoSQL key-value at any scale | **DynamoDB** | ms latency, unlimited, serverless available |
| Cache to reduce DB latency | **ElastiCache Redis** | Microseconds, persistence, replication |
| Complex relationships (graphs) | **Neptune** | Optimized for graph traversals |
| MongoDB compatible | **DocumentDB** | MongoDB API, managed by AWS |
| Data with timestamps / IoT | **Timestream** | Optimized for time series ingest and query |
| Immutable auditable record | **QLDB** | Ledger with cryptographic hash, non-modifiable |
| Analytics over petabytes | **Redshift** | Columnar, MPP, standard SQL over massive data |
| Cassandra compatible | **Keyspaces** | Same API, serverless, managed |

---

## Common Exam Patterns

### Pattern 1: Read-intensive web application
```
Users ──→ CloudFront ──→ ALB ──→ EC2/ECS ──→ ElastiCache (Redis)
                                                    │ (cache miss)
                                                    ▼
                                               Aurora (Read Replicas)
```

### Pattern 2: Serverless application with DynamoDB
```
API Gateway ──→ Lambda ──→ DynamoDB
                              │
                              ├── DAX (microsecond cache)
                              └── DynamoDB Streams ──→ Lambda (processing)
```

### Pattern 3: Analytics and reporting
```
Data sources ──→ S3 (data lake) ──→ Redshift (warehouse)
                                          │
                                          ├── Athena (ad-hoc queries on S3)
                                          └── QuickSight (dashboards)
```

### Pattern 4: Database migration
```
On-prem DB ──→ DMS (Database Migration Service) ──→ RDS / Aurora / DynamoDB
                    │
                    └── SCT (Schema Conversion Tool) if changing engines
```

---

## Exam Keywords → Service

```
"Relational + high availability"              → Aurora
"Relational + Oracle/SQL Server"              → RDS
"Key-value + millisecond latency"             → DynamoDB
"Key-value + microsecond latency"             → DynamoDB + DAX
"In-memory cache"                             → ElastiCache (almost always Redis)
"Session store"                               → ElastiCache Redis or DynamoDB
"Social network / relationships"              → Neptune
"Fraud detection / graph"                     → Neptune
"MongoDB compatible"                          → DocumentDB
"IoT sensor data / time series"               → Timestream
"Immutable / ledger / auditable"              → QLDB
"Data warehouse / OLAP / BI"                  → Redshift
"Query S3 data with SQL"                      → Athena (serverless) or Redshift Spectrum
"Multi-region active-active NoSQL"            → DynamoDB Global Tables
"Multi-region relational"                     → Aurora Global Database
"Database migration"                          → DMS + SCT
"Cassandra compatible"                        → Keyspaces
"Durable Redis replacement"                   → MemoryDB for Redis
```
