# Decision Tree: Messaging Service Selection

## Main Question: What do you need to communicate and how?

```
What type of communication do you need?
│
├── NOTIFICATIONS (Pub/Sub - send to multiple subscribers)
│   │
│   └──→ Amazon SNS (Simple Notification Service)
│        │
│        ├── Possible subscribers:
│        │   ├── SQS queues (fan-out pattern)
│        │   ├── Lambda functions
│        │   ├── HTTP/HTTPS endpoints
│        │   ├── Email / Email-JSON
│        │   ├── SMS
│        │   └── Mobile push (APNs, FCM)
│        │
│        ├── Features:
│        │   ├── Push-based (SNS sends to subscribers)
│        │   ├── Up to 12.5M subscribers per topic
│        │   ├── Up to 100,000 topics
│        │   ├── Message filtering by attributes
│        │   └── Does not retain messages (if no subscriber, message is lost)
│        │
│        └── Pricing: Per publish + delivery
│
├── MESSAGE QUEUE (decouple producers and consumers)
│   │
│   └──→ Amazon SQS (Simple Queue Service)
│        │
│        ├── What type of queue?
│        │   │
│        │   ├── Do you need EXACT order and deduplication?
│        │   │   └──→ SQS FIFO
│        │   │       ├── Guaranteed order (FIFO)
│        │   │       ├── Exactly-once processing
│        │   │       ├── Up to 300 msg/s (3,000 with batching)
│        │   │       └── Ideal: financial transactions, ordered workflows
│        │   │
│        │   └── Maximum throughput, strict order not required?
│        │       └──→ SQS Standard
│        │           ├── Unlimited throughput
│        │           ├── At-least-once delivery (possible duplicates)
│        │           ├── Best-effort ordering
│        │           └── Ideal: general decoupling, async processing
│        │
│        ├── Common features:
│        │   ├── Pull-based (consumers request messages)
│        │   ├── Retention: 1 min to 14 days (default 4 days)
│        │   ├── Visibility timeout: prevent duplicate processing
│        │   ├── Dead Letter Queue (DLQ): failed messages
│        │   ├── Long polling: reduces costs (waits up to 20s)
│        │   └── Maximum message size: 256 KB
│        │
│        └── Pricing: Per request (very economical)
│
├── EVENT ROUTING (rules, filters, multiple destinations)
│   │
│   └──→ Amazon EventBridge
│        │
│        ├── Features:
│        │   ├── Centralized event bus
│        │   ├── Rules with filtering patterns
│        │   ├── Schema registry / discovery
│        │   ├── Native AWS service events
│        │   ├── SaaS events (Zendesk, Datadog, Shopify, etc.)
│        │   ├── Archive & replay of events
│        │   ├── Scheduled events (cron/rate)
│        │   └── Pipes: point-to-point with transformation
│        │
│        ├── Destinations: Lambda, SQS, SNS, Step Functions, API Gateway,
│        │   Kinesis, ECS tasks, CodePipeline, and more
│        │
│        └── vs CloudWatch Events: EventBridge is the evolution
│            (same underlying API, more features)
│
├── ORCHESTRATION / WORKFLOWS (steps, decisions, retries)
│   │
│   └──→ AWS Step Functions
│        │
│        ├── Types:
│        │   ├── Standard: up to 1 year duration, exactly-once
│        │   └── Express: up to 5 minutes, at-least-once, high throughput
│        │
│        ├── Features:
│        │   ├── Visual state machines (ASL - JSON)
│        │   ├── Built-in error handling and retries
│        │   ├── Parallel execution
│        │   ├── Wait states
│        │   ├── Map state (iterative processing)
│        │   ├── Choice state (conditional decisions)
│        │   └── Direct integration with 200+ AWS services
│        │
│        └── Ideal for: saga patterns, ETL, approval workflows,
│            microservice orchestration
│
├── REAL-TIME STREAMING (continuous data, high velocity)
│   │
│   ├── Do you need custom processing of each record?
│   │   │
│   │   └──→ Amazon Kinesis Data Streams
│   │        ├── Retention: 24 hours (default) up to 365 days
│   │        ├── Multiple simultaneous consumers
│   │        ├── Shards for scaling (provisioned or on-demand)
│   │        ├── Ordering by partition key within shard
│   │        ├── Consumers: Lambda, KCL apps, Spark, Flink
│   │        └── Ideal: real-time analytics, logs, clickstream
│   │
│   └── Do you just need to deliver data to a destination (S3, Redshift, etc.)?
│       │
│       └──→ Amazon Kinesis Data Firehose
│            ├── Near real-time (minimum 60s buffer)
│            ├── Fully serverless (no shards)
│            ├── Auto-scaling
│            ├── Optional transformation with Lambda
│            ├── Destinations: S3, Redshift, OpenSearch, Splunk, HTTP
│            ├── Automatic compression and encryption
│            └── Ideal: data lake ingest, log delivery
│
├── LEGACY PROTOCOLS (JMS, AMQP, MQTT, STOMP, OpenWire)
│   │
│   └──→ Amazon MQ
│        ├── Engines: Managed ActiveMQ or RabbitMQ
│        ├── Compatibility with existing applications
│        ├── Migration without changing app code
│        ├── Multi-AZ for high availability
│        └── Ideal: migrate on-prem message broker to AWS without refactoring
│
└── API COMMUNICATION (request/response, synchronous)
    │
    ├── REST APIs ──→ API Gateway (REST)
    │   ├── Throttling, caching, authorization
    │   └── Lambda or HTTP backend
    │
    ├── HTTP APIs (simpler) ──→ API Gateway (HTTP)
    │   └── Lower latency and cost than REST API
    │
    ├── WebSocket ──→ API Gateway (WebSocket)
    │   └── Chat, real-time notifications
    │
    └── GraphQL ──→ AWS AppSync
        └── Real-time subscriptions, offline sync
```

---

## Fan-Out Pattern: SNS + SQS

```
                              ┌──── SQS Queue A ──→ Consumer A (order processing)
                              │
Producer ──→ SNS Topic ──────├──── SQS Queue B ──→ Consumer B (email sending)
                              │
                              ├──── SQS Queue C ──→ Consumer C (analytics)
                              │
                              └──── Lambda ──→ Immediate processing
```

**Fan-out pattern advantages:**
- Each consumer processes independently
- If one consumer fails, the others are not affected
- Each SQS has its own DLQ for retries
- SNS guarantees delivery to subscribed queues
- Completely decouples producers from consumers

> **Exam key:** "Send the same message to multiple services for independent processing" = **SNS + SQS fan-out**.

---

## Quick Comparison Table

| Service | Model | Retention | Order | Throughput | Main Use Case |
|---------|-------|-----------|-------|------------|---------------|
| **SNS** | Pub/Sub (push) | No retention | No | High | Notifications, fan-out |
| **SQS Standard** | Queue (pull) | Up to 14 days | Best-effort | Unlimited | Decouple services |
| **SQS FIFO** | Queue (pull) | Up to 14 days | **FIFO** | 300-3,000/s | Strict ordering |
| **EventBridge** | Event bus (push) | Optional archive | No | High | Routing with rules |
| **Step Functions** | Workflow | Internal state | Sequential | Medium | Orchestration |
| **Kinesis Streams** | Streaming (pull) | 24h - 365 days | **Per shard** | Very high | Real-time analytics |
| **Kinesis Firehose** | Delivery (push) | Buffer only | N/A | Auto-scale | Delivery to S3/Redshift |
| **Amazon MQ** | Broker (push/pull) | Configurable | Yes | Medium | Legacy protocols |

---

## Decision Table by Use Case

| You need... | Use... |
|-------------|--------|
| Send email/SMS/push to users | **SNS** |
| Decouple microservices | **SQS** |
| Processing in exact order | **SQS FIFO** |
| One message → multiple processors | **SNS → SQS** (fan-out) |
| React to AWS events | **EventBridge** |
| External SaaS events | **EventBridge** |
| Serverless cron/scheduled jobs | **EventBridge** (cron rule) |
| Workflow with steps and decisions | **Step Functions** |
| Saga pattern / compensations | **Step Functions** |
| Real-time data streaming | **Kinesis Data Streams** |
| Continuously load logs/data to S3 | **Kinesis Firehose** |
| Migrate ActiveMQ/RabbitMQ to AWS | **Amazon MQ** |
| MQTT communication (IoT) | **IoT Core** (or Amazon MQ) |
| Request/response HTTP API | **API Gateway** |
| Real-time bidirectional | **API Gateway WebSocket** or **AppSync** |

---

## Kinesis Family - Summary

```
Kinesis Family
│
├── Kinesis Data Streams
│   └── Real-time ingest and processing (shards, KCL, Lambda)
│
├── Kinesis Data Firehose
│   └── Near real-time delivery to S3, Redshift, OpenSearch, Splunk
│
├── Kinesis Data Analytics (now Managed Apache Flink)
│   └── SQL/Flink on real-time streams
│
└── Kinesis Video Streams
    └── Real-time video ingest and processing
```

---

## Exam Keywords → Service

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
