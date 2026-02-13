# Lab 06: Arquitectura Event-Driven

## Objetivo

Construir una arquitectura event-driven con desacoplamiento total entre componentes, usando patrones de mensajeria y eventos de AWS. Este lab cubre los patrones de diseño mas importantes para el examen: fan-out, dead-letter queues, integracion directa de servicios y procesamiento asincrono.

## Arquitectura

```
  FLUJO 1: Procesamiento de eventos S3
  =====================================

  ┌──────────┐     ┌──────────────┐     ┌──────────────┐
  │  S3      │────►│ EventBridge  │────►│  SNS Topic   │
  │  Upload  │     │  Rule        │     │  (fan-out)   │
  └──────────┘     └──────────────┘     └──────┬───────┘
                                               │
                               ┌───────────────┼───────────────┐
                               │               │               │
                               ▼               ▼               │
                    ┌──────────────┐ ┌──────────────┐          │
                    │  SQS Queue   │ │  SQS Queue   │          │
                    │  (images)    │ │  (audit)     │          │
                    └──────┬───────┘ └──────┬───────┘          │
                           │                │                  │
                    ┌──────┴───────┐ ┌──────┴───────┐          │
                    │  DLQ         │ │  DLQ         │          │
                    │  (images)    │ │  (audit)     │          │
                    └──────────────┘ └──────────────┘          │
                           │                │                  │
                           ▼                ▼                  │
                    ┌──────────────┐ ┌──────────────┐          │
                    │  Lambda      │ │  Lambda      │          │
                    │  Image       │ │  Audit       │          │
                    │  Processor   │ │  Logger      │          │
                    └──────────────┘ └──────────────┘          │
                                                               │
                                                               │
  FLUJO 2: API Gateway -> SQS (integracion directa)           │
  ===================================================          │
                                                               │
  ┌──────────┐     ┌──────────────┐     ┌──────────────┐      │
  │  Cliente  │────►│ API Gateway │────►│  SQS Queue   │      │
  │  HTTP     │     │  (REST)     │     │  (API msgs)  │      │
  └──────────┘     └──────────────┘     └──────┬───────┘      │
                     Sin Lambda                 │              │
                     en medio!                  ▼              │
                                        ┌──────────────┐      │
                                        │  Lambda      │      │
                                        │  Consumer    │      │
                                        └──────────────┘      │
```

## Que vas a aprender

- **EventBridge**: bus de eventos centralizado para capturar y enrutar eventos de servicios AWS
- **SNS (fan-out)**: distribucion de un mensaje a multiples suscriptores simultaneamente
- **SQS**: colas de mensajes para desacoplar productores y consumidores
- **Dead-Letter Queues (DLQ)**: manejo de mensajes que fallan en el procesamiento
- **Lambda con SQS**: procesamiento de mensajes de cola con funciones serverless
- **API Gateway -> SQS directo**: integracion sin Lambda proxy (reduce costes y latencia)
- **Message filtering**: filtrar mensajes en SNS para que cada cola reciba solo lo relevante
- **IAM Roles para Lambda**: permisos minimos necesarios (least privilege)

## Componentes desplegados

| Componente | Servicio AWS | Funcion |
|---|---|---|
| Almacenamiento | S3 Bucket | Origen de eventos (uploads) |
| Bus de eventos | EventBridge Rule | Captura eventos PutObject de S3 |
| Distribucion | SNS Topic | Fan-out a multiples colas |
| Cola procesamiento | SQS Queue (images) | Cola para procesamiento de imagenes |
| Cola auditoria | SQS Queue (audit) | Cola para registro de auditoria |
| Colas errores | SQS DLQ x2 | Dead-letter queues para mensajes fallidos |
| Procesadores | Lambda x2 | Consumidores de mensajes |
| API | API Gateway | Punto de entrada HTTP directo a SQS |

## Patrones de diseno cubiertos

1. **Fan-out pattern**: un evento genera multiples acciones en paralelo
2. **Dead-letter queue pattern**: manejo de errores sin perder mensajes
3. **Service integration pattern**: API Gateway se integra directamente con SQS sin Lambda
4. **Event sourcing**: S3 como fuente de eventos via EventBridge

## Requisitos previos

- AWS CLI configurado
- Terraform >= 1.0

## Despliegue

```bash
terraform init
terraform plan
terraform apply
```

## Pruebas

### Flujo 1: Subir archivo a S3
```bash
# Crear un archivo de prueba y subirlo al bucket
echo "test content" > test.txt
aws s3 cp test.txt s3://$(terraform output -raw s3_bucket_name)/test.txt

# Verificar los logs de las funciones Lambda
aws logs tail /aws/lambda/event-driven-dev-image-processor --follow
aws logs tail /aws/lambda/event-driven-dev-audit-logger --follow
```

### Flujo 2: Enviar mensaje via API Gateway
```bash
# Enviar un mensaje directamente a la cola via API Gateway
curl -X POST $(terraform output -raw api_endpoint)/messages \
  -H "Content-Type: application/json" \
  -d '{"message": "test event from API"}'
```

## Coste estimado

**Free Tier** - Todos los servicios usados estan dentro del Free Tier de AWS:

| Servicio | Free Tier |
|---|---|
| S3 | 5 GB almacenamiento |
| EventBridge | Gratuito para eventos de servicios AWS |
| SNS | 1 millon de publicaciones/mes |
| SQS | 1 millon de solicitudes/mes |
| Lambda | 1 millon de invocaciones/mes |
| API Gateway | 1 millon de llamadas API/mes |
