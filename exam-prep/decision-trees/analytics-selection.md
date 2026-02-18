# Decision Tree: Selección de servicio de Analytics

## ¿Qué necesitas hacer con los datos?

```
¿Qué necesitas hacer?
│
├── CONSULTAR datos
│   ├── ¿Dónde están los datos?
│   │   ├── En S3 → ¿Query ad-hoc o recurrente?
│   │   │   ├── Ad-hoc, pago por query → Athena
│   │   │   └── Queries complejos, recurrentes, joins masivos → Redshift (o Redshift Spectrum sobre S3)
│   │   ├── En múltiples fuentes (S3 + RDS + DynamoDB) → Athena Federated Query
│   │   └── Logs en CloudWatch → CloudWatch Logs Insights
│   │
│   └── ¿Necesitas búsqueda full-text?
│       └── Sí → OpenSearch
│
├── TRANSFORMAR datos (ETL)
│   ├── ¿Serverless o con control del cluster?
│   │   ├── Serverless, integrado con catálogo → Glue ETL
│   │   ├── Serverless, Spark sin gestionar → EMR Serverless
│   │   ├── Control total (Spark/Hadoop custom) → EMR on EC2
│   │   └── Transformación simple (< 15 min) → Lambda
│   │
│   └── ¿Sin código?
│       └── Glue DataBrew
│
├── STREAMING de datos
│   ├── ¿Kafka o AWS-native?
│   │   ├── Kafka (portabilidad, ecosistema existente) → MSK
│   │   ├── Kafka serverless → MSK Serverless
│   │   ├── AWS-native, integración simple con Lambda/S3 → Kinesis Data Streams
│   │   └── Delivery a S3/Redshift/OpenSearch sin código → Kinesis Data Firehose
│   │
│   └── ¿Análisis SQL en tiempo real sobre stream?
│       └── Kinesis Data Analytics (Apache Flink)
│
├── VISUALIZAR datos (dashboards)
│   └── QuickSight
│       ├── Standard: básico
│       └── Enterprise: row-level security, embedded, AD integration
│
├── CATALOGAR datos
│   ├── Solo metastore → Glue Data Catalog
│   ├── Descubrir schema automáticamente → Glue Crawler
│   └── Gobernanza + seguridad por columna/fila → Lake Formation
│
└── MOVER datos
    ├── Base de datos → base de datos → DMS
    ├── On-premises → S3 (red) → DataSync
    ├── On-premises → S3 (físico, TB/PB) → Snow Family
    └── Kafka → S3/OpenSearch → MSK Connect
```

## Comparaciones frecuentes en el examen

### Athena vs Redshift

| Criterio | Athena | Redshift |
|----------|--------|----------|
| Modelo | Serverless | Cluster (o Serverless) |
| Datos | En S3 (no los mueve) | Cargados en Redshift (o Spectrum sobre S3) |
| Mejor para | Queries ad-hoc, análisis exploratorio | Data warehouse, queries recurrentes complejos |
| Coste | $5/TB escaneado | Por nodo-hora (fijo) |
| Rendimiento | Bueno para queries simples | Superior para joins masivos y queries complejos |

### Glue vs EMR

| Criterio | Glue | EMR |
|----------|------|-----|
| Modelo | Serverless | Cluster gestionado (o serverless) |
| Motor | Spark (gestionado) | Spark, Hadoop, Hive, Presto, Flink... |
| Control | Limitado | Total (puedes instalar librerías, configurar cluster) |
| Integración | Data Catalog nativo | Cualquier ecosistema Hadoop |
| Mejor para | ETL estándar, conversión de formatos | Big data complejo, ML con Spark, custom frameworks |

### Kinesis vs MSK

| Criterio | Kinesis | MSK |
|----------|---------|-----|
| Protocolo | AWS API propietaria | Apache Kafka (open source) |
| Modelo | Shards (serverless-like) | Brokers (cluster) o Serverless |
| Portabilidad | AWS lock-in | Multi-cloud (Kafka estándar) |
| Integración | Lambda, Firehose, Analytics (nativo AWS) | Kafka Connect, Kafka Streams, KSQL |
| Mejor para | Integración simple con AWS | Equipos con experiencia Kafka, portabilidad |

### OpenSearch vs CloudWatch Logs Insights

| Criterio | OpenSearch | CloudWatch Logs Insights |
|----------|-----------|------------------------|
| Modelo | Cluster (o serverless) | Serverless (pay per query) |
| Funcionalidad | Búsqueda full-text, dashboards, alertas | Queries de logs ad-hoc |
| Setup | Medio-alto | Zero (ya integrado con CloudWatch) |
| Mejor para | Logs a gran escala con dashboards en tiempo real | Análisis rápido de logs sin infra adicional |
