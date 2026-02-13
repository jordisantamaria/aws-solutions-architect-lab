# Arbol de Decisión: Selección de Base de Datos

## Pregunta Principal: ¿Qué tipo de base de datos necesitas?

```
¿Qué tipo de datos y consultas necesitas?
│
├── RELACIONAL (SQL, joins, transacciones ACID, schema fijo)
│   │
│   ├── ¿Necesitas auto-scaling, alta disponibilidad superior y rendimiento?
│   │   │
│   │   ├── SÍ ──→ Amazon Aurora
│   │   │   │
│   │   │   ├── ¿MySQL compatible? ──→ Aurora MySQL
│   │   │   ├── ¿PostgreSQL compatible? ──→ Aurora PostgreSQL
│   │   │   │
│   │   │   ├── ¿Carga variable/impredecible? ──→ Aurora Serverless v2
│   │   │   ├── ¿Multi-region replication? ──→ Aurora Global Database
│   │   │   └── ¿Múltiples escritores? ──→ Aurora Multi-Master
│   │   │
│   │   └── NO (o necesito motor específico)
│   │       │
│   │       └──→ Amazon RDS
│   │           │
│   │           ├── ¿MySQL? ──→ RDS MySQL
│   │           ├── ¿PostgreSQL? ──→ RDS PostgreSQL
│   │           ├── ¿MariaDB? ──→ RDS MariaDB
│   │           ├── ¿Oracle? ──→ RDS Oracle (BYOL o License Included)
│   │           ├── ¿SQL Server? ──→ RDS SQL Server
│   │           └── ¿Db2? ──→ RDS Db2
│   │
│   └── ¿Necesitas más rendimiento de lectura?
│       ├── Read Replicas (hasta 5 RDS / 15 Aurora)
│       └── ElastiCache delante de la BD
│
├── KEY-VALUE / DOCUMENT (NoSQL, schema flexible, escala masiva)
│   │
│   └──→ Amazon DynamoDB
│        │
│        ├── ¿Carga predecible? ──→ Provisioned Capacity (más económico)
│        ├── ¿Carga variable?   ──→ On-Demand Capacity
│        │
│        ├── ¿Necesitas latencia de microsegundos? ──→ DynamoDB + DAX
│        ├── ¿Multi-region activo-activo? ──→ DynamoDB Global Tables
│        └── ¿Event-driven (reaccionar a cambios)? ──→ DynamoDB Streams + Lambda
│
├── CACHE IN-MEMORY (microsegundos de latencia, datos temporales)
│   │
│   └──→ Amazon ElastiCache
│        │
│        ├── ¿Necesitas persistencia, replicación, tipos de datos complejos?
│        │   └──→ Redis
│        │       ├── Sesiones de usuario
│        │       ├── Leaderboards (sorted sets)
│        │       ├── Rate limiting
│        │       └── Pub/Sub en tiempo real
│        │
│        └── ¿Solo cache simple, multi-threaded?
│            └──→ Memcached
│                └── Cache de objetos grandes, pool de threads
│
├── GRAFOS (relaciones complejas entre entidades)
│   │
│   └──→ Amazon Neptune
│        ├── Redes sociales (amigos de amigos)
│        ├── Detección de fraude (patrones de transacciones)
│        ├── Knowledge graphs
│        └── Motor de recomendaciones basado en relaciones
│
├── DOCUMENTOS (JSON, compatible MongoDB)
│   │
│   └──→ Amazon DocumentDB
│        ├── Compatible con API de MongoDB
│        ├── Migración desde MongoDB on-prem
│        └── Escalable y gestionado
│
├── SERIES TEMPORALES (datos con timestamp, IoT, métricas)
│   │
│   └──→ Amazon Timestream
│        ├── Datos de sensores IoT
│        ├── Métricas de aplicación
│        ├── Logs con timestamp
│        └── Retención automática por tiers (memory → magnetic)
│
├── LEDGER / INMUTABLE (historial verificable, auditoría)
│   │
│   └──→ Amazon QLDB (Quantum Ledger Database)
│        ├── Historial de transacciones financieras
│        ├── Supply chain tracking
│        ├── Registro regulatorio inmutable
│        └── Hash criptográfico verificable (journal)
│
├── WIDE-COLUMN (compatible Cassandra)
│   │
│   └──→ Amazon Keyspaces
│        ├── Migración desde Apache Cassandra
│        ├── Cargas de trabajo IoT a gran escala
│        └── Time-series con modelo Cassandra
│
└── DATA WAREHOUSE / ANALYTICS (OLAP, queries analíticas masivas)
    │
    └──→ Amazon Redshift
         ├── Queries SQL sobre petabytes
         ├── BI dashboards (QuickSight, Tableau)
         ├── ¿Datos en S3? ──→ Redshift Spectrum (query sin cargar datos)
         ├── ¿Carga variable? ──→ Redshift Serverless
         └── ¿Machine Learning? ──→ Redshift ML
```

---

## Tabla de Decisión Rápida

| Requisito | Servicio | Razón principal |
|-----------|----------|----------------|
| SQL + máxima HA + auto-scaling | **Aurora** | 6 copias, 3 AZs, failover < 30s, storage auto-scaling |
| SQL + Oracle o SQL Server | **RDS** | Único servicio gestionado para estos engines |
| NoSQL key-value a cualquier escala | **DynamoDB** | Latencia ms, ilimitado, serverless disponible |
| Cache para reducir latencia de BD | **ElastiCache Redis** | Microsegundos, persistencia, replicación |
| Relaciones complejas (grafos) | **Neptune** | Optimizado para traversals de grafos |
| Compatible MongoDB | **DocumentDB** | API MongoDB, gestionado por AWS |
| Datos con timestamp / IoT | **Timestream** | Optimizado para ingest y query de series temporales |
| Registro inmutable auditable | **QLDB** | Ledger con hash criptográfico, no modificable |
| Analytics sobre petabytes | **Redshift** | Columnar, MPP, SQL estándar sobre datos masivos |
| Compatible Cassandra | **Keyspaces** | Misma API, serverless, gestionado |

---

## Patrones Comunes en el Examen

### Patrón 1: Aplicación web con lectura intensiva
```
Usuarios ──→ CloudFront ──→ ALB ──→ EC2/ECS ──→ ElastiCache (Redis)
                                                      │ (cache miss)
                                                      ▼
                                                 Aurora (Read Replicas)
```

### Patrón 2: Aplicación serverless con DynamoDB
```
API Gateway ──→ Lambda ──→ DynamoDB
                              │
                              ├── DAX (cache microsegundos)
                              └── DynamoDB Streams ──→ Lambda (procesamiento)
```

### Patrón 3: Analytics y reporting
```
Fuentes de datos ──→ S3 (data lake) ──→ Redshift (warehouse)
                                              │
                                              ├── Athena (queries ad-hoc sobre S3)
                                              └── QuickSight (dashboards)
```

### Patrón 4: Migración de base de datos
```
On-prem DB ──→ DMS (Database Migration Service) ──→ RDS / Aurora / DynamoDB
                    │
                    └── SCT (Schema Conversion Tool) si cambias de motor
```

---

## Keywords del Examen → Servicio

```
"Relational + high availability"              → Aurora
"Relational + Oracle/SQL Server"              → RDS
"Key-value + millisecond latency"             → DynamoDB
"Key-value + microsecond latency"             → DynamoDB + DAX
"In-memory cache"                             → ElastiCache (casi siempre Redis)
"Session store"                               → ElastiCache Redis o DynamoDB
"Social network / relationships"              → Neptune
"Fraud detection / graph"                     → Neptune
"MongoDB compatible"                          → DocumentDB
"IoT sensor data / time series"               → Timestream
"Immutable / ledger / auditable"              → QLDB
"Data warehouse / OLAP / BI"                  → Redshift
"Query S3 data with SQL"                      → Athena (serverless) o Redshift Spectrum
"Multi-region active-active NoSQL"            → DynamoDB Global Tables
"Multi-region relational"                     → Aurora Global Database
"Database migration"                          → DMS + SCT
"Cassandra compatible"                        → Keyspaces
"Durable Redis replacement"                   → MemoryDB for Redis
```
