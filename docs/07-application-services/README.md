# Application Services in AWS

## Table of Contents

- [Amazon SQS](#amazon-sqs)
- [Amazon SNS](#amazon-sns)
- [Fan-Out Pattern: SQS + SNS](#fan-out-pattern-sqs--sns)
- [Amazon EventBridge](#amazon-eventbridge)
- [AWS Step Functions](#aws-step-functions)
- [Amazon API Gateway](#amazon-api-gateway)
- [AWS AppSync](#aws-appsync)
- [Amazon Kinesis](#amazon-kinesis)
- [Amazon MQ](#amazon-mq)
- [Amazon SES](#amazon-ses)
- [Exam Tips](#exam-tips)

---

## Amazon SQS

Simple Queue Service: fully managed and serverless message queuing service.

### SQS Standard vs FIFO

| Feature | Standard | FIFO |
|---|---|---|
| **Throughput** | Unlimited | 300 msg/s (without batching), 3000 msg/s (with batching) |
| **Order** | Best-effort (no guarantee) | Strictly ordered (FIFO) |
| **Delivery** | At-least-once (possible duplicates) | Exactly-once (deduplication) |
| **Queue name** | Any | Must end with `.fifo` |
| **Use case** | High throughput, order doesn't matter | Critical ordering, no duplicates |
| **Deduplication** | No | Yes (content-based or deduplication ID, 5 min window) |
| **Message Group ID** | Not applicable | Groups messages for ordering within the group |

### Key SQS Concepts

**Visibility Timeout:**
- Period during which a consumed message becomes **invisible** to other consumers.
- Default: **30 seconds**. Range: 0 seconds to 12 hours.
- If the consumer does not process and delete the message before the timeout, the message **returns to the queue**.
- Can be extended with the `ChangeMessageVisibility` API.

```
    Producer --> [SQS Queue] --> Consumer A receives message
                                  |
                                  |-- Visibility Timeout (30s default)
                                  |   The message is INVISIBLE to other consumers
                                  |
                                  |-- If Consumer A deletes the message -> OK
                                  +-- If it does NOT delete before timeout ->
                                      the message REAPPEARS in the queue
```

> **Key**: If messages are processed twice, the visibility timeout is probably too short. If messages are never reprocessed after failures, it is probably too long.

**Dead-Letter Queue (DLQ):**
- Queue where messages that repeatedly fail are sent.
- A **MaxReceiveCount** is configured: after N failed attempts, the message goes to the DLQ.
- Useful for debugging problematic messages.
- The DLQ must be of the **same type** as the source queue (Standard -> Standard, FIFO -> FIFO).
- **Redrive to source**: Allows resending messages from the DLQ to the original queue after fixing the problem.

**Delay Queues:**
- Delays delivery of new messages by up to X seconds.
- Default: 0 seconds. Maximum: **15 minutes**.
- Configured at queue level or per individual message (Standard only).

**Long Polling:**
- The consumer waits until messages are available (instead of empty polling).
- Reduces the number of empty API calls (saves costs).
- Wait time: 1 to **20 seconds**.
- Configured at queue level (`ReceiveMessageWaitTimeSeconds`) or per API call (`WaitTimeSeconds`).
- **Always preferable** to short polling.

### Other SQS Details

- **Message retention**: 4 days default, configurable from 1 minute to **14 days**.
- **Maximum message size**: **256 KB**. For larger messages, use **SQS Extended Client Library** (stores the payload in S3).
- **Encryption**: In transit (HTTPS) and at-rest (SSE-SQS by default, or SSE-KMS).
- **Access control**: IAM policies + SQS Resource Policies (for cross-account or allowing other services to send messages).
- **Auto Scaling**: SQS is frequently used with ASG. The `ApproximateNumberOfMessagesVisible` CloudWatch metric is used to scale consumers.

---

## Amazon SNS

Simple Notification Service: fully managed pub/sub messaging service.

### Key Concepts

- **Topic**: Communication channel to which publishers send messages.
- **Subscriptions**: Subscribers receive all messages published to the topic.
- Up to **12,500,000 subscriptions** per topic.
- Up to **100,000 topics** per account.

### Subscription Types

| Protocol | Destination |
|---|---|
| **SQS** | SQS queue |
| **Lambda** | Lambda function |
| **HTTP/HTTPS** | Web endpoint |
| **Email / Email-JSON** | Email |
| **SMS** | Text message |
| **Kinesis Data Firehose** | Delivery to S3, Redshift, etc. |
| **Platform Application** | Mobile push notifications (APNs, GCM/FCM) |

### SNS FIFO Topics

- Strict message ordering within a **Message Group ID**.
- Message deduplication.
- **Can only have SQS FIFO subscribers**.
- Throughput similar to SQS FIFO.

### Message Filtering

- Subscribers can define a **filter policy** (JSON) to receive only messages that meet certain criteria.
- Filtered by message attributes (not by the body).
- Without a filter policy, the subscriber receives **all** messages.

```json
{
  "store": ["example_corp"],
  "event": ["order_placed"],
  "customer_interests": ["rugby", "football"]
}
```

> **Key**: SNS message filtering is the way to avoid creating multiple topics. A single topic with different filters per subscriber.

---

## Fan-Out Pattern: SQS + SNS

One of the most important architecture patterns for the exam.

### Concept

A message published to an SNS topic is sent to multiple subscribed SQS queues, enabling parallel and independent processing.

```
                         +--------------+    +--------------+
                         |   SQS Queue  |---->| Consumer A   |
                    +--->|  (Service A) |    |  (Process)   |
                    |    +--------------+    +--------------+
+----------+   +---+----+
| Producer |-->|  SNS   |
|          |   | Topic  |
+----------+   +---+----+
                    |    +--------------+    +--------------+
                    +--->|   SQS Queue  |---->| Consumer B   |
                    |    |  (Service B) |    |  (Archive)   |
                    |    +--------------+    +--------------+
                    |    +--------------+    +--------------+
                    +--->|   SQS Queue  |---->| Consumer C   |
                         |  (Service C) |    |  (Notify)    |
                         +--------------+    +--------------+
```

### Fan-Out Benefits

- **Total decoupling**: Consumers are independent.
- **Parallel processing**: Each queue processes at its own pace.
- **No data loss**: SQS guarantees persistence.
- **Scalability**: New consumers can be added without modifying the producer.
- **Fault tolerance**: If a consumer fails, messages remain in its queue.

### Pattern Variants

**S3 Events -> SNS -> SQS Fan-Out:**

```
    S3 Event --> SNS Topic --> SQS Queue 1 (processing)
                           --> SQS Queue 2 (archiving)
                           --> Lambda (thumbnail)
```

> **Key**: S3 event notifications only allow **one rule** per event and prefix combination. For multiple destinations, use SNS fan-out.

**SNS FIFO + SQS FIFO Fan-Out:**
- For when you need strict ordering AND multiple consumers.
- Deduplication and ordering guaranteed across all subscribers.

---

## Amazon EventBridge

Serverless event bus service (formerly CloudWatch Events).

### Key Concepts

| Concept | Description |
|---|---|
| **Event Bus** | Channel that receives events. Default bus (AWS events), Custom bus, Partner bus (SaaS) |
| **Rules** | Filter events and route them to targets based on patterns or schedules |
| **Targets** | Event destinations (Lambda, SQS, SNS, Step Functions, API Gateway, etc.) |
| **Schema Registry** | Automatically detects and stores event structure |
| **Scheduler** | Schedule recurring or one-time invocations (cron, rate, one-time) |

### Event Buses

```
    +----------------------------------+
    |         EventBridge              |
    |                                  |
    |  +---------------+               |
    |  |  Default Bus  |<-- AWS Events (EC2, S3, etc.)
    |  +---------------+               |
    |                                  |
    |  +---------------+               |
    |  |  Custom Bus   |<-- Your applications
    |  +---------------+               |
    |                                  |
    |  +---------------+               |
    |  | Partner Bus   |<-- SaaS (Zendesk, Datadog, etc.)
    |  +---------------+               |
    |                                  |
    |  Rules --> Targets               |
    +----------------------------------+
```

### EventBridge vs SNS

| Feature | EventBridge | SNS |
|---|---|---|
| **Event sources** | AWS, SaaS, custom | Direct publishing |
| **Filtering** | Advanced content-based filtering (JSON) | Attribute-based filtering |
| **Targets** | 15+ native targets | SQS, Lambda, HTTP, Email, SMS |
| **Schema** | Schema Registry and Discovery | No |
| **Archive** | Archive and Replay events | No |
| **Throughput** | Lower (rate limits per region) | Higher |
| **Use case** | Complex event-driven architectures | Simple notifications, fan-out |

### EventBridge Scheduler

- **Schedule expressions**: `rate(1 hour)`, `cron(0 12 * * ? *)`.
- **One-time schedules**: Execute once at a specific date/time.
- Replacement for CloudWatch Events Scheduled Rules.
- Supports time zones.

> **Key**: EventBridge is the evolution of CloudWatch Events with additional capabilities. For new event-driven architectures, AWS recommends EventBridge.

---

## AWS Step Functions

Serverless orchestration service for coordinating multiple AWS services in visual workflows.

### Workflow Types

| Type | Max Duration | Execution | Price | Use Case |
|---|---|---|---|---|
| **Standard** | Up to 1 year | Exactly-once | Per state transition | Long-running flows, complex orchestration |
| **Express** | Up to 5 minutes | At-least-once (async) / At-most-once (sync) | Per execution and duration | High volume, event processing, ETL |

### ASL (Amazon States Language)

Flows are defined in JSON/YAML using ASL. Available states:

| State | Description |
|---|---|
| **Task** | Executes work (Lambda, ECS, DynamoDB, etc.) |
| **Choice** | Conditional branching (if/else) |
| **Parallel** | Executes branches in parallel |
| **Map** | Iterates over a collection (like a for-each) |
| **Wait** | Waits a fixed time or until a date |
| **Pass** | Passes input to output (transformation, debugging) |
| **Succeed** | Terminates successfully |
| **Fail** | Terminates with error |

### Error Handling

- **Retry**: Retry a failed task with exponential backoff.
  - `ErrorEquals`: List of errors to handle.
  - `IntervalSeconds`: Time between retries.
  - `MaxAttempts`: Maximum number of retries.
  - `BackoffRate`: Interval multiplier.
- **Catch**: Catch errors and redirect to another state (fallback).
  - `ErrorEquals`: List of errors to catch.
  - `Next`: Fallback state.

**Predefined error types:**
- `States.ALL`: All errors.
- `States.Timeout`: Task timeout.
- `States.TaskFailed`: Task execution failure.
- `States.Permissions`: Insufficient permissions.

> **Key**: Step Functions is ideal for orchestrating complex workflows with error handling, retries and wait states. Preferable to coordinating Lambda with Lambda.

---

## Amazon API Gateway

Fully managed service for creating, publishing, maintaining and securing APIs at any scale.

### API Types

| Type | Protocol | Features | Price | Use Case |
|---|---|---|---|---|
| **REST API** | HTTPS | More features (caching, usage plans, API keys, request validation, WAF) | Higher | APIs with advanced requirements |
| **HTTP API** | HTTPS | Faster, cheaper, fewer features | ~70% cheaper | Simple APIs, proxy to Lambda/HTTP |
| **WebSocket API** | WSS | Persistent bidirectional connections | Per message and connection | Chat, gaming, real-time streaming |

### Stages and Deployment

- **Stage**: Named environment (dev, staging, prod).
- **Stage variables**: Environment variables per stage (e.g., point to different Lambdas).
- **Canary deployment**: Direct a percentage of traffic to a new version of the stage.

### Throttling

- **Account-level**: 10,000 requests/s per region (soft limit, increasable).
- **Stage-level and Method-level**: Individually configurable.
- Returns error **429 Too Many Requests** when exceeded.
- Uses **token bucket algorithm**.

### Caching

- Only available in **REST API**.
- Size: 0.5 GB to 237 GB.
- TTL: default 300 seconds (5 min). Range: 0 to 3600 seconds.
- Configured per stage.
- Cache invalidation: Header `Cache-Control: max-age=0` (requires permissions).

### Usage Plans and API Keys

- **Usage Plan**: Defines who can access which stages/methods and with what throttling/quota.
- **API Keys**: Identifiers for clients (NOT a security mechanism on their own).
- Combined to control access and rate limiting per client.

### Authorizers

| Type | Description | Use Case |
|---|---|---|
| **IAM Authorizer** | Uses SigV4 (AWS signature). Ideal for internal AWS services. | Service-to-service, IAM users |
| **Lambda Authorizer** (custom) | Lambda that validates a token and returns an IAM policy. | OAuth, SAML tokens, custom logic |
| **Cognito User Pool** | Validates JWT tokens from Cognito directly. | Apps with Cognito as identity provider |

```
    Client --> API Gateway --> Lambda Authorizer --> Valid token?
                                                        |
                                    +-------------------+
                                    |                   |
                                   Yes                  No
                                    |                   |
                              IAM Policy           403 Forbidden
                              (cacheable)
                                    |
                              API Gateway
                              executes the
                              backend
```

### Backend Integration

| Integration Type | Description |
|---|---|
| **Lambda Proxy** | API Gateway passes the complete request to Lambda. Lambda's response is returned directly. Simplest. |
| **Lambda Non-Proxy** | API Gateway transforms the request before sending to Lambda. Mapping templates (VTL). |
| **HTTP Proxy** | Direct proxy to an HTTP endpoint. |
| **HTTP Non-Proxy** | With mapping templates. |
| **AWS Service** | Direct integration with AWS services (SQS, Step Functions, etc.) without Lambda. |

> **Key**: REST API has more features (caching, WAF, API keys). HTTP API is cheaper and simpler. If the question doesn't require advanced features, HTTP API is the answer.

---

## AWS AppSync

Managed service that facilitates the development of **GraphQL** and Pub/Sub APIs.

### Main Features

- **GraphQL**: A single endpoint for multiple data sources.
- **Resolvers**: Connect schema fields to data sources (DynamoDB, Lambda, RDS, HTTP, OpenSearch, etc.).
- **Real-time subscriptions**: Managed WebSockets for real-time updates.
- **Offline sync**: Clients can work offline and sync when reconnecting (Amplify DataStore).
- **Caching**: Resolver-level cache.
- **Security**: API Key, Cognito, IAM, OIDC.

### When to Use AppSync vs API Gateway

| Scenario | Service |
|---|---|
| Traditional REST/HTTP API | API Gateway |
| GraphQL API | AppSync |
| Real-time data with simple WebSockets | API Gateway WebSocket |
| Real-time data with GraphQL subscriptions | AppSync |
| Multiple data sources in a single query | AppSync |
| Offline sync for mobile apps | AppSync + Amplify |

> **Key**: If the question mentions "GraphQL", "real-time with multiple data sources", or "offline synchronization", the answer is **AppSync**.

---

## Amazon Kinesis

Family of services for **real-time streaming** data processing.

### Kinesis Service Comparison

| Service | Description | Latency | Retention | Consumers | Use Case |
|---|---|---|---|---|---|
| **Data Streams** | Stream data ingestion and storage | ~200 ms (real-time) | 1-365 days | Custom (SDK, KCL, Lambda) | Real-time ingestion, custom processing |
| **Data Firehose** | Data delivery to destinations (near real-time) | ~60 seconds (buffer) | No retention (direct delivery) | S3, Redshift, OpenSearch, Splunk, HTTP | Automated ETL and delivery |
| **Data Analytics** | SQL/Apache Flink analysis on streams | Seconds | N/A (processing) | Output to Streams, Firehose, Lambda | Real-time analysis with SQL |
| **Video Streams** | Video ingestion for processing | Real-time | Configurable | Custom, Rekognition | Video analytics, ML on video |

### Kinesis Data Streams - Details

**Architecture:**

```
    Producers            Shards              Consumers
    +------+         +---------+         +--------------+
    | App  |-------->| Shard 1 |-------->| Lambda       |
    | SDK  |         +---------+         +--------------+
    | Agent|-------->| Shard 2 |-------->| KCL App      |
    | IoT  |         +---------+         +--------------+
    |      |-------->| Shard N |-------->| Firehose     |
    +------+         +---------+         +--------------+
```

- **Shard**: Unit of capacity.
  - **Ingestion**: 1 MB/s or 1000 records/s per shard.
  - **Consumption**: 2 MB/s per shard (shared) or 2 MB/s per consumer (enhanced fan-out).
- **Partition Key**: Determines which shard each record goes to. Key for uniform distribution.
- **Capacity modes**:
  - **Provisioned**: Shards are chosen manually.
  - **On-demand**: Scales automatically (up to 200 MB/s ingestion by default).

**Enhanced Fan-Out:**
- Each registered consumer gets **2 MB/s dedicated** per shard (push model via HTTP/2).
- Without enhanced fan-out: all consumers share 2 MB/s per shard (pull model).
- Use when there are multiple consumers or latency < 70 ms is needed.

### Kinesis Data Firehose - Details

- **Fully managed** service, no administration required.
- **Near real-time**: Minimum buffer of 60 seconds or 1 MB.
- Data transformation with Lambda (optional).
- **Destinations**: S3, Redshift (via S3 COPY), OpenSearch, Splunk, HTTP endpoint, third-party partners.
- Supports compression (GZIP, ZIP, Snappy) and encryption.
- **No data retention**: deliver and forget. Failed data goes to an error S3 bucket.

### Kinesis vs SQS - When to Use Each

| Feature | Kinesis Data Streams | SQS |
|---|---|---|
| **Model** | Streaming (multiple consumers) | Message queue (one consumer per message) |
| **Retention** | 1-365 days | Up to 14 days |
| **Order** | Per shard (partition key) | FIFO (with FIFO queue) or unordered |
| **Throughput** | Based on shards | Unlimited (Standard) |
| **Consumers** | Multiple in parallel (fan-out) | One consumer per message |
| **Replay** | Yes (re-read data) | No (message deleted after processing) |
| **Use case** | Real-time analytics, logs, IoT | Decoupling, asynchronous processing |

---

## Amazon MQ

Managed message broker service for **Apache ActiveMQ** and **RabbitMQ**.

### When to Use Amazon MQ vs SQS/SNS

| Scenario | Recommended Service |
|---|---|
| New cloud-native application | SQS/SNS (serverless, scalable) |
| Migration of on-premises applications using standard protocols (AMQP, MQTT, STOMP, OpenWire, WSS) | Amazon MQ |
| JMS (Java Message Service) compatibility needed | Amazon MQ |
| Traditional broker features needed (queue + topic in a single service) | Amazon MQ |

### Amazon MQ Features

- **Not serverless**: Runs on dedicated servers.
- **High availability**: Multi-AZ with automatic failover (Active/Standby).
- Natively supports **queues and topics** (like a traditional broker).
- Storage on EFS (shared between brokers for HA).

```
    AWS Region
    +------------------------------------+
    |   AZ-a              AZ-b          |
    |  +----------+    +----------+     |
    |  | ActiveMQ |    | ActiveMQ |     |
    |  |  Active  |<-->|  Standby |     |
    |  +----+-----+    +----+-----+     |
    |       |               |           |
    |       +-------+-------+           |
    |           +---v---+               |
    |           |  EFS  |               |
    |           |(shared)|              |
    |           +-------+               |
    +------------------------------------+
```

> **Key for the exam**: If the question mentions migration of applications with traditional messaging protocols (AMQP, MQTT, STOMP, JMS), the answer is **Amazon MQ**, not SQS/SNS.

---

## Amazon SES

Simple Email Service: service for sending and receiving email at scale.

### Main Features

- Sending transactional, marketing, and notification emails.
- Supports **SMTP** and direct API.
- Reputation management (bounce handling, complaint feedback).
- **Dedicated IPs** for better reputation control.
- Integration with S3 (store received emails), Lambda (processing), SNS (notifications).
- **Templates** for email personalization.
- **Configuration sets**: Event tracking (delivery, open, click, bounce).

### SES vs SNS (Email)

| Feature | SES | SNS (Email) |
|---|---|---|
| **Purpose** | Professional email at scale | Simple notifications |
| **Format** | Custom HTML/Text | Plain text only |
| **Tracking** | Open, click, bounce, delivery | No |
| **Reception** | Yes (can receive emails) | No |
| **Use case** | Marketing, transactional | System alerts |

> **Key**: For transactional or marketing emails -> SES. For simple email alerts -> SNS.

---

## Exam Tips

### SQS

1. **"Decouple components"** -> SQS.
2. **"Strict ordering and no duplicates"** -> SQS FIFO.
3. **"Messages processed twice"** -> Increase visibility timeout.
4. **"Messages that repeatedly fail"** -> Dead-Letter Queue (DLQ).
5. **"Delay message processing"** -> Delay Queue.
6. **"Reduce empty API calls"** -> Long Polling.
7. **"Message larger than 256 KB"** -> SQS Extended Client Library (payload in S3).
8. **"Scale consumers based on the queue"** -> CloudWatch + ASG with `ApproximateNumberOfMessagesVisible` metric.

### SNS

9. **"Send a message to multiple destinations"** -> SNS (pub/sub).
10. **"Filter messages by subscriber"** -> SNS Message Filtering.
11. **"Notify multiple SQS queues from an event"** -> Fan-out (SNS -> SQS).
12. **"Fan-out with ordering"** -> SNS FIFO + SQS FIFO.

### EventBridge

13. **"React to AWS service events"** -> EventBridge (default event bus).
14. **"Integrate with SaaS (Zendesk, Datadog)"** -> EventBridge (partner event bus).
15. **"Schedule tasks (cron in the cloud)"** -> EventBridge Scheduler.
16. **"Archive and replay events"** -> EventBridge Archive + Replay.
17. **"Event bus vs SNS"** -> EventBridge for complex event-driven; SNS for simple fan-out.

### Step Functions

18. **"Orchestrate multiple Lambdas"** -> Step Functions.
19. **"Long-running workflow (hours/days)"** -> Step Functions Standard.
20. **"High-volume workflow (< 5 min)"** -> Step Functions Express.
21. **"Error handling with automatic retries"** -> Step Functions Retry/Catch.
22. **"Human approval process"** -> Step Functions with Wait + callback.

### API Gateway

23. **"REST API with caching and throttling"** -> API Gateway REST API.
24. **"Simple and cheap API proxy"** -> API Gateway HTTP API.
25. **"Real-time chat or streaming"** -> API Gateway WebSocket.
26. **"Authentication with custom tokens"** -> Lambda Authorizer.
27. **"Authentication with Cognito"** -> Cognito User Pool Authorizer.
28. **"Call AWS service without Lambda"** -> API Gateway AWS Service integration.

### AppSync

29. **"GraphQL"** -> AppSync.
30. **"Offline synchronization for mobile"** -> AppSync + Amplify.
31. **"Combine data from multiple sources in one query"** -> AppSync (resolvers).

### Kinesis

32. **"Real-time streaming"** -> Kinesis Data Streams.
33. **"Data delivery to S3/Redshift/OpenSearch"** -> Kinesis Data Firehose.
34. **"SQL analysis on streaming"** -> Kinesis Data Analytics.
35. **"Multiple consumers of the same stream"** -> Kinesis Data Streams with Enhanced Fan-Out.
36. **"Near real-time (60 sec buffer)"** -> Firehose. **"Real-time (200 ms)"** -> Data Streams.

### Amazon MQ

37. **"Migration of traditional broker (ActiveMQ, RabbitMQ)"** -> Amazon MQ.
38. **"AMQP, MQTT, STOMP protocols"** -> Amazon MQ.
39. **"New cloud-native messaging application"** -> SQS/SNS (NOT Amazon MQ).
