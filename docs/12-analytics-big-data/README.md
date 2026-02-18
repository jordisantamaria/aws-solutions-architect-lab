# Analytics y Big Data en AWS

## Tabla de Contenidos

- [Amazon Athena](#amazon-athena)
- [AWS Glue](#aws-glue)
- [Amazon EMR](#amazon-emr)
- [Amazon QuickSight](#amazon-quicksight)
- [Amazon OpenSearch Service](#amazon-opensearch-service)
- [Amazon MSK (Managed Streaming for Apache Kafka)](#amazon-msk)
- [AWS Lake Formation](#aws-lake-formation)
- [Arquitectura de referencia: Data Lake en AWS](#arquitectura-de-referencia-data-lake-en-aws)
- [Decision Tree: elegir el servicio de analytics correcto](#decision-tree-elegir-el-servicio-de-analytics-correcto)
- [Analytics Exam Tips](#analytics-exam-tips)

---

## Amazon Athena

Servicio **serverless** de queries interactivas que permite ejecutar SQL directamente sobre datos almacenados en **S3**.

### Características principales

| Característica | Detalle |
|---------------|---------|
| **Modelo** | Serverless (sin infraestructura que gestionar) |
| **Lenguaje** | SQL estándar (basado en Presto/Trino) |
| **Fuente de datos** | S3 (principal), también connectors a otras fuentes via Federated Query |
| **Formatos soportados** | CSV, JSON, Parquet, ORC, Avro, TSV |
| **Precio** | $5 por TB escaneado |
| **Integración** | Glue Data Catalog como metastore, QuickSight para visualización |

### Optimización de costes y rendimiento

El precio de Athena se basa en los **datos escaneados**, así que reducir el escaneo = reducir coste:

| Técnica | Ahorro | Cómo |
|---------|--------|------|
| **Formatos columnares (Parquet/ORC)** | Hasta 90% | Solo lee las columnas que necesitas, no toda la fila |
| **Compresión (gzip, snappy, zstd)** | 50-80% | Menos bytes que leer |
| **Particionado** | Variable (enorme) | Divide datos por fecha/región/etc. Athena solo lee las particiones relevantes |
| **Bucketing** | Variable | Agrupa datos dentro de una partición para queries más eficientes |

**Ejemplo de particionado en S3:**

```
s3://mi-datalake/ventas/
    year=2024/month=01/data.parquet
    year=2024/month=02/data.parquet
    year=2025/month=01/data.parquet
```

```sql
-- Solo escanea la partición de enero 2025, no todo el bucket
SELECT * FROM ventas WHERE year = 2025 AND month = 1;
```

### Athena Federated Query

- Permite ejecutar SQL sobre fuentes de datos **más allá de S3**: DynamoDB, RDS, Redshift, CloudWatch Logs, on-premises (via JDBC).
- Usa **Lambda connectors** para conectarse a cada fuente.
- Caso de uso: queries que cruzan datos de S3 con datos en DynamoDB o RDS sin moverlos.

### Casos de uso principales

- Análisis ad-hoc de logs en S3 (VPC Flow Logs, ALB logs, CloudTrail logs).
- Queries de negocio sobre data lake en S3.
- Reporting que no justifica un data warehouse permanente (Redshift).
- Complemento de QuickSight para dashboards.

> **Tip para el examen:** Si la pregunta dice "analizar datos en S3 con SQL", "serverless query", "sin infraestructura", "pago por query" → **Athena**. Si dice "data warehouse con queries complejas, joins masivos, datos estructurados a gran escala" → **Redshift**.

---

## AWS Glue

Servicio **serverless** de ETL (Extract, Transform, Load) y catálogo de datos.

### Componentes

| Componente | Descripción |
|-----------|-------------|
| **Glue Data Catalog** | Metastore centralizado. Almacena definiciones de tablas, schemas, ubicación de datos. Lo usan Athena, Redshift Spectrum, EMR |
| **Glue Crawlers** | Escanean fuentes de datos (S3, RDS, DynamoDB) y descubren automáticamente el schema, creando tablas en el Data Catalog |
| **Glue ETL Jobs** | Scripts (Python/Scala con Apache Spark) que transforman datos entre fuentes |
| **Glue DataBrew** | Herramienta visual (sin código) para limpiar y normalizar datos |
| **Glue Studio** | Interfaz visual para crear ETL jobs sin escribir código |

### Glue Data Catalog

```
Fuentes de datos (S3, RDS, DynamoDB)
    │
    ▼
Glue Crawler (escanea y descubre schema)
    │
    ▼
Glue Data Catalog (metastore centralizado)
    │
    ├── Athena usa el catálogo para saber qué tablas hay en S3
    ├── Redshift Spectrum usa el catálogo para queries externas
    └── EMR usa el catálogo como Hive metastore
```

- El Data Catalog es el **pegamento** que conecta los servicios de analytics.
- Es compatible con Apache Hive Metastore.
- Almacena: databases, tables, partitions, column definitions, locations.

### Glue ETL Jobs

- Se ejecutan sobre Apache Spark (serverless, AWS gestiona el cluster).
- Fuentes: S3, RDS, Redshift, DynamoDB, JDBC.
- Destinos: S3 (Parquet, ORC, JSON, CSV), Redshift, RDS, Glue Data Catalog.
- Soporta **job bookmarks** para procesar solo datos nuevos (incremental ETL).
- Transformaciones: mapear columnas, filtrar, join, agregar, cambiar formatos.

### Glue vs otros servicios de ETL

| Servicio | Cuándo usarlo |
|----------|--------------|
| **Glue ETL** | ETL serverless, transformaciones Spark, integrado con Data Catalog |
| **EMR** | ETL con control total del cluster, workloads Spark/Hadoop complejos |
| **Lambda** | Transformaciones simples y ligeras (< 15 min, < 10 GB) |
| **Kinesis Data Firehose** | Transformaciones ligeras en streaming (near real-time) |
| **DMS** | Migración de base de datos a base de datos (no transformación compleja) |

> **Tip para el examen:** Si la pregunta menciona "descubrir schema automáticamente", "catálogo de datos", "ETL serverless" → **Glue**. Si dice "ETL con Spark/Hadoop y control del cluster" → **EMR**. El Glue Data Catalog aparece frecuentemente como respuesta cuando se necesita un metastore centralizado.

---

## Amazon EMR

Amazon EMR (Elastic MapReduce) es un servicio gestionado para ejecutar frameworks de **Big Data** como Apache Hadoop, Spark, Hive, HBase, Presto, Flink.

### Modos de despliegue

| Modo | Descripción | Caso de uso |
|------|-------------|-------------|
| **EMR on EC2** | Cluster de instancias EC2 gestionado por EMR | Control total, workloads complejos, GPU |
| **EMR on EKS** | Jobs de Spark sobre un cluster EKS existente | Equipos que ya usan Kubernetes |
| **EMR Serverless** | Sin cluster que gestionar, pago por uso | Jobs ad-hoc, equipos que no quieren gestionar infra |

### Arquitectura del cluster EMR on EC2

```
EMR Cluster
├── Master Node (1)      → Coordina el cluster, ejecuta YARN ResourceManager
├── Core Nodes (N)       → Almacenan datos en HDFS + ejecutan tareas
└── Task Nodes (N)       → Solo ejecutan tareas (sin HDFS). Ideal para Spot Instances
```

- **Master Node**: Siempre On-Demand (si falla, pierdes el cluster).
- **Core Nodes**: On-Demand o Reserved (almacenan datos HDFS).
- **Task Nodes**: **Spot Instances** (solo cómputo, no almacenan datos, tolerantes a interrupción).

### Almacenamiento en EMR

| Opción | Descripción | Persistencia |
|--------|-------------|-------------|
| **HDFS** | En los core nodes del cluster | Se pierde al terminar el cluster |
| **EMRFS (S3)** | Usa S3 como sistema de archivos | Persistente. Recomendado para data lakes |
| **EBS** | Volúmenes adjuntos a los nodos | Se pierde al terminar el cluster |

> **Recomendación:** Usar EMRFS (S3) para datos persistentes y HDFS solo para datos temporales intermedios que necesitan baja latencia.

### Casos de uso

- Machine learning a gran escala (Spark MLlib).
- Procesamiento de logs y ETL masivo.
- Análisis de datos genómicos.
- Análisis de datos financieros.
- Procesamiento de datos geoespaciales.

### EMR vs Glue vs Athena

| Pregunta | Servicio |
|----------|---------|
| "Quiero ejecutar SQL sobre datos en S3 sin infra" | **Athena** |
| "Necesito ETL serverless integrado con Data Catalog" | **Glue** |
| "Necesito Spark/Hadoop con control del cluster y librerías custom" | **EMR on EC2** |
| "Necesito Spark serverless sin gestionar cluster" | **EMR Serverless** o **Glue** |

> **Tip para el examen:** Si la pregunta menciona "Hadoop", "Spark", "Hive", "HBase", "Presto", "big data processing", "machine learning con Spark" → **EMR**. Si menciona "Spot Instances para big data" → Task Nodes de EMR con Spot.

---

## Amazon QuickSight

Servicio de **Business Intelligence (BI)** serverless para crear dashboards y visualizaciones interactivas.

### Características principales

| Característica | Detalle |
|---------------|---------|
| **Modelo** | Serverless, pago por sesión o por usuario |
| **SPICE** | Motor in-memory (Super-fast, Parallel, In-memory Calculation Engine). Importa datos para queries rápidas |
| **Fuentes de datos** | Athena, S3, RDS, Aurora, Redshift, DynamoDB, OpenSearch, Salesforce, JDBC/ODBC |
| **Funcionalidades** | Dashboards, análisis ad-hoc, ML Insights (anomalías, forecasting), alertas |
| **Seguridad** | Integración con IAM, row-level security (RLS), column-level security (CLS) |

### Arquitectura típica

```
Datos (S3, RDS, Redshift, Athena)
    │
    ▼
QuickSight (importa a SPICE o direct query)
    │
    ▼
Dashboards interactivos (compartidos con usuarios)
```

### Ediciones

| Característica | Standard | Enterprise |
|---------------|----------|------------|
| **Autenticación** | IAM, email | IAM, email, Active Directory, SAML |
| **Row-level security** | No | Sí |
| **Column-level security** | No | Sí |
| **Private VPC access** | No | Sí |
| **Embedded dashboards** | No | Sí |
| **ML Insights** | Limitado | Completo |

> **Tip para el examen:** Si la pregunta dice "BI", "dashboards", "visualización de datos", "business users" → **QuickSight**. Si dice "SPICE" → QuickSight. Si necesita row-level security → QuickSight Enterprise.

---

## Amazon OpenSearch Service

Servicio gestionado de **OpenSearch** (fork de Elasticsearch) para búsqueda, análisis de logs y observabilidad.

### Características principales

| Característica | Detalle |
|---------------|---------|
| **Modelo** | Cluster gestionado (no serverless, aunque existe OpenSearch Serverless) |
| **Funcionalidades** | Búsqueda full-text, análisis de logs, dashboards (OpenSearch Dashboards / Kibana) |
| **Ingesta** | Kinesis Data Firehose, CloudWatch Logs, Lambda, Logstash, FluentBit |
| **Despliegue** | Multi-AZ (hasta 3 AZs), cifrado en reposo y en tránsito |

### Patrones comunes

**Análisis de logs en tiempo real:**

```
CloudWatch Logs / Kinesis Data Firehose / IoT
    │
    ▼
OpenSearch cluster (indexa y permite búsqueda)
    │
    ▼
OpenSearch Dashboards (visualización en tiempo real)
```

**Búsqueda full-text en aplicación:**

```
DynamoDB (fuente de verdad)
    │
    ▼ (DynamoDB Streams → Lambda)
OpenSearch (índice de búsqueda)
    │
    ▼
Aplicación busca en OpenSearch, lee detalle de DynamoDB
```

### OpenSearch vs CloudWatch Logs Insights vs Athena

| Pregunta | Servicio |
|----------|---------|
| "Búsqueda full-text sobre logs/documentos" | **OpenSearch** |
| "Análisis de logs ad-hoc rápido, sin infra" | **CloudWatch Logs Insights** |
| "SQL sobre logs en S3, pago por query" | **Athena** |
| "Dashboards de logs en tiempo real con KQL" | **OpenSearch Dashboards** |

### OpenSearch Serverless

- Versión serverless de OpenSearch (sin gestionar clusters).
- Auto-escala según la carga.
- Dos modos: **Time Series** (logs, métricas) y **Search** (búsqueda full-text).
- Más simple pero con menos control que el cluster gestionado.

> **Tip para el examen:** Si la pregunta menciona "búsqueda full-text", "Elasticsearch", "Kibana", "análisis de logs en tiempo real con dashboards" → **OpenSearch**. Si dice "search" en el contexto de una aplicación → probablemente OpenSearch como índice de búsqueda.

---

## Amazon MSK

Amazon MSK (Managed Streaming for Apache Kafka) es un servicio gestionado de **Apache Kafka** para streaming de datos.

### Kafka en 30 segundos

```
Producers (envían datos) → Kafka Topics (organizados en particiones) → Consumers (leen datos)
```

- **Topic**: Canal de datos con nombre (ej: "orders", "clickstream").
- **Partition**: Subdivisión de un topic para paralelismo.
- **Broker**: Servidor Kafka que almacena y sirve datos.
- **Consumer Group**: Grupo de consumers que se reparten las particiones.

### MSK vs Kinesis Data Streams

| Característica | Amazon MSK | Kinesis Data Streams |
|---------------|-----------|---------------------|
| **Protocolo** | Apache Kafka (open source) | API propietaria de AWS |
| **Modelo** | Cluster gestionado (brokers) | Serverless (shards) |
| **Retención** | Ilimitada (disco) | 1-365 días |
| **Mensaje máximo** | 1 MB (default), configurable hasta mayor | 1 MB |
| **Consumers** | Kafka Consumer API, Connect | Kinesis Client Library, Lambda |
| **Ecosistema** | Kafka Connect, Kafka Streams, KSQL | Integración nativa AWS |
| **Portabilidad** | Alto (Kafka es open source, funciona en cualquier cloud) | AWS lock-in |
| **Coste** | Pagas por broker (instancia) | Pagas por shard/hora + datos |
| **Cuándo usar** | Ya usas Kafka, necesitas ecosistema Kafka, portabilidad | Solución AWS-native, integración simple con Lambda/S3 |

### MSK Serverless

- Versión serverless de MSK (sin gestionar brokers).
- Auto-escala según la carga.
- Pagas por datos y particiones, no por instancias.
- Ideal para cargas variables o equipos que no quieren gestionar Kafka.

### MSK Connect

- Servicio gestionado de **Kafka Connect** para mover datos entre Kafka y otros sistemas.
- Conectores prebuilds: S3 Sink, Elasticsearch Sink, Debezium (CDC), JDBC.
- Ejemplo: MSK → S3 automáticamente sin código.

> **Tip para el examen:** Si la pregunta menciona "Kafka", "ecosistema Kafka", "migrar Kafka a AWS", "portabilidad" → **MSK**. Si dice "streaming de datos nativo AWS" sin mencionar Kafka → **Kinesis**. Si dice "streaming serverless de Kafka" → **MSK Serverless**.

---

## AWS Lake Formation

Servicio para crear, gestionar y asegurar **data lakes** en S3.

### Qué problema resuelve

Sin Lake Formation, montar un data lake requiere:
- Configurar permisos de S3 por bucket/prefix manualmente.
- Gestionar políticas IAM complejas para cada equipo/usuario.
- Implementar seguridad a nivel de columna o fila manualmente.

Lake Formation **centraliza todo esto**.

### Componentes

| Componente | Descripción |
|-----------|-------------|
| **Data Catalog** | Usa el Glue Data Catalog como base |
| **Security** | Permisos centralizados a nivel de base de datos, tabla, columna y fila |
| **Blueprints** | Workflows predefinidos para ingestar datos de RDS, CloudTrail, etc. a S3 |
| **Data Filters** | Row-level y column-level security sobre tablas del catálogo |
| **Governed Tables** | Tablas con soporte ACID (transacciones sobre S3) |

### Modelo de seguridad

```
Sin Lake Formation:
    IAM Policies + S3 Bucket Policies + KMS Policies = complejo, descentralizado

Con Lake Formation:
    Lake Formation Permissions (GRANT/REVOKE tipo SQL)
        → "Usuario X puede ver columnas A,B,C de la tabla Y"
        → "Equipo Z solo puede ver filas donde region='EU'"
```

- Centraliza permisos en un solo lugar (en vez de IAM + S3 + Glue policies).
- Soporta **column-level** y **row-level security**.
- Se integra con: Athena, Redshift Spectrum, EMR, Glue.

### Arquitectura típica

```
Fuentes (RDS, S3, on-premises)
    │
    ▼
Lake Formation (ingesta via Blueprints, seguridad centralizada)
    │
    ▼
Data Lake en S3 (Parquet, catalogado en Glue Data Catalog)
    │
    ├── Athena (queries ad-hoc)
    ├── Redshift Spectrum (analytics)
    ├── EMR (big data processing)
    └── QuickSight (dashboards)
```

> **Tip para el examen:** Si la pregunta menciona "seguridad centralizada de data lake", "permisos a nivel de columna/fila en S3", "governanza de datos" → **Lake Formation**. Si solo necesitas un metastore → **Glue Data Catalog** (sin Lake Formation).

---

## Arquitectura de referencia: Data Lake en AWS

Cómo encajan todos los servicios juntos:

```
INGESTA                    ALMACENAMIENTO          PROCESAMIENTO            CONSUMO
─────────                  ──────────────          ─────────────            ───────
Kinesis Data Streams  ─┐
Kinesis Firehose      ─┤
MSK (Kafka)           ─┤                                                   Athena (SQL ad-hoc)
IoT Core              ─┤                                                      │
DMS (bases de datos)  ─┼──► S3 (Data Lake) ──► Glue ETL / EMR ──────────► QuickSight (BI)
API Gateway + Lambda  ─┤       │                                              │
Glue Crawlers         ─┤       │                                           Redshift (DW)
DataSync (on-prem)    ─┘       │                                              │
                               ▼                                           OpenSearch (búsqueda)
                        Glue Data Catalog                                     │
                        Lake Formation                                     SageMaker (ML)
                        (seguridad centralizada)
```

---

## Decision Tree: elegir el servicio de analytics correcto

```
¿Qué necesitas hacer?
│
├── Ejecutar SQL sobre datos en S3
│   ├── Queries ad-hoc, pago por query → Athena
│   └── Data warehouse con datos estructurados, queries complejos, joins masivos → Redshift
│
├── Transformar datos (ETL)
│   ├── Serverless, integrado con Data Catalog → Glue
│   ├── Spark/Hadoop con control total del cluster → EMR
│   └── Transformación simple y ligera → Lambda o Kinesis Firehose
│
├── Streaming de datos
│   ├── AWS-native, integración con Lambda → Kinesis
│   └── Ecosistema Kafka, portabilidad → MSK
│
├── Visualizar datos (dashboards)
│   └── QuickSight
│
├── Búsqueda full-text / análisis de logs en tiempo real
│   └── OpenSearch
│
├── Catálogo de datos centralizado
│   └── Glue Data Catalog
│
└── Gobernanza y seguridad de data lake (permisos por columna/fila)
    └── Lake Formation
```

---

## Analytics Exam Tips

### Athena

1. **"SQL sobre S3 sin infraestructura"** → Athena.
2. **"Reducir costes de Athena"** → Formato columnar (Parquet/ORC) + particionado + compresión.
3. **"Analizar CloudTrail logs / VPC Flow Logs / ALB logs con SQL"** → Athena sobre los logs en S3.
4. **"Query que cruza datos de S3 con RDS"** → Athena Federated Query.

### Glue

5. **"Descubrir schema de datos en S3 automáticamente"** → Glue Crawler.
6. **"Catálogo de datos centralizado"** → Glue Data Catalog.
7. **"ETL serverless"** → Glue ETL Jobs.
8. **"Transformar datos sin código"** → Glue DataBrew.
9. **"Convertir CSV a Parquet"** → Glue ETL Job.

### EMR

10. **"Hadoop, Spark, Hive, HBase, Presto"** → EMR.
11. **"Big data con Spot Instances"** → EMR Task Nodes con Spot.
12. **"Machine learning con Spark MLlib"** → EMR.
13. **"Spark sin gestionar cluster"** → EMR Serverless o Glue.

### QuickSight

14. **"Dashboards", "BI", "visualización"** → QuickSight.
15. **"SPICE"** → QuickSight (motor in-memory).
16. **"Row-level security en dashboards"** → QuickSight Enterprise.
17. **"Embedded analytics en app web"** → QuickSight Enterprise (embedded dashboards).

### OpenSearch

18. **"Búsqueda full-text"** → OpenSearch.
19. **"Elasticsearch", "Kibana", "ELK stack"** → OpenSearch.
20. **"Análisis de logs en tiempo real con dashboards"** → OpenSearch + OpenSearch Dashboards.
21. **"Índice de búsqueda complementario a DynamoDB"** → DynamoDB Streams → Lambda → OpenSearch.

### MSK

22. **"Kafka", "migrar Kafka a AWS"** → MSK.
23. **"Streaming con portabilidad multi-cloud"** → MSK (Kafka es open source).
24. **"Kafka sin gestionar brokers"** → MSK Serverless.
25. **"Kinesis vs MSK"** → Kinesis = AWS-native, simple. MSK = Kafka ecosystem, portable.

### Lake Formation

26. **"Seguridad centralizada de data lake"** → Lake Formation.
27. **"Permisos a nivel de columna en S3"** → Lake Formation.
28. **"Row-level security sobre data lake"** → Lake Formation Data Filters.
29. **"Simplificar permisos de IAM + S3 para datos"** → Lake Formation.

### Patrones recurrentes

30. **Pipeline de analytics típico:** S3 → Glue Crawler (cataloga) → Athena (query) → QuickSight (visualiza).
31. **Streaming a analytics:** Kinesis/MSK → Firehose → S3 → Athena / Redshift.
32. **ETL + Data Lake:** Glue ETL (transforma) → S3 (Parquet) → Lake Formation (seguridad) → Athena/Redshift (query).
33. **Logs en tiempo real:** CloudWatch Logs → Subscription Filter → OpenSearch → Dashboards.
