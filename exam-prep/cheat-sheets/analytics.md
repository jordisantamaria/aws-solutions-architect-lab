# Analytics y Big Data - Cheat Sheet

## Cuándo usar cada servicio

| Necesidad | Servicio | Clave para recordar |
|-----------|---------|-------------------|
| SQL sobre S3 sin infra | **Athena** | Serverless, $5/TB escaneado |
| Catálogo de datos centralizado | **Glue Data Catalog** | Metastore para Athena/EMR/Redshift |
| Descubrir schema automáticamente | **Glue Crawler** | Escanea S3/RDS → crea tablas en catálogo |
| ETL serverless | **Glue ETL** | Spark bajo el capó |
| ETL visual sin código | **Glue DataBrew** | Limpieza y normalización |
| Big data (Hadoop/Spark/Hive) | **EMR** | Cluster gestionado, Task Nodes con Spot |
| Spark sin cluster | **EMR Serverless** o **Glue** | Sin infra |
| Dashboards / BI | **QuickSight** | SPICE = motor in-memory |
| Búsqueda full-text | **OpenSearch** | Ex-Elasticsearch |
| Análisis de logs en tiempo real | **OpenSearch** + Dashboards | Ex-Kibana |
| Streaming AWS-native | **Kinesis** | Data Streams + Firehose |
| Streaming Kafka | **MSK** | Portable, ecosistema Kafka |
| Gobernanza data lake | **Lake Formation** | Permisos por columna/fila en S3 |
| Data warehouse SQL | **Redshift** | MPP, columnar, petabyte-scale |
| Convertir CSV → Parquet | **Glue ETL** | Formato columnar = Athena más barato |

## Diferenciadores rápidos

| Pregunta del examen | Respuesta |
|---------------------|-----------|
| "Analizar datos en S3 con SQL" | Athena |
| "Data warehouse con joins complejos" | Redshift |
| "ETL serverless" | Glue |
| "Hadoop, Spark, Hive, HBase" | EMR |
| "BI, dashboards, visualización" | QuickSight |
| "Elasticsearch, Kibana, búsqueda" | OpenSearch |
| "Kafka en AWS" | MSK |
| "Seguridad por columna en data lake" | Lake Formation |
| "Descubrir schema en S3" | Glue Crawler |
| "Catálogo de datos" | Glue Data Catalog |
| "Streaming a S3 near real-time" | Kinesis Firehose |
| "SPICE" | QuickSight |
| "Reducir coste de Athena" | Parquet + particionado + compresión |
| "Spot Instances para big data" | EMR Task Nodes |
| "Row-level security en dashboards" | QuickSight Enterprise |

## Pipeline típico de data lake

```
Ingesta → Almacenamiento → Catálogo → Procesamiento → Consumo

Kinesis/MSK → S3 (raw) → Glue Crawler → Glue ETL → S3 (Parquet)
                          (Data Catalog)              ↓
                                                Lake Formation (seguridad)
                                                      ↓
                                          Athena / Redshift / QuickSight
```

## Costes

| Servicio | Modelo de precio |
|----------|-----------------|
| **Athena** | $5/TB escaneado (reducir con Parquet/particionado) |
| **Glue** | DPU-hora (Data Processing Unit). Crawlers: por tiempo de ejecución |
| **EMR** | Instancias EC2 del cluster + fee de EMR (~15-25% sobre EC2) |
| **QuickSight** | Por usuario/mes (Standard ~$9, Enterprise ~$18) o por sesión |
| **OpenSearch** | Instancias del cluster + almacenamiento |
| **MSK** | Por broker-hora + almacenamiento |
| **Lake Formation** | Gratis (pagas por los servicios subyacentes: S3, Glue, etc.) |
| **Redshift** | Por nodo-hora (o Redshift Serverless: por RPU) |
