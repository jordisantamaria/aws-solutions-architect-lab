# Lab 09: Arquitectura Completa - Plataforma E-Commerce (Proyecto Final)

## Objetivo

Proyecto final que combina todos los conceptos aprendidos en los labs anteriores. Despliega una plataforma de e-commerce serverless completa con autenticacion, API, base de datos, cache, procesamiento asincrono, notificaciones, monitorizacion y seguridad.

## Arquitectura

```
                                    ┌─────────────┐
                                    │   WAF       │
                                    │  (rules)    │
                                    └──────┬──────┘
                                           │
┌──────────┐    ┌──────────────┐    ┌──────▼──────┐    ┌─────────────┐
│ Usuarios │───▶│  CloudFront  │───▶│ S3 Frontend │    │  Cognito    │
│          │    │  (CDN)       │    │ (React/Vue) │    │ (Auth)      │
└────┬─────┘    └──────────────┘    └─────────────┘    └──────┬──────┘
     │                                                         │
     │          ┌──────────────┐    ┌─────────────┐    ┌──────▼──────┐
     └─────────▶│  API Gateway │◄──▶│  Cognito    │───▶│  Lambda     │
                │  (REST API)  │    │  Authorizer │    │  Functions  │
                └──────┬───────┘    └─────────────┘    └──┬───┬───┬──┘
                       │                                   │   │   │
              ┌────────┴────────┐                         │   │   │
              │                 │                          │   │   │
       ┌──────▼──────┐  ┌──────▼──────┐           ┌──────▼┐  │  ┌▼────────┐
       │ get_products │  │create_order │           │Aurora  │  │  │ElastiCa-│
       │ (Lambda)     │  │(Lambda)     │           │Server- │  │  │che Redis│
       └──────┬───────┘  └──────┬──────┘           │less v2 │  │  │(cache+  │
              │                 │                   └────────┘  │  │sessions)│
              │                 ▼                               │  └─────────┘
              │          ┌─────────────┐                       │
              │          │  SQS Queue  │                       │
              │          │ (orders)    │                       │
              │          └──────┬──────┘                       │
              │                 │              ┌───────────────┘
              │          ┌──────▼──────┐       │
              │          │process_pay- │       │
              │          │ment (Lambda)│       │
              │          └──────┬──────┘       │
              │                 │        ┌─────▼──────┐
              │          ┌──────▼──────┐ │S3 Uploads  │
              │          │  SNS Topic  │ │(presigned  │
              │          │(notificatio-│ │ URLs)      │
              │          │nes)         │ └────────────┘
              │          └─────────────┘
              │
       ┌──────▼───────────────────────┐
       │  CloudWatch                  │
       │  - Alarms (5xx, DLQ, CPU)    │
       │  - Dashboards                │
       │  - Logs                      │
       └──────────────────────────────┘
```

## Mapeo a los 4 dominios del examen SA Associate

### Dominio 1: Diseno de Arquitecturas Seguras (30%)
- **Cognito**: autenticacion y autorizacion de usuarios
- **WAF**: proteccion contra ataques web comunes (SQL injection, XSS)
- **IAM Roles**: principio de minimo privilegio para cada Lambda
- **S3 Presigned URLs**: acceso temporal seguro a archivos
- **Encryption**: datos cifrados en reposo y en transito

### Dominio 2: Diseno de Arquitecturas Resilientes (26%)
- **SQS + DLQ**: procesamiento asincrono con manejo de fallos
- **Aurora Serverless**: escalado automatico de base de datos
- **ElastiCache**: cache para reducir carga en la base de datos
- **CloudFront**: distribucion global con alta disponibilidad
- **Multi-AZ**: Aurora y ElastiCache con replicacion

### Dominio 3: Diseno de Arquitecturas de Alto Rendimiento (24%)
- **CloudFront CDN**: contenido estatico cerca del usuario
- **ElastiCache Redis**: cache de sesiones y datos frecuentes
- **API Gateway**: throttling y caching de respuestas
- **Aurora Serverless v2**: escalado rapido segun demanda
- **Lambda**: escalado automatico por funcion

### Dominio 4: Diseno de Arquitecturas Optimizadas en Costes (20%)
- **Serverless**: pago por uso (Lambda, API Gateway, Aurora Serverless)
- **S3 + CloudFront**: hosting estatico sin servidores
- **SQS**: desacoplamiento para optimizar recursos
- **Aurora Serverless v2**: escala a 0.5 ACU cuando no hay trafico

## Componentes desplegados

| Servicio | Recurso | Funcion |
|----------|---------|---------|
| Cognito | User Pool + App Client | Autenticacion de usuarios |
| S3 | Bucket frontend | Hosting del frontend |
| CloudFront | Distribucion | CDN global |
| API Gateway | REST API | Punto de entrada del API |
| Lambda | get_products | Consulta productos |
| Lambda | create_order | Crea pedidos |
| Lambda | process_payment | Procesa pagos |
| Aurora | Serverless v2 PostgreSQL | Base de datos |
| ElastiCache | Redis cluster | Cache y sesiones |
| SQS | Cola + DLQ | Procesamiento de pedidos |
| SNS | Topic | Notificaciones de pedidos |
| S3 | Bucket uploads | Subida de archivos |
| WAF | WebACL | Proteccion web |
| CloudWatch | Alarms | Monitorizacion |

## Coste estimado

**~$5-8/dia** (principalmente Aurora Serverless y ElastiCache)

> **Nota**: Aurora Serverless v2 tiene un minimo de 0.5 ACU (~$0.12/hora). ElastiCache tiene coste por nodo. Destruye cuando no lo uses.

## Este lab es el mas complejo - tomatelo con calma

1. **No intentes entenderlo todo de golpe**. Revisa seccion por seccion.
2. **Despliega y experimenta**. Haz cambios, rompe cosas, aprende.
3. **Relaciona cada componente con el examen**. Preguntate: si me preguntan sobre este servicio en el examen, que responderia?
4. **Dibuja la arquitectura a mano**. Esto ayuda mucho a consolidar el conocimiento.

## Como desplegar

```bash
# Inicializar Terraform
terraform init

# Ver el plan (sera largo - muchos recursos)
terraform plan

# Desplegar
terraform apply

# Destruir cuando termines
terraform destroy
```

## Pruebas basicas

### 1. Probar autenticacion con Cognito
```bash
# Crear usuario de prueba
aws cognito-idp sign-up \
  --client-id <app_client_id> \
  --username testuser@example.com \
  --password "Test1234!"

# Confirmar usuario (admin)
aws cognito-idp admin-confirm-sign-up \
  --user-pool-id <user_pool_id> \
  --username testuser@example.com
```

### 2. Probar el API
```bash
# Obtener token
TOKEN=$(aws cognito-idp initiate-auth \
  --client-id <app_client_id> \
  --auth-flow USER_PASSWORD_AUTH \
  --auth-parameters USERNAME=testuser@example.com,PASSWORD="Test1234!" \
  --query 'AuthenticationResult.IdToken' --output text)

# Llamar al API
curl -H "Authorization: $TOKEN" https://<api_id>.execute-api.eu-west-1.amazonaws.com/prod/products
```

### 3. Verificar CloudWatch
```bash
# Ver alarmas activas
aws cloudwatch describe-alarms --state-value ALARM
```

## Limpieza

```bash
# IMPORTANTE: Destruir todo al terminar
terraform destroy
```

> Verifica en la consola que no quedan recursos activos. Presta especial atencion a Aurora, ElastiCache y los buckets S3.
