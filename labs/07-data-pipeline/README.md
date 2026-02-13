# Lab 07: Data Pipeline - Streaming y Batch

## Objetivo

Construir un pipeline de datos completo que procese datos tanto en streaming (tiempo real) como en batch, utilizando los servicios de analítica de AWS.

## Arquitectura

```
                                    ┌─────────────────┐
                                    │   Lambda         │
                                    │   (real-time     │
                                    │    processing)   │
                                    └────────▲─────────┘
                                             │
┌──────────┐    ┌─────────────────┐    ┌─────┴──────────┐    ┌─────────────────┐
│ Producers│───▶│ Kinesis Data    │───▶│ Kinesis Data   │───▶│ S3 Data Lake    │
│ (apps,   │    │ Streams         │    │ Firehose       │    │ (raw/processed) │
│ sensors) │    │ (1 shard)       │    │ (buffer 60s)   │    │                 │
└──────────┘    └─────────────────┘    └────────────────┘    └────────┬────────┘
                                                                      │
                                                              ┌───────▼────────┐
                                                              │ AWS Glue       │
                                                              │ Catalog        │
                                                              │ (schema)       │
                                                              └───────┬────────┘
                                                                      │
                                                              ┌───────▼────────┐
                                                              │ Amazon Athena  │
                                                              │ (SQL queries)  │
                                                              └────────────────┘
```

## Qué vas a aprender

- **Kinesis Data Streams**: ingesta de datos en streaming con shards y particiones
- **Kinesis Data Firehose**: entrega automática de datos a destinos (S3, Redshift, etc.)
- **Data Lake en S3**: almacenamiento centralizado de datos con lifecycle policies
- **AWS Glue Catalog**: catálogo de metadatos para definir esquemas de datos
- **Amazon Athena**: consultas SQL serverless sobre datos en S3
- **Lambda con Kinesis**: procesamiento en tiempo real de eventos del stream

## Componentes desplegados

| Recurso | Descripción | Coste estimado |
|---------|-------------|----------------|
| Kinesis Data Stream | 1 shard para ingesta | ~$0.36/día |
| Kinesis Firehose | Delivery stream a S3 | ~$0.01/GB |
| S3 Data Lake | Almacenamiento de datos | ~$0.023/GB/mes |
| Lambda | Procesador en tiempo real | Free tier |
| Glue Catalog | Catálogo de metadatos | Free (primeras 1M objects) |
| Athena | Consultas SQL | ~$5/TB escaneado |

## Coste estimado total

**~$1-2/día** (principalmente por el shard de Kinesis activo 24/7)

> **Nota**: El shard de Kinesis tiene un coste fijo por hora. Destruye la infraestructura cuando no la estés usando.

## Cómo desplegar

```bash
# Inicializar Terraform
terraform init

# Ver el plan de ejecución
terraform plan

# Desplegar la infraestructura
terraform apply

# Cuando termines, destruir todo
terraform destroy
```

## Cómo enviar datos de prueba al stream

Usa el script `test_producer.py` incluido para enviar eventos simulados de sensores:

```bash
# Instalar dependencias
pip install boto3

# Enviar 100 registros de prueba
python test_producer.py

# Enviar registros continuamente (1 por segundo)
python test_producer.py --continuous
```

El script envía registros JSON con este formato:

```json
{
  "sensor_id": "sensor-001",
  "temperature": 23.5,
  "humidity": 65.2,
  "timestamp": "2024-01-15T10:30:00Z",
  "location": "warehouse-A"
}
```

## Consultar datos con Athena

Una vez que Firehose haya entregado datos a S3 (espera al menos 60 segundos por el buffer):

```sql
-- Consultar los últimos registros
SELECT * FROM sensor_data
ORDER BY timestamp DESC
LIMIT 10;

-- Temperatura promedio por sensor
SELECT sensor_id, AVG(temperature) as avg_temp
FROM sensor_data
GROUP BY sensor_id;

-- Alertas de temperatura alta
SELECT sensor_id, temperature, timestamp
FROM sensor_data
WHERE temperature > 30.0
ORDER BY timestamp DESC;
```

## Conceptos clave para el examen

1. **Kinesis Data Streams vs Firehose**: Streams requiere consumidores personalizados, Firehose entrega automáticamente a destinos
2. **Shards**: cada shard soporta 1MB/s entrada y 2MB/s salida
3. **Partition Key**: determina a qué shard va cada registro
4. **Firehose Buffer**: configurable por tiempo (60-900s) y tamaño (1-128MB)
5. **Athena**: serverless, paga por datos escaneados, usa formato columnar (Parquet) para optimizar
6. **Glue Catalog**: compatible con Hive metastore, central para servicios de analítica

## Limpieza

```bash
terraform destroy
```

> **Importante**: Verifica que los buckets S3 estén vacíos. Terraform puede fallar al eliminar buckets con objetos.
