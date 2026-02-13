# Arbol de Decisión: Selección de Servicio de Mensajería

## Pregunta Principal: ¿Qué necesitas comunicar y cómo?

```
¿Qué tipo de comunicación necesitas?
│
├── NOTIFICACIONES (Pub/Sub - enviar a múltiples suscriptores)
│   │
│   └──→ Amazon SNS (Simple Notification Service)
│        │
│        ├── Suscriptores posibles:
│        │   ├── SQS queues (fan-out pattern)
│        │   ├── Lambda functions
│        │   ├── HTTP/HTTPS endpoints
│        │   ├── Email / Email-JSON
│        │   ├── SMS
│        │   └── Mobile push (APNs, FCM)
│        │
│        ├── Características:
│        │   ├── Push-based (SNS envía a suscriptores)
│        │   ├── Hasta 12.5M suscriptores por topic
│        │   ├── Hasta 100,000 topics
│        │   ├── Message filtering por atributos
│        │   └── No retiene mensajes (si no hay suscriptor, se pierde)
│        │
│        └── Precio: Por publicación + entrega
│
├── COLA DE MENSAJES (desacoplar productores y consumidores)
│   │
│   └──→ Amazon SQS (Simple Queue Service)
│        │
│        ├── ¿Qué tipo de cola?
│        │   │
│        │   ├── ¿Necesitas orden EXACTO y deduplicación?
│        │   │   └──→ SQS FIFO
│        │   │       ├── Orden garantizado (FIFO)
│        │   │       ├── Exactly-once processing
│        │   │       ├── Hasta 300 msg/s (3,000 con batching)
│        │   │       └── Ideal: transacciones financieras, flujos ordenados
│        │   │
│        │   └── ¿Máximo throughput, sin importar orden estricto?
│        │       └──→ SQS Standard
│        │           ├── Throughput ilimitado
│        │           ├── At-least-once delivery (posibles duplicados)
│        │           ├── Best-effort ordering
│        │           └── Ideal: desacoplamiento general, procesamiento async
│        │
│        ├── Características comunes:
│        │   ├── Pull-based (consumidores piden mensajes)
│        │   ├── Retención: 1 min a 14 días (default 4 días)
│        │   ├── Visibility timeout: evitar procesamiento duplicado
│        │   ├── Dead Letter Queue (DLQ): mensajes fallidos
│        │   ├── Long polling: reduce costos (espera hasta 20s)
│        │   └── Tamaño máximo mensaje: 256 KB
│        │
│        └── Precio: Por request (muy económico)
│
├── ENRUTAMIENTO DE EVENTOS (reglas, filtros, múltiples destinos)
│   │
│   └──→ Amazon EventBridge
│        │
│        ├── Características:
│        │   ├── Event bus centralizado
│        │   ├── Reglas con patrones de filtrado
│        │   ├── Schema registry / discovery
│        │   ├── Eventos de servicios AWS nativos
│        │   ├── Eventos de SaaS (Zendesk, Datadog, Shopify, etc.)
│        │   ├── Archive & replay de eventos
│        │   ├── Eventos programados (cron/rate)
│        │   └── Pipes: point-to-point con transformación
│        │
│        ├── Destinos: Lambda, SQS, SNS, Step Functions, API Gateway,
│        │   Kinesis, ECS tasks, CodePipeline, y más
│        │
│        └── vs CloudWatch Events: EventBridge es la evolución
│            (misma API subyacente, más features)
│
├── ORQUESTACIÓN / WORKFLOWS (pasos, decisiones, reintentos)
│   │
│   └──→ AWS Step Functions
│        │
│        ├── Tipos:
│        │   ├── Standard: hasta 1 año de duración, exactly-once
│        │   └── Express: hasta 5 minutos, at-least-once, alto throughput
│        │
│        ├── Características:
│        │   ├── Máquinas de estado visuales (ASL - JSON)
│        │   ├── Manejo de errores y reintentos integrado
│        │   ├── Parallel execution
│        │   ├── Wait states
│        │   ├── Map state (procesamiento iterativo)
│        │   ├── Choice state (decisiones condicionales)
│        │   └── Integración directa con 200+ servicios AWS
│        │
│        └── Ideal para: saga patterns, ETL, approval workflows,
│            orquestación de microservicios
│
├── STREAMING EN TIEMPO REAL (datos continuos, alta velocidad)
│   │
│   ├── ¿Necesitas procesamiento custom de cada registro?
│   │   │
│   │   └──→ Amazon Kinesis Data Streams
│   │        ├── Retención: 24 horas (default) hasta 365 días
│   │        ├── Múltiples consumidores simultáneos
│   │        ├── Shards para escalar (provisioned o on-demand)
│   │        ├── Ordering por partition key dentro del shard
│   │        ├── Consumidores: Lambda, KCL apps, Spark, Flink
│   │        └── Ideal: real-time analytics, logs, clickstream
│   │
│   └── ¿Solo necesitas entregar datos a un destino (S3, Redshift, etc.)?
│       │
│       └──→ Amazon Kinesis Data Firehose
│            ├── Near real-time (buffer de 60s mínimo)
│            ├── Completamente serverless (sin shards)
│            ├── Auto-scaling
│            ├── Transformación con Lambda opcional
│            ├── Destinos: S3, Redshift, OpenSearch, Splunk, HTTP
│            ├── Compresión y cifrado automático
│            └── Ideal: ingest a data lake, log delivery
│
├── PROTOCOLOS LEGACY (JMS, AMQP, MQTT, STOMP, OpenWire)
│   │
│   └──→ Amazon MQ
│        ├── Motores: ActiveMQ o RabbitMQ gestionado
│        ├── Compatibilidad con aplicaciones existentes
│        ├── Migración sin cambiar código de la app
│        ├── Multi-AZ para alta disponibilidad
│        └── Ideal: migrar message broker on-prem a AWS sin refactorizar
│
└── COMUNICACIÓN API (request/response, sincrónica)
    │
    ├── REST APIs ──→ API Gateway (REST)
    │   ├── Throttling, caching, autorización
    │   └── Lambda o HTTP backend
    │
    ├── HTTP APIs (más simple) ──→ API Gateway (HTTP)
    │   └── Menor latencia y costo que REST API
    │
    ├── WebSocket ──→ API Gateway (WebSocket)
    │   └── Chat, notificaciones en tiempo real
    │
    └── GraphQL ──→ AWS AppSync
        └── Real-time subscriptions, offline sync
```

---

## Patrón Fan-Out: SNS + SQS

```
                              ┌──── SQS Queue A ──→ Consumer A (procesamiento de pedidos)
                              │
Producer ──→ SNS Topic ──────├──── SQS Queue B ──→ Consumer B (envío de emails)
                              │
                              ├──── SQS Queue C ──→ Consumer C (analytics)
                              │
                              └──── Lambda ──→ Procesamiento inmediato
```

**Ventajas del patrón fan-out:**
- Cada consumidor procesa independientemente
- Si un consumidor falla, los demás no se afectan
- Cada SQS tiene su propia DLQ para reintentos
- SNS garantiza la entrega a las colas suscritas
- Desacopla completamente productores de consumidores

> **Clave examen:** "Enviar el mismo mensaje a múltiples servicios para procesamiento independiente" = **SNS + SQS fan-out**.

---

## Tabla Comparativa Rápida

| Servicio | Modelo | Retención | Orden | Throughput | Caso principal |
|----------|--------|-----------|-------|------------|---------------|
| **SNS** | Pub/Sub (push) | No retiene | No | Alto | Notificaciones, fan-out |
| **SQS Standard** | Queue (pull) | Hasta 14 días | Best-effort | Ilimitado | Desacoplar servicios |
| **SQS FIFO** | Queue (pull) | Hasta 14 días | **FIFO** | 300-3,000/s | Orden estricto |
| **EventBridge** | Event bus (push) | Archive opcional | No | Alto | Routing con reglas |
| **Step Functions** | Workflow | Estado interno | Secuencial | Medio | Orquestación |
| **Kinesis Streams** | Streaming (pull) | 24h - 365 días | **Por shard** | Muy alto | Real-time analytics |
| **Kinesis Firehose** | Delivery (push) | Buffer solo | N/A | Auto-scale | Entrega a S3/Redshift |
| **Amazon MQ** | Broker (push/pull) | Configurable | Sí | Medio | Protocolos legacy |

---

## Tabla de Decisión por Caso de Uso

| Necesitas... | Usa... |
|-------------|--------|
| Enviar email/SMS/push a usuarios | **SNS** |
| Desacoplar microservicios | **SQS** |
| Procesamiento en orden exacto | **SQS FIFO** |
| Un mensaje → múltiples procesadores | **SNS → SQS** (fan-out) |
| Reaccionar a eventos AWS | **EventBridge** |
| Eventos de SaaS externos | **EventBridge** |
| Cron/scheduled jobs serverless | **EventBridge** (regla cron) |
| Workflow con pasos y decisiones | **Step Functions** |
| Saga pattern / compensaciones | **Step Functions** |
| Real-time streaming de datos | **Kinesis Data Streams** |
| Cargar logs/datos a S3 continuamente | **Kinesis Firehose** |
| Migrar ActiveMQ/RabbitMQ a AWS | **Amazon MQ** |
| Comunicación MQTT (IoT) | **IoT Core** (o Amazon MQ) |
| Request/response HTTP API | **API Gateway** |
| Real-time bidireccional | **API Gateway WebSocket** o **AppSync** |

---

## Kinesis Family - Resumen

```
Kinesis Family
│
├── Kinesis Data Streams
│   └── Ingest y procesamiento real-time (shards, KCL, Lambda)
│
├── Kinesis Data Firehose
│   └── Delivery near real-time a S3, Redshift, OpenSearch, Splunk
│
├── Kinesis Data Analytics (ahora Managed Apache Flink)
│   └── SQL/Flink sobre streams en tiempo real
│
└── Kinesis Video Streams
    └── Ingest y procesamiento de video en tiempo real
```

---

## Keywords del Examen → Servicio

```
"Decouple services / message queue"           → SQS
"Guaranteed order + no duplicates"            → SQS FIFO
"Send notifications to multiple targets"      → SNS
"Fan-out pattern"                             → SNS + SQS
"Event-driven routing with rules"             → EventBridge
"Scheduled event / cron job"                  → EventBridge (schedule rule)
"Orchestrate Lambda functions"                → Step Functions
"Saga pattern / compensating transactions"    → Step Functions
"Real-time data streaming"                    → Kinesis Data Streams
"Load streaming data to S3"                   → Kinesis Firehose
"SQL on streaming data"                       → Managed Apache Flink
"Migrate from ActiveMQ / RabbitMQ"            → Amazon MQ
"MQTT / AMQP / JMS protocol"                 → Amazon MQ
"Async processing with retry"                 → SQS + Dead Letter Queue
"Process each message exactly once"           → SQS FIFO
"Video streaming ingestion"                   → Kinesis Video Streams
```
