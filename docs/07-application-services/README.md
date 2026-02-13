# Servicios de Aplicación en AWS (Application Services)

## Índice

- [Amazon SQS](#amazon-sqs)
- [Amazon SNS](#amazon-sns)
- [Patrón Fan-Out: SQS + SNS](#patrón-fan-out-sqs--sns)
- [Amazon EventBridge](#amazon-eventbridge)
- [AWS Step Functions](#aws-step-functions)
- [Amazon API Gateway](#amazon-api-gateway)
- [AWS AppSync](#aws-appsync)
- [Amazon Kinesis](#amazon-kinesis)
- [Amazon MQ](#amazon-mq)
- [Amazon SES](#amazon-ses)
- [Tips para el examen](#tips-para-el-examen)

---

## Amazon SQS

Simple Queue Service: servicio de colas de mensajes totalmente gestionado y serverless.

### SQS Standard vs FIFO

| Característica | Standard | FIFO |
|---|---|---|
| **Throughput** | Ilimitado | 300 msg/s (sin batching), 3000 msg/s (con batching) |
| **Orden** | Best-effort (sin garantía) | Estrictamente ordenado (FIFO) |
| **Entrega** | At-least-once (posibles duplicados) | Exactly-once (deduplicación) |
| **Nombre de cola** | Cualquiera | Debe terminar en `.fifo` |
| **Caso de uso** | Alto throughput, orden no importa | Orden crítico, sin duplicados |
| **Deduplicación** | No | Sí (content-based o deduplication ID, ventana de 5 min) |
| **Message Group ID** | No aplica | Agrupa mensajes para orden dentro del grupo |

### Conceptos clave de SQS

**Visibility Timeout:**
- Período durante el cual un mensaje consumido se vuelve **invisible** para otros consumidores.
- Por defecto: **30 segundos**. Rango: 0 segundos a 12 horas.
- Si el consumidor no procesa y borra el mensaje antes del timeout, el mensaje **vuelve a la cola**.
- Se puede extender con la API `ChangeMessageVisibility`.

```
    Productor ──► [Cola SQS] ──► Consumidor A recibe mensaje
                                  │
                                  ├── Visibility Timeout (30s por defecto)
                                  │   El mensaje es INVISIBLE para otros consumidores
                                  │
                                  ├── Si Consumidor A borra el mensaje → OK
                                  └── Si NO lo borra antes del timeout →
                                      el mensaje REAPARECE en la cola
```

> **Clave**: Si los mensajes se procesan dos veces, probablemente el visibility timeout es demasiado corto. Si los mensajes nunca se reprocesan tras fallos, probablemente es demasiado largo.

**Dead-Letter Queue (DLQ):**
- Cola donde se envían los mensajes que fallan repetidamente.
- Se configura un **MaxReceiveCount**: tras N intentos fallidos, el mensaje va a la DLQ.
- Útil para debugging de mensajes problemáticos.
- La DLQ debe ser del **mismo tipo** que la cola origen (Standard → Standard, FIFO → FIFO).
- **Redrive to source**: Permite reenviar mensajes de la DLQ a la cola original tras corregir el problema.

**Delay Queues:**
- Retrasa la entrega de mensajes nuevos hasta X segundos.
- Por defecto: 0 segundos. Máximo: **15 minutos**.
- Se configura a nivel de cola o por mensaje individual (solo Standard).

**Long Polling:**
- El consumidor espera hasta que haya mensajes disponibles (en vez de hacer polling vacío).
- Reduce el número de llamadas API vacías (ahorra costes).
- Tiempo de espera: 1 a **20 segundos**.
- Se configura a nivel de cola (`ReceiveMessageWaitTimeSeconds`) o por llamada API (`WaitTimeSeconds`).
- **Siempre preferible** a short polling.

### Otros detalles de SQS

- **Retención de mensajes**: 4 días por defecto, configurable de 1 minuto a **14 días**.
- **Tamaño máximo de mensaje**: **256 KB**. Para mensajes más grandes, usar **SQS Extended Client Library** (almacena el payload en S3).
- **Cifrado**: En tránsito (HTTPS) y at-rest (SSE-SQS por defecto, o SSE-KMS).
- **Access control**: IAM policies + SQS Resource Policies (para cross-account o permitir que otros servicios envíen mensajes).
- **Auto Scaling**: SQS se usa frecuentemente con ASG. La métrica `ApproximateNumberOfMessagesVisible` en CloudWatch se usa para escalar consumidores.

---

## Amazon SNS

Simple Notification Service: servicio de mensajería pub/sub totalmente gestionado.

### Conceptos clave

- **Topic**: Canal de comunicación al que los publishers envían mensajes.
- **Subscriptions**: Los suscriptores reciben todos los mensajes publicados en el topic.
- Hasta **12,500,000 suscripciones** por topic.
- Hasta **100,000 topics** por cuenta.

### Tipos de suscripción

| Protocolo | Destino |
|---|---|
| **SQS** | Cola SQS |
| **Lambda** | Función Lambda |
| **HTTP/HTTPS** | Endpoint web |
| **Email / Email-JSON** | Correo electrónico |
| **SMS** | Mensaje de texto |
| **Kinesis Data Firehose** | Entrega a S3, Redshift, etc. |
| **Platform Application** | Push notifications móviles (APNs, GCM/FCM) |

### SNS FIFO Topics

- Orden estricto de mensajes dentro de un **Message Group ID**.
- Deduplicación de mensajes.
- **Solo puede tener suscriptores SQS FIFO**.
- Throughput similar a SQS FIFO.

### Message Filtering

- Los suscriptores pueden definir una **filter policy** (JSON) para recibir solo mensajes que cumplan ciertos criterios.
- Se filtra por atributos del mensaje (no por el cuerpo).
- Sin filter policy, el suscriptor recibe **todos** los mensajes.

```json
{
  "store": ["example_corp"],
  "event": ["order_placed"],
  "customer_interests": ["rugby", "football"]
}
```

> **Clave**: SNS message filtering es la forma de evitar crear múltiples topics. Un solo topic con filtros diferentes por suscriptor.

---

## Patrón Fan-Out: SQS + SNS

Uno de los patrones de arquitectura más importantes para el examen.

### Concepto

Un mensaje publicado en un SNS topic se envía a múltiples colas SQS suscritas, permitiendo procesamiento paralelo e independiente.

```
                         ┌──────────────┐    ┌──────────────┐
                         │   Cola SQS   │───►│ Consumidor A │
                    ┌───►│  (Servicio A)│    │  (Procesar)  │
                    │    └──────────────┘    └──────────────┘
┌──────────┐   ┌────┴───┐
│ Productor│──►│  SNS   │
│          │   │ Topic  │
└──────────┘   └────┬───┘
                    │    ┌──────────────┐    ┌──────────────┐
                    ├───►│   Cola SQS   │───►│ Consumidor B │
                    │    │  (Servicio B)│    │  (Archivar)  │
                    │    └──────────────┘    └──────────────┘
                    │    ┌──────────────┐    ┌──────────────┐
                    └───►│   Cola SQS   │───►│ Consumidor C │
                         │  (Servicio C)│    │  (Notificar) │
                         └──────────────┘    └──────────────┘
```

### Beneficios del Fan-Out

- **Desacoplamiento total**: Los consumidores son independientes.
- **Procesamiento paralelo**: Cada cola procesa a su ritmo.
- **Sin pérdida de datos**: SQS garantiza persistencia.
- **Escalabilidad**: Se pueden añadir nuevos consumidores sin modificar el productor.
- **Tolerancia a fallos**: Si un consumidor falla, los mensajes permanecen en su cola.

### Variantes del patrón

**S3 Events → SNS → SQS Fan-Out:**

```
    S3 Event ──► SNS Topic ──► SQS Cola 1 (procesamiento)
                           ──► SQS Cola 2 (archivado)
                           ──► Lambda (thumbnail)
```

> **Clave**: S3 event notifications solo permiten **una regla** por combinación de evento y prefijo. Para múltiples destinos, usar SNS fan-out.

**SNS FIFO + SQS FIFO Fan-Out:**
- Para cuando necesitas orden estricto Y múltiples consumidores.
- Deduplicación y ordenamiento garantizados en todos los suscriptores.

---

## Amazon EventBridge

Servicio de bus de eventos serverless (anteriormente CloudWatch Events).

### Conceptos clave

| Concepto | Descripción |
|---|---|
| **Event Bus** | Canal que recibe eventos. Default bus (eventos de AWS), Custom bus, Partner bus (SaaS) |
| **Rules** | Filtran eventos y los enrutan a targets basándose en patrones o schedules |
| **Targets** | Destinos de los eventos (Lambda, SQS, SNS, Step Functions, API Gateway, etc.) |
| **Schema Registry** | Detecta y almacena automáticamente la estructura de los eventos |
| **Scheduler** | Programar invocaciones recurrentes o únicas (cron, rate, one-time) |

### Event Buses

```
    ┌─────────────────────────────────┐
    │         EventBridge             │
    │                                 │
    │  ┌───────────────┐              │
    │  │  Default Bus  │◄── Eventos AWS (EC2, S3, etc.)
    │  └───────────────┘              │
    │                                 │
    │  ┌───────────────┐              │
    │  │  Custom Bus   │◄── Tus aplicaciones
    │  └───────────────┘              │
    │                                 │
    │  ┌───────────────┐              │
    │  │ Partner Bus   │◄── SaaS (Zendesk, Datadog, etc.)
    │  └───────────────┘              │
    │                                 │
    │  Rules ──► Targets              │
    └─────────────────────────────────┘
```

### EventBridge vs SNS

| Característica | EventBridge | SNS |
|---|---|---|
| **Fuentes de eventos** | AWS, SaaS, custom | Publicación directa |
| **Filtrado** | Content-based filtering avanzado (JSON) | Attribute-based filtering |
| **Targets** | 15+ targets nativos | SQS, Lambda, HTTP, Email, SMS |
| **Schema** | Schema Registry y Discovery | No |
| **Archivo** | Archive y Replay de eventos | No |
| **Throughput** | Menor (rate limits por región) | Mayor |
| **Caso de uso** | Arquitecturas event-driven complejas | Notificaciones simples, fan-out |

### EventBridge Scheduler

- **Schedule expressions**: `rate(1 hour)`, `cron(0 12 * * ? *)`.
- **One-time schedules**: Ejecutar una vez en una fecha/hora específica.
- Reemplazo de CloudWatch Events Scheduled Rules.
- Soporta time zones.

> **Clave**: EventBridge es la evolución de CloudWatch Events con capacidades adicionales. Para nuevas arquitecturas event-driven, AWS recomienda EventBridge.

---

## AWS Step Functions

Servicio de orquestación serverless para coordinar múltiples servicios AWS en flujos de trabajo visuales.

### Tipos de workflows

| Tipo | Duración máx. | Ejecución | Precio | Caso de uso |
|---|---|---|---|---|
| **Standard** | Hasta 1 año | Exactly-once | Por transición de estado | Flujos de larga duración, orquestación compleja |
| **Express** | Hasta 5 minutos | At-least-once (async) / At-most-once (sync) | Por ejecución y duración | Alto volumen, procesamiento de eventos, ETL |

### ASL (Amazon States Language)

Los flujos se definen en JSON/YAML usando ASL. Estados disponibles:

| Estado | Descripción |
|---|---|
| **Task** | Ejecuta trabajo (Lambda, ECS, DynamoDB, etc.) |
| **Choice** | Bifurcación condicional (if/else) |
| **Parallel** | Ejecuta ramas en paralelo |
| **Map** | Itera sobre una colección (como un for-each) |
| **Wait** | Espera un tiempo fijo o hasta una fecha |
| **Pass** | Pasa input al output (transformación, debugging) |
| **Succeed** | Termina exitosamente |
| **Fail** | Termina con error |

### Error Handling

- **Retry**: Reintentar una tarea fallida con backoff exponencial.
  - `ErrorEquals`: Lista de errores a manejar.
  - `IntervalSeconds`: Tiempo entre reintentos.
  - `MaxAttempts`: Número máximo de reintentos.
  - `BackoffRate`: Multiplicador del intervalo.
- **Catch**: Capturar errores y redirigir a otro estado (fallback).
  - `ErrorEquals`: Lista de errores a capturar.
  - `Next`: Estado de fallback.

**Tipos de error predefinidos:**
- `States.ALL`: Todos los errores.
- `States.Timeout`: Timeout de la tarea.
- `States.TaskFailed`: Fallo en la ejecución de la tarea.
- `States.Permissions`: Permisos insuficientes.

> **Clave**: Step Functions es ideal para orquestar workflows complejos con manejo de errores, reintentos y estados de espera. Preferible a coordinar Lambda con Lambda.

---

## Amazon API Gateway

Servicio totalmente gestionado para crear, publicar, mantener y proteger APIs a cualquier escala.

### Tipos de API

| Tipo | Protocolo | Características | Precio | Caso de uso |
|---|---|---|---|---|
| **REST API** | HTTPS | Más features (caching, usage plans, API keys, request validation, WAF) | Mayor | APIs con requisitos avanzados |
| **HTTP API** | HTTPS | Más rápido, más barato, menos features | ~70% más barato | APIs simples, proxy a Lambda/HTTP |
| **WebSocket API** | WSS | Conexiones bidireccionales persistentes | Por mensaje y conexión | Chat, gaming, streaming en tiempo real |

### Stages y Deployment

- **Stage**: Entorno nombrado (dev, staging, prod).
- **Stage variables**: Variables de entorno por stage (ej: apuntar a diferentes Lambdas).
- **Canary deployment**: Dirigir un porcentaje del tráfico a una nueva versión del stage.

### Throttling

- **Account-level**: 10,000 requests/s por región (límite suave, ampliable).
- **Stage-level y Method-level**: Configurables individualmente.
- Retorna error **429 Too Many Requests** cuando se excede.
- Usa **token bucket algorithm**.

### Caching

- Solo disponible en **REST API**.
- Tamaño: 0.5 GB a 237 GB.
- TTL: por defecto 300 segundos (5 min). Rango: 0 a 3600 segundos.
- Se configura por stage.
- Cache invalidation: Header `Cache-Control: max-age=0` (requiere permisos).

### Usage Plans y API Keys

- **Usage Plan**: Define quién puede acceder a qué stages/methods y con qué throttling/cuota.
- **API Keys**: Identificadores para clientes (NO son mecanismo de seguridad por sí solos).
- Se combinan para controlar acceso y rate limiting por cliente.

### Authorizers

| Tipo | Descripción | Caso de uso |
|---|---|---|
| **IAM Authorizer** | Usa SigV4 (firma AWS). Ideal para servicios internos AWS. | Service-to-service, usuarios IAM |
| **Lambda Authorizer** (custom) | Lambda que valida un token y retorna una IAM policy. | Tokens OAuth, SAML, custom logic |
| **Cognito User Pool** | Valida tokens JWT de Cognito directamente. | Apps con Cognito como proveedor de identidad |

```
    Cliente ──► API Gateway ──► Lambda Authorizer ──► ¿Token válido?
                                                        │
                                    ┌───────────────────┤
                                    │                   │
                                   Sí                  No
                                    │                   │
                              IAM Policy           403 Forbidden
                              (cacheable)
                                    │
                              API Gateway
                              ejecuta el
                              backend
```

### Integración con backends

| Tipo de integración | Descripción |
|---|---|
| **Lambda Proxy** | API Gateway pasa el request completo a Lambda. La respuesta de Lambda se devuelve directamente. Más simple. |
| **Lambda Non-Proxy** | API Gateway transforma el request antes de enviar a Lambda. Mapping templates (VTL). |
| **HTTP Proxy** | Proxy directo a un endpoint HTTP. |
| **HTTP Non-Proxy** | Con mapping templates. |
| **AWS Service** | Integración directa con servicios AWS (SQS, Step Functions, etc.) sin Lambda. |

> **Clave**: REST API tiene más features (caching, WAF, API keys). HTTP API es más barato y simple. Si la pregunta no requiere features avanzadas, HTTP API es la respuesta.

---

## AWS AppSync

Servicio gestionado que facilita el desarrollo de APIs **GraphQL** y Pub/Sub.

### Características principales

- **GraphQL**: Un solo endpoint para múltiples fuentes de datos.
- **Resolvers**: Conectan campos del schema con fuentes de datos (DynamoDB, Lambda, RDS, HTTP, OpenSearch, etc.).
- **Subscriptions en tiempo real**: WebSockets gestionados para actualizaciones en tiempo real.
- **Offline sync**: Los clientes pueden trabajar offline y sincronizar al reconectar (Amplify DataStore).
- **Caching**: Cache a nivel de resolver.
- **Seguridad**: API Key, Cognito, IAM, OIDC.

### Cuándo usar AppSync vs API Gateway

| Escenario | Servicio |
|---|---|
| API REST/HTTP tradicional | API Gateway |
| API GraphQL | AppSync |
| Datos en tiempo real con WebSockets sencillos | API Gateway WebSocket |
| Datos en tiempo real con GraphQL subscriptions | AppSync |
| Múltiples fuentes de datos en un solo query | AppSync |
| Sync offline para apps móviles | AppSync + Amplify |

> **Clave**: Si la pregunta menciona "GraphQL", "tiempo real con múltiples fuentes de datos", o "sincronización offline", la respuesta es **AppSync**.

---

## Amazon Kinesis

Familia de servicios para procesamiento de datos en **streaming en tiempo real**.

### Comparación de servicios Kinesis

| Servicio | Descripción | Latencia | Retención | Consumers | Caso de uso |
|---|---|---|---|---|---|
| **Data Streams** | Ingesta y almacenamiento de streams de datos | ~200 ms (real-time) | 1-365 días | Custom (SDK, KCL, Lambda) | Ingesta en tiempo real, processing custom |
| **Data Firehose** | Entrega de datos a destinos (near real-time) | ~60 segundos (buffer) | Sin retención (entrega directa) | S3, Redshift, OpenSearch, Splunk, HTTP | ETL y entrega automatizada |
| **Data Analytics** | Análisis SQL/Apache Flink sobre streams | Segundos | N/A (procesamiento) | Output a Streams, Firehose, Lambda | Análisis en tiempo real con SQL |
| **Video Streams** | Ingesta de video para procesamiento | Tiempo real | Configurable | Custom, Rekognition | Video analytics, ML sobre video |

### Kinesis Data Streams - Detalles

**Arquitectura:**

```
    Productores          Shards              Consumidores
    ┌──────┐         ┌─────────┐         ┌──────────────┐
    │ App  │────────►│ Shard 1 │────────►│ Lambda       │
    │ SDK  │         ├─────────┤         ├──────────────┤
    │ Agent│────────►│ Shard 2 │────────►│ KCL App      │
    │ IoT  │         ├─────────┤         ├──────────────┤
    │      │────────►│ Shard N │────────►│ Firehose     │
    └──────┘         └─────────┘         └──────────────┘
```

- **Shard**: Unidad de capacidad.
  - **Ingesta**: 1 MB/s o 1000 records/s por shard.
  - **Consumo**: 2 MB/s por shard (shared) o 2 MB/s por consumer (enhanced fan-out).
- **Partition Key**: Determina en qué shard va cada record. Clave para distribución uniforme.
- **Modos de capacidad**:
  - **Provisioned**: Se eligen los shards manualmente.
  - **On-demand**: Escala automáticamente (hasta 200 MB/s de ingesta por defecto).

**Enhanced Fan-Out:**
- Cada consumidor registrado obtiene **2 MB/s dedicados** por shard (push model vía HTTP/2).
- Sin enhanced fan-out: todos los consumidores comparten 2 MB/s por shard (pull model).
- Usar cuando hay múltiples consumidores o se necesita latencia < 70 ms.

### Kinesis Data Firehose - Detalles

- Servicio **fully managed**, no requiere administración.
- **Near real-time**: Buffer mínimo de 60 segundos o 1 MB.
- Transformación de datos con Lambda (opcional).
- **Destinos**: S3, Redshift (vía S3 COPY), OpenSearch, Splunk, HTTP endpoint, third-party partners.
- Soporta compresión (GZIP, ZIP, Snappy) y cifrado.
- **Sin retención de datos**: entrega y olvida. Los datos fallidos van a un bucket S3 de error.

### Kinesis vs SQS - Cuándo usar cada uno

| Característica | Kinesis Data Streams | SQS |
|---|---|---|
| **Modelo** | Streaming (múltiples consumidores) | Cola de mensajes (un consumidor por mensaje) |
| **Retención** | 1-365 días | Hasta 14 días |
| **Orden** | Por shard (partition key) | FIFO (con FIFO queue) o sin orden |
| **Throughput** | Basado en shards | Ilimitado (Standard) |
| **Consumidores** | Múltiples en paralelo (fan-out) | Un consumidor por mensaje |
| **Replay** | Sí (re-leer datos) | No (mensaje se borra tras procesarse) |
| **Caso de uso** | Analytics en tiempo real, logs, IoT | Desacoplamiento, procesamiento asíncrono |

---

## Amazon MQ

Servicio de message broker gestionado para **Apache ActiveMQ** y **RabbitMQ**.

### Cuándo usar Amazon MQ vs SQS/SNS

| Escenario | Servicio recomendado |
|---|---|
| Nueva aplicación cloud-native | SQS/SNS (serverless, escalable) |
| Migración de aplicaciones on-premises que usan protocolos estándar (AMQP, MQTT, STOMP, OpenWire, WSS) | Amazon MQ |
| Se necesita compatibilidad con JMS (Java Message Service) | Amazon MQ |
| Se necesitan features de broker tradicional (queue + topic en un solo servicio) | Amazon MQ |

### Características de Amazon MQ

- **No es serverless**: Se ejecuta en servidores dedicados.
- **Alta disponibilidad**: Multi-AZ con failover automático (Active/Standby).
- Soporta **colas y topics** nativamente (como un broker tradicional).
- Almacenamiento en EFS (compartido entre brokers para HA).

```
    Región AWS
    ┌────────────────────────────────────┐
    │   AZ-a              AZ-b          │
    │  ┌──────────┐    ┌──────────┐     │
    │  │ ActiveMQ │    │ ActiveMQ │     │
    │  │  Active  │◄──►│ Standby  │     │
    │  └────┬─────┘    └────┬─────┘     │
    │       │               │           │
    │       └───────┬───────┘           │
    │           ┌───▼───┐               │
    │           │  EFS  │               │
    │           │(shared)│              │
    │           └───────┘               │
    └────────────────────────────────────┘
```

> **Clave para el examen**: Si la pregunta menciona migración de aplicaciones con protocolos de mensajería tradicionales (AMQP, MQTT, STOMP, JMS), la respuesta es **Amazon MQ**, no SQS/SNS.

---

## Amazon SES

Simple Email Service: servicio para envío y recepción de email a escala.

### Características principales

- Envío de emails transaccionales, marketing y notificaciones.
- Soporta **SMTP** y API directa.
- Gestión de reputación (bounce handling, complaint feedback).
- **Dedicated IPs** para mejor control de reputación.
- Integración con S3 (almacenar emails recibidos), Lambda (procesamiento), SNS (notificaciones).
- **Templates** para personalización de emails.
- **Configuration sets**: Tracking de eventos (delivery, open, click, bounce).

### SES vs SNS (Email)

| Característica | SES | SNS (Email) |
|---|---|---|
| **Propósito** | Email profesional a escala | Notificaciones simples |
| **Formato** | HTML/Text personalizado | Solo texto plano |
| **Tracking** | Open, click, bounce, delivery | No |
| **Recepción** | Sí (puede recibir emails) | No |
| **Caso de uso** | Marketing, transaccional | Alertas de sistemas |

> **Clave**: Para emails transaccionales o marketing → SES. Para alertas simples por email → SNS.

---

## Tips para el examen

### SQS

1. **"Desacoplar componentes"** → SQS.
2. **"Orden estricto y sin duplicados"** → SQS FIFO.
3. **"Mensajes procesados dos veces"** → Aumentar visibility timeout.
4. **"Mensajes que fallan repetidamente"** → Dead-Letter Queue (DLQ).
5. **"Retrasar procesamiento de mensajes"** → Delay Queue.
6. **"Reducir llamadas API vacías"** → Long Polling.
7. **"Mensaje mayor de 256 KB"** → SQS Extended Client Library (payload en S3).
8. **"Escalar consumidores basándose en la cola"** → CloudWatch + ASG con métrica `ApproximateNumberOfMessagesVisible`.

### SNS

9. **"Enviar un mensaje a múltiples destinos"** → SNS (pub/sub).
10. **"Filtrar mensajes por suscriptor"** → SNS Message Filtering.
11. **"Notificar múltiples colas SQS desde un evento"** → Fan-out (SNS → SQS).
12. **"Fan-out con orden"** → SNS FIFO + SQS FIFO.

### EventBridge

13. **"Reaccionar a eventos de servicios AWS"** → EventBridge (default event bus).
14. **"Integrar con SaaS (Zendesk, Datadog)"** → EventBridge (partner event bus).
15. **"Programar tareas (cron en la nube)"** → EventBridge Scheduler.
16. **"Archivar y reproducir eventos"** → EventBridge Archive + Replay.
17. **"Event bus vs SNS"** → EventBridge para event-driven complejo; SNS para fan-out simple.

### Step Functions

18. **"Orquestar múltiples Lambdas"** → Step Functions.
19. **"Workflow de larga duración (horas/días)"** → Step Functions Standard.
20. **"Workflow de alto volumen (< 5 min)"** → Step Functions Express.
21. **"Manejo de errores con reintentos automáticos"** → Step Functions Retry/Catch.
22. **"Proceso de aprobación humana"** → Step Functions con Wait + callback.

### API Gateway

23. **"API REST con caching y throttling"** → API Gateway REST API.
24. **"API proxy simple y barata"** → API Gateway HTTP API.
25. **"Chat en tiempo real o streaming"** → API Gateway WebSocket.
26. **"Autenticación con tokens custom"** → Lambda Authorizer.
27. **"Autenticación con Cognito"** → Cognito User Pool Authorizer.
28. **"Llamar servicio AWS sin Lambda"** → API Gateway AWS Service integration.

### AppSync

29. **"GraphQL"** → AppSync.
30. **"Sincronización offline para mobile"** → AppSync + Amplify.
31. **"Combinar datos de múltiples fuentes en un query"** → AppSync (resolvers).

### Kinesis

32. **"Streaming en tiempo real"** → Kinesis Data Streams.
33. **"Entrega de datos a S3/Redshift/OpenSearch"** → Kinesis Data Firehose.
34. **"Análisis SQL sobre streaming"** → Kinesis Data Analytics.
35. **"Múltiples consumidores del mismo stream"** → Kinesis Data Streams con Enhanced Fan-Out.
36. **"Near real-time (60 seg buffer)"** → Firehose. **"Real-time (200 ms)"** → Data Streams.

### Amazon MQ

37. **"Migración de broker tradicional (ActiveMQ, RabbitMQ)"** → Amazon MQ.
38. **"Protocolos AMQP, MQTT, STOMP"** → Amazon MQ.
39. **"Nueva aplicación cloud-native de mensajería"** → SQS/SNS (NO Amazon MQ).
