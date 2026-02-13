# Monitorización y Gestión en AWS (Monitoring & Management)

## Índice

- [Amazon CloudWatch](#amazon-cloudwatch)
- [CloudWatch Logs](#cloudwatch-logs)
- [CloudWatch Agent](#cloudwatch-agent)
- [AWS CloudTrail](#aws-cloudtrail)
- [AWS Config](#aws-config)
- [AWS X-Ray](#aws-x-ray)
- [Amazon EventBridge como herramienta de monitorización](#amazon-eventbridge-como-herramienta-de-monitorización)
- [AWS Trusted Advisor](#aws-trusted-advisor)
- [AWS Health Dashboard](#aws-health-dashboard)
- [VPC Flow Logs](#vpc-flow-logs)
- [AWS Systems Manager](#aws-systems-manager)
- [Tips para el examen](#tips-para-el-examen)

---

## Amazon CloudWatch

Servicio de monitorización y observabilidad de AWS. Recopila métricas, logs y eventos de los recursos y aplicaciones.

### Métricas (Metrics)

- Cada servicio AWS envía métricas a CloudWatch automáticamente.
- Una **métrica** pertenece a un **namespace** (ej: `AWS/EC2`, `AWS/RDS`).
- Cada métrica tiene hasta **30 dimensiones** (atributos como InstanceId, InstanceType).
- **Resolución**:
  - Estándar: datos cada **5 minutos** (gratuito).
  - Detailed monitoring: datos cada **1 minuto** (coste adicional).
  - High-resolution custom metrics: hasta cada **1 segundo**.
- Retención de datos:
  - Datos de 1 segundo → disponibles durante 3 horas.
  - Datos de 60 segundos → disponibles durante 15 días.
  - Datos de 5 minutos → disponibles durante 63 días.
  - Datos de 1 hora → disponibles durante 455 días (15 meses).

### Métricas comunes por servicio

| Servicio | Métricas clave | Nota |
|---|---|---|
| **EC2** | CPUUtilization, NetworkIn/Out, StatusCheckFailed | **NO incluye memoria RAM ni disco** (requieren agent) |
| **EBS** | VolumeReadOps, VolumeWriteOps, BurstBalance | BurstBalance para gp2 |
| **RDS** | DatabaseConnections, FreeableMemory, ReadIOPS | FreeableMemory SÍ está disponible |
| **ALB** | RequestCount, TargetResponseTime, HTTPCode_Target_5XX | HealthyHostCount importante |
| **Lambda** | Invocations, Duration, Errors, Throttles, ConcurrentExecutions | Métricas automáticas |
| **S3** | BucketSizeBytes, NumberOfObjects | Métricas diarias de bucket |
| **SQS** | ApproximateNumberOfMessagesVisible, ApproximateAgeOfOldestMessage | Clave para auto scaling |

> **Clave para el examen**: EC2 NO envía métricas de RAM ni uso de disco a CloudWatch por defecto. Se necesita el CloudWatch Agent para esto.

### Custom Metrics

- Se publican con la API `PutMetricData`.
- Se puede definir resolución: **Standard** (60 segundos) o **High Resolution** (1 segundo).
- Se pueden enviar datos del pasado (hasta 2 semanas) y del futuro (hasta 2 horas).
- Se pueden usar dimensiones para segmentar (ej: `Environment=prod`, `InstanceId=i-xxx`).

### CloudWatch Alarms

Evalúan métricas y ejecutan acciones cuando se cruzan umbrales.

**Estados de una alarma:**
- `OK`: La métrica está dentro del umbral.
- `ALARM`: La métrica ha cruzado el umbral.
- `INSUFFICIENT_DATA`: No hay datos suficientes para evaluar.

**Acciones disponibles:**

| Acción | Descripción |
|---|---|
| **EC2 Actions** | Stop, Terminate, Reboot, Recover la instancia |
| **Auto Scaling** | Scale out/in |
| **SNS** | Enviar notificación a un topic SNS |
| **Systems Manager** | Ejecutar un OpsItem o Incident |
| **Lambda** | Invocar función (a través de SNS) |

**Configuración de alarmas:**
- **Period**: Período de evaluación (ej: 300 segundos = 5 min).
- **Evaluation Periods**: Número de períodos consecutivos que deben estar en alarma.
- **Datapoints to Alarm**: Número mínimo de datapoints en alarma dentro de los evaluation periods.

> **Ejemplo**: Period=60s, Evaluation Periods=5, Datapoints to Alarm=3 → La alarma se activa si 3 de los últimos 5 minutos están por encima del umbral.

### Composite Alarms

- Combinan múltiples alarmas con operadores lógicos **AND** y **OR**.
- Reducen el "alarm noise" al requerir que múltiples condiciones se cumplan.
- Caso de uso: Solo alertar si CPU alta **AND** memoria alta (no solo una de las dos).

### CloudWatch Dashboards

- Visualización de métricas en paneles personalizados.
- **Globales**: Pueden incluir métricas de diferentes regiones y cuentas.
- Widgets: Line, Stacked area, Number, Bar, Text, Log, Alarm status.
- Se pueden compartir externamente (con Cognito).
- Gratuitos hasta 3 dashboards (50 métricas cada uno). Después, $3/dashboard/mes.

---

## CloudWatch Logs

Servicio centralizado para recopilar, monitorizar y analizar logs.

### Conceptos clave

```
    ┌─────────────────────────────────────┐
    │          CloudWatch Logs            │
    │                                     │
    │  Log Group: /aws/lambda/mi-funcion  │
    │  ├── Log Stream: 2024/01/15/[$LATEST]abc123  │
    │  │   ├── Log Event (timestamp + mensaje)     │
    │  │   ├── Log Event                           │
    │  │   └── Log Event                           │
    │  ├── Log Stream: 2024/01/15/[$LATEST]def456  │
    │  └── ...                                     │
    │                                     │
    │  Retention: 1 día → 10 años → Never │
    └─────────────────────────────────────┘
```

| Concepto | Descripción |
|---|---|
| **Log Group** | Agrupación lógica de logs (ej: por aplicación o servicio). Configuración de retención y cifrado. |
| **Log Stream** | Secuencia de eventos del mismo origen (ej: una instancia EC2 específica). |
| **Log Event** | Un registro individual con timestamp y mensaje. |
| **Retention** | Configurable: desde 1 día hasta 10 años, o sin expiración. |

### Fuentes de logs

| Fuente | Log Group típico |
|---|---|
| **Lambda** | `/aws/lambda/<function-name>` (automático) |
| **API Gateway** | `/aws/apigateway/<api-name>` |
| **ECS** | `/ecs/<service-name>` |
| **CloudTrail** | Configurable |
| **Route 53** | DNS query logs |
| **VPC Flow Logs** | Configurable |
| **EC2 / on-premises** | Requiere CloudWatch Agent |
| **Elastic Beanstalk** | Automático |

### Metric Filters

- Extraen datos de los logs y los convierten en **métricas de CloudWatch**.
- Usan patrones de filtro para buscar en los log events.
- Se pueden crear alarmas sobre estas métricas.

**Ejemplo de uso**: Contar el número de errores "ERROR" en los logs y crear una alarma si supera un umbral.

```
    Logs ──► Metric Filter ("ERROR") ──► Custom Metric ──► Alarm ──► SNS
```

> **Nota**: Los metric filters NO son retroactivos. Solo procesan eventos que llegan DESPUÉS de crear el filtro.

### CloudWatch Logs Insights

- Motor de consultas interactivo para analizar logs.
- Lenguaje de consulta propio (similar a SQL).
- Puede consultar múltiples log groups.
- Visualización de resultados en tablas y gráficos.

**Ejemplo de query:**

```
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 20
```

### Exportar logs

| Destino | Método | Latencia |
|---|---|---|
| **S3** | Export task (API: `CreateExportTask`) | Hasta **12 horas** (no en tiempo real) |
| **Kinesis Data Streams** | Subscription filter (tiempo real) | Tiempo real |
| **Kinesis Data Firehose** | Subscription filter (near real-time) | Near real-time (~60s) |
| **Lambda** | Subscription filter (tiempo real) | Tiempo real |
| **OpenSearch** | Subscription filter (tiempo real) | Tiempo real |

> **Clave**: Para exportar logs a S3 en tiempo real NO se usa `CreateExportTask` (tarda horas). Se usa un **Subscription Filter** → Kinesis Data Firehose → S3.

### Logs cross-account

- Se pueden enviar logs de múltiples cuentas a una cuenta centralizada usando **Subscription Filters** + Kinesis Data Streams o Firehose.

---

## CloudWatch Agent

### CloudWatch Unified Agent

Agente que se instala en instancias EC2 o servidores on-premises para enviar métricas y logs adicionales a CloudWatch.

**Métricas que recopila (no disponibles por defecto):**

| Métrica | Descripción |
|---|---|
| **Memory** | Utilización de RAM (mem_used_percent) |
| **Disk** | Uso de disco, I/O (disk_used_percent) |
| **Swap** | Uso de memoria swap |
| **Netstat** | Conexiones TCP, UDP |
| **Processes** | Número de procesos |
| **CPU** | Métricas granulares por core |

**Configuración:**
- Se configura mediante un archivo JSON o con el **SSM Parameter Store** (centralizado).
- Se puede usar el wizard `amazon-cloudwatch-agent-config-wizard` para generar la configuración.
- Requiere un **IAM Role** con permisos para CloudWatch Logs y Metrics.

**Diferencia entre agentes:**
- **CloudWatch Logs Agent** (legacy): Solo envía logs. No métricas custom.
- **CloudWatch Unified Agent** (recomendado): Envía logs Y métricas custom. Más configurable.

> **Clave**: Si la pregunta menciona "monitorizar memoria RAM de EC2" o "uso de disco", la respuesta siempre incluye instalar el **CloudWatch Unified Agent**.

---

## AWS CloudTrail

Servicio de auditoría que registra todas las llamadas API realizadas en la cuenta de AWS.

### Tipos de eventos

| Tipo | Descripción | Habilitado por defecto | Ejemplo |
|---|---|---|---|
| **Management Events** | Operaciones sobre recursos AWS (crear, configurar, eliminar) | Sí (90 días gratis) | CreateBucket, TerminateInstances, AttachRolePolicy |
| **Data Events** | Operaciones sobre los datos dentro de los recursos | No (alto volumen, coste adicional) | GetObject en S3, Invoke en Lambda |
| **Insights Events** | Detección de actividad inusual | No (debe habilitarse) | Picos anormales de API calls |

### Management Events - Detalle

- **Read Events**: Operaciones de lectura que no modifican recursos (ej: `DescribeInstances`, `ListBuckets`).
- **Write Events**: Operaciones que modifican recursos (ej: `CreateBucket`, `DeleteTable`).
- Se pueden separar para optimizar costes (solo registrar write events).

### CloudTrail Insights

- Analiza management events para detectar **actividad inusual**.
- Establece una línea base de actividad normal.
- Detecta: picos en la creación de recursos, uso inusual de APIs, gaps en actividad.
- Los insights se pueden enviar a S3, EventBridge, o la consola de CloudTrail.

### Configuración multi-región y organización

| Configuración | Descripción |
|---|---|
| **Multi-region trail** | Un solo trail que captura eventos de TODAS las regiones. Recomendado siempre. |
| **Organization trail** | Un trail para TODAS las cuentas de la organización. Se almacena en un bucket S3 centralizado. |
| **Log file integrity** | Validación de integridad de los logs usando SHA-256 hash. Detecta si los logs han sido modificados o eliminados. |

### Almacenamiento y análisis

- Los eventos se almacenan en **S3** (logs comprimidos en JSON).
- Retención en la consola de CloudTrail: **90 días** (gratis).
- Para retención mayor: crear un Trail que envíe a S3.
- Se puede enviar a **CloudWatch Logs** para crear metric filters y alarmas.
- Se puede analizar con **Athena** (queries SQL directamente sobre los logs en S3).

```
    API Call ──► CloudTrail ──► S3 Bucket (almacenamiento a largo plazo)
                           ──► CloudWatch Logs (alarmas en tiempo real)
                           ──► EventBridge (reaccionar a eventos)
```

> **Clave para el examen**: CloudTrail = "quién hizo qué y cuándo" (auditoría de API calls). CloudWatch = "cómo está funcionando el recurso" (métricas y logs operativos). Son complementarios.

---

## AWS Config

Servicio que evalúa, audita y registra la **configuración** de los recursos AWS. Permite verificar compliance de forma continua.

### Conceptos clave

| Concepto | Descripción |
|---|---|
| **Config Rules** | Reglas que evalúan si los recursos cumplen con la configuración deseada |
| **Configuration Items** | Snapshot de la configuración de un recurso en un punto en el tiempo |
| **Configuration Recorder** | Registra los cambios de configuración |
| **Compliance** | Estado de cumplimiento de las reglas (COMPLIANT / NON_COMPLIANT) |

### Config Rules

- **AWS Managed Rules**: Más de 75 reglas predefinidas (ej: `s3-bucket-versioning-enabled`, `ec2-instance-no-public-ip`, `rds-instance-public-access-check`).
- **Custom Rules**: Definidas con Lambda o AWS CloudFormation Guard.
- Se evalúan:
  - Ante cada cambio de configuración (trigger de cambio).
  - De forma periódica (cada 1, 3, 6, 12 o 24 horas).
- **No previenen** acciones; solo evalúan y notifican.

### Remediación (Remediation)

- Acciones automáticas para corregir recursos no conformes.
- Usa **SSM Automation Documents** para ejecutar la corrección.
- Se puede configurar remediación automática con reintentos.

**Ejemplo de flujo:**

```
    Recurso cambia ──► Config Rule evalúa ──► NON_COMPLIANT
                                                  │
                                                  ▼
                                          Remediation Action
                                          (SSM Automation)
                                                  │
                                                  ▼
                                          Recurso corregido
```

### Conformance Packs

- Colección de Config Rules y remediation actions empaquetadas como una sola unidad.
- Se pueden desplegar en una cuenta o en toda la organización.
- Ejemplo: Pack de compliance para PCI-DSS, HIPAA, etc.

### Config Aggregator

- Vista centralizada del estado de compliance de **múltiples cuentas y regiones**.
- Recopila datos de Config de todas las cuentas de la organización.
- No requiere permisos individuales si se usa AWS Organizations.

> **Clave**: Config = "cómo están configurados mis recursos y si cumplen las reglas". CloudTrail = "quién cambió la configuración". Son complementarios.

---

## AWS X-Ray

Servicio de tracing distribuido para analizar y depurar aplicaciones en producción, especialmente arquitecturas de microservicios.

### Conceptos clave

| Concepto | Descripción |
|---|---|
| **Trace** | Rastro end-to-end de un request a través de múltiples servicios |
| **Segment** | Bloque de trabajo realizado por un servicio individual |
| **Subsegment** | Detalle granular dentro de un segmento (ej: llamada a DynamoDB desde Lambda) |
| **Service Map** | Visualización gráfica de la arquitectura y latencias entre servicios |
| **Annotations** | Key-value pairs indexados para filtrar traces |
| **Metadata** | Key-value pairs NO indexados para información adicional |
| **Sampling** | Controla el porcentaje de requests que se tracean (reducir coste) |

### Arquitectura de X-Ray

```
    Request del usuario
         │
    ┌────▼────┐    ┌──────────┐    ┌──────────┐
    │   API   │───►│  Lambda  │───►│ DynamoDB │
    │ Gateway │    │          │    │          │
    └────┬────┘    └────┬─────┘    └────┬─────┘
         │              │               │
    Segmento 1     Segmento 2     Subsegmento
         │              │               │
         └──────────────┴───────────────┘
                        │
                  ┌─────▼─────┐
                  │  X-Ray    │
                  │  Service  │
                  │   Map     │
                  └───────────┘
```

### Integración con servicios AWS

| Servicio | Integración |
|---|---|
| **Lambda** | Habilitación directa en la configuración de la función |
| **API Gateway** | Se habilita en el stage |
| **EC2** | Requiere instalar el X-Ray Daemon |
| **ECS/EKS** | X-Ray Daemon como sidecar container |
| **Elastic Beanstalk** | Configuración en `.ebextensions` |
| **App Runner** | Habilitación directa |

### Sampling Rules

- **Default**: 1 request/segundo + 5% de requests adicionales.
- Se pueden definir reglas personalizadas (ej: tracear 100% de errores, 1% de requests exitosos).
- Reglas de reservoir (mínimo garantizado) + fixed rate (porcentaje adicional).

> **Clave**: X-Ray ayuda a identificar cuellos de botella y errores en arquitecturas distribuidas. Si la pregunta menciona "tracing", "latencia entre microservicios", "mapa de servicios", la respuesta es X-Ray.

---

## Amazon EventBridge como herramienta de monitorización

Además de su uso como bus de eventos, EventBridge es útil para monitorización:

### Casos de uso de monitorización

| Evento | Origen | Acción |
|---|---|---|
| Cambio de estado de EC2 (running → stopped) | EC2 | SNS → notificación al equipo |
| Console sign-in | CloudTrail | Lambda → verificar IP y alertar |
| API call inusual | CloudTrail + EventBridge | Step Functions → workflow de investigación |
| Pipeline de CI/CD fallido | CodePipeline | SNS → notificación a devs |
| Scheduled health check | EventBridge Scheduler | Lambda → verificar endpoints |
| Config rule non-compliant | AWS Config | SNS → alerta de compliance |
| GuardDuty finding | GuardDuty | Lambda → remediation automática |

### EventBridge + CloudTrail

- Todos los management events de CloudTrail generan eventos en el **default event bus**.
- Se pueden crear reglas para reaccionar a API calls específicas.

**Ejemplo**: Detectar cuando alguien elimina una tabla DynamoDB:

```json
{
  "source": ["aws.dynamodb"],
  "detail-type": ["AWS API Call via CloudTrail"],
  "detail": {
    "eventSource": ["dynamodb.amazonaws.com"],
    "eventName": ["DeleteTable"]
  }
}
```

> **Clave**: EventBridge es el pegamento entre servicios de monitorización. Permite crear flujos reactivos ante cualquier cambio en la infraestructura.

---

## AWS Trusted Advisor

Servicio que inspecciona el entorno AWS y proporciona recomendaciones en tiempo real basadas en mejores prácticas.

### Categorías de checks

| Categoría | Ejemplo de checks |
|---|---|
| **Cost Optimization** | Instancias EC2 infrautilizadas, EBS volumes no adjuntos, IPs elásticas no usadas, Reserved Instance optimization |
| **Performance** | EC2 con alto uso de CPU, CloudFront con distribuciones subóptimas, provisionamiento insuficiente |
| **Security** | Security Groups con puertos abiertos al mundo, IAM sin MFA, S3 buckets públicos, claves de acceso sin rotar |
| **Fault Tolerance** | EBS snapshots no recientes, RDS sin Multi-AZ, ASG sin multi-AZ, Route 53 sin health checks |
| **Service Limits** | Porcentaje de uso de cuotas de servicio (80%+ genera warning) |
| **Operational Excellence** | (Solo con planes avanzados) CloudFormation stack notifications, etc. |

### Checks por nivel de Support Plan

| Check | Basic / Developer | Business | Enterprise |
|---|---|---|---|
| **S3 Bucket Permissions** (público) | Disponible | Disponible | Disponible |
| **Security Groups - Unrestricted Ports** | Disponible | Disponible | Disponible |
| **IAM Use** | Disponible | Disponible | Disponible |
| **MFA on Root Account** | Disponible | Disponible | Disponible |
| **EBS Public Snapshots** | Disponible | Disponible | Disponible |
| **RDS Public Snapshots** | Disponible | Disponible | Disponible |
| **Service Limits** | Disponible | Disponible | Disponible |
| **Todos los demás checks (~115+)** | NO disponible | Disponible | Disponible |
| **API access** (`aws support describe-trusted-advisor-checks`) | NO | Disponible | Disponible |
| **CloudWatch integration** | NO | Disponible | Disponible |

> **Clave para el examen**: Con el plan **Basic/Developer** solo se tienen los 7 core checks (principalmente seguridad y service limits). Para el set completo se necesita **Business o Enterprise**.

### Trusted Advisor + EventBridge

- Los cambios de estado de Trusted Advisor checks generan eventos en EventBridge.
- Se pueden crear alarmas y flujos automáticos de remediación.

---

## AWS Health Dashboard

Proporciona visibilidad sobre el estado de los servicios AWS y cómo afectan a tu cuenta.

### Service Health Dashboard vs Personal Health Dashboard

| Característica | Service Health Dashboard | AWS Health Dashboard (Personal) |
|---|---|---|
| **URL** | `health.aws.amazon.com` | Dentro de la consola AWS |
| **Alcance** | Estado global de todos los servicios AWS | Solo eventos que afectan a TU cuenta |
| **Información** | Interrupciones y problemas de servicio generales | Impacto en tus recursos específicos |
| **Notificaciones** | RSS feed | EventBridge, notificaciones proactivas |
| **Historial** | Sí (incidentes pasados) | Sí (eventos de los últimos 90 días) |
| **API** | No | Sí (`aws health` API, requiere Business/Enterprise) |

### AWS Health Dashboard (Personal) - Detalles

- **Eventos programados**: Mantenimiento planificado que afectará a tus recursos.
- **Eventos operativos**: Problemas actuales en servicios que afectan a tus recursos.
- **Notificaciones proactivas**: Alertas sobre cambios que podrían afectarte.
- **Integración con EventBridge**: Automatizar respuestas ante eventos de salud.

```
    AWS Health ──► EventBridge Rule ──► Lambda ──► Migrar instancia afectada
                                   ──► SNS ──► Notificar al equipo
```

> **Clave**: Si la pregunta menciona "saber si un problema de AWS afecta a mis recursos específicos", la respuesta es **AWS Health Dashboard** (Personal). Para el estado general de los servicios, es el **Service Health Dashboard**.

---

## VPC Flow Logs

Capturan información sobre el tráfico IP que entra y sale de las interfaces de red en la VPC.

### Niveles de captura

| Nivel | Descripción |
|---|---|
| **VPC** | Captura todo el tráfico de todas las ENIs en la VPC |
| **Subnet** | Captura el tráfico de todas las ENIs en la subnet |
| **ENI (Network Interface)** | Captura el tráfico de una interfaz de red específica |

### Formato del log

```
version account-id interface-id srcaddr dstaddr srcport dstport protocol packets bytes start end action log-status
```

**Campos clave:**

| Campo | Descripción |
|---|---|
| `srcaddr` / `dstaddr` | IP origen y destino |
| `srcport` / `dstport` | Puerto origen y destino |
| `protocol` | Protocolo (6=TCP, 17=UDP, 1=ICMP) |
| `action` | **ACCEPT** o **REJECT** |
| `log-status` | OK, NODATA, SKIPDATA |

### Destinos de almacenamiento

| Destino | Caso de uso |
|---|---|
| **CloudWatch Logs** | Análisis con Logs Insights, metric filters, alarmas |
| **S3** | Almacenamiento a largo plazo, análisis con Athena |
| **Kinesis Data Firehose** | Análisis en tiempo real, entrega a OpenSearch |

### Tráfico NO capturado por Flow Logs

- Tráfico DNS a Amazon DNS server (sí se captura si usas tu propio DNS).
- Tráfico de metadatos de instancia (`169.254.169.254`).
- Tráfico DHCP.
- Tráfico al VPC router.
- Tráfico a la dirección reservada del VPC (Network+1 address).

### Análisis de VPC Flow Logs

**Con Athena (S3):**

```sql
SELECT srcaddr, dstaddr, dstport, protocol, action, COUNT(*) as count
FROM vpc_flow_logs
WHERE action = 'REJECT'
GROUP BY srcaddr, dstaddr, dstport, protocol, action
ORDER BY count DESC
LIMIT 10;
```

**Con CloudWatch Logs Insights:**

```
fields @timestamp, srcAddr, dstAddr, dstPort, action
| filter action = "REJECT"
| stats count(*) as rejectCount by srcAddr
| sort rejectCount desc
| limit 10
```

> **Clave**: Si la pregunta pide "analizar tráfico rechazado" o "troubleshoot conectividad de red", piensa en **VPC Flow Logs**. Si necesita análisis con SQL, piensa en Athena sobre los logs en S3.

---

## AWS Systems Manager

Servicio unificado para gestionar la infraestructura AWS y on-premises a escala.

### Requisitos previos

- Las instancias EC2 y servidores on-premises necesitan el **SSM Agent** instalado.
- El SSM Agent viene preinstalado en Amazon Linux 2, Amazon Linux 2023 y algunas AMIs de Ubuntu.
- Las instancias necesitan un **IAM Instance Profile** con permisos de SSM (`AmazonSSMManagedInstanceCore`).

### Parameter Store

Almacén centralizado y seguro para datos de configuración y secretos.

| Característica | Standard | Advanced |
|---|---|---|
| **Número de parámetros** | 10,000 | 100,000+ |
| **Tamaño máximo** | 4 KB | 8 KB |
| **Políticas de parámetro** | No | Sí (TTL, notificaciones) |
| **Coste** | Gratuito | De pago |

**Tipos de parámetros:**
- **String**: Texto plano.
- **StringList**: Lista de valores separados por comas.
- **SecureString**: Cifrado con KMS.

**Organización jerárquica:**

```
/mi-app/
    /dev/
        /db-url         → "dev-db.example.com"
        /db-password    → (SecureString) "xxx"
    /prod/
        /db-url         → "prod-db.example.com"
        /db-password    → (SecureString) "yyy"
```

**Parameter Store vs Secrets Manager:**

| Característica | Parameter Store | Secrets Manager |
|---|---|---|
| **Rotación automática** | No nativa (se puede con Lambda) | Sí, integrada (RDS, Redshift, DocumentDB) |
| **Coste** | Gratuito (Standard) | $0.40/secreto/mes |
| **Cross-account** | No nativo | Sí |
| **Cifrado** | Opcional (SecureString con KMS) | Siempre cifrado |
| **Caso de uso** | Configuraciones generales y secretos simples | Secretos con rotación, credenciales de DB |

> **Clave**: Si la pregunta necesita **rotación automática de credenciales de base de datos**, la respuesta es **Secrets Manager**. Para configuraciones generales, **Parameter Store**.

### Session Manager

- Acceso shell seguro a instancias EC2 y on-premises **sin SSH, sin bastion host, sin abrir el puerto 22**.
- Todo el tráfico va a través de SSM (puerto 443 HTTPS).
- **Auditoría completa**: Se puede registrar toda la sesión en S3 y CloudWatch Logs.
- Integración con IAM para control de acceso.
- Compatible con Linux, Windows y macOS.

```
    Usuario ──► IAM Auth ──► SSM Session Manager ──► SSM Agent ──► Instancia
                                     │
                              (Puerto 443, HTTPS)
                                     │
                              Sin necesidad de:
                              - SSH key pairs
                              - Bastion hosts
                              - Puerto 22 abierto
                              - IP pública en la instancia
```

> **Clave para el examen**: Si la pregunta pide "acceso seguro a EC2 sin SSH" o "sin bastion host" o "auditar comandos ejecutados", la respuesta es **Session Manager**.

### Patch Manager

- Automatiza el proceso de parcheo de instancias gestionadas.
- Soporta OS (Linux, Windows) y aplicaciones.
- **Patch Baseline**: Define qué parches aprobar automáticamente (por clasificación, severidad).
  - Predefinidas por AWS para cada OS.
  - Se pueden crear custom baselines.
- **Patch Group**: Agrupa instancias por tag para aplicar baselines específicas.
- **Maintenance Window**: Ventana de tiempo para ejecutar el parcheo.
- **Compliance reporting**: Estado de parcheo de todas las instancias.

### Run Command

- Ejecuta comandos o scripts en instancias gestionadas (EC2 y on-premises) **sin SSH**.
- Usa **SSM Documents** (JSON/YAML) que definen las acciones a ejecutar.
- Se puede ejecutar en instancias individuales, por tags, o por resource groups.
- Integración con IAM, CloudTrail y EventBridge.
- Los resultados se pueden enviar a S3 o CloudWatch Logs.
- Control de rate (concurrencia máxima y porcentaje de error).

**Documentos comunes:**
- `AWS-RunShellScript`: Ejecutar comandos shell en Linux.
- `AWS-RunPowerShellScript`: Ejecutar PowerShell en Windows.
- `AWS-ConfigureAWSPackage`: Instalar/desinstalar paquetes.

### Automation

- Automatiza tareas comunes de mantenimiento y despliegue.
- Usa **Automation Runbooks** (SSM Documents de tipo Automation).
- Se puede activar manualmente, por EventBridge, por Config remediation, o por mantenimiento programado.

**Ejemplos de runbooks:**
- `AWS-RestartEC2Instance`: Reiniciar una instancia.
- `AWS-CreateImage`: Crear una AMI de una instancia.
- `AWS-StopEC2InstancesWithApproval`: Parar instancias con aprobación manual.

**Integración con Config:**

```
    Config Rule (NON_COMPLIANT) ──► Remediation Action ──► SSM Automation Runbook
                                                              │
                                                         Corrige el recurso
```

### Otros componentes de Systems Manager

| Componente | Descripción |
|---|---|
| **Inventory** | Recopila metadatos de instancias (software instalado, configuración de red, etc.) |
| **State Manager** | Mantiene instancias en un estado deseado (ej: antivirus instalado) |
| **Compliance** | Vista centralizada del estado de parcheo y configuración |
| **OpsCenter** | Centraliza items operativos (OpsItems) para investigación |
| **Explorer** | Dashboard operativo con métricas y datos de la cuenta |
| **Fleet Manager** | Gestión de flotas de instancias desde la consola |

---

## Tips para el examen

### CloudWatch

1. **"Monitorizar CPU de EC2"** → CloudWatch (métrica por defecto).
2. **"Monitorizar RAM o disco de EC2"** → CloudWatch Agent (NO disponible por defecto).
3. **"Alarma cuando CPU > 80% durante 5 minutos"** → CloudWatch Alarm.
4. **"Alarma que combine múltiples condiciones"** → Composite Alarm.
5. **"Resolución de métricas de 1 segundo"** → High-Resolution Custom Metrics.
6. **"Dashboard con métricas de múltiples regiones"** → CloudWatch Dashboard (global).

### CloudWatch Logs

7. **"Centralizar logs de múltiples servicios"** → CloudWatch Logs.
8. **"Enviar logs a S3 en tiempo real"** → Subscription Filter → Kinesis Firehose → S3 (NO CreateExportTask).
9. **"Crear alarma basada en patrones en logs"** → Metric Filter → CloudWatch Alarm.
10. **"Analizar logs con queries tipo SQL"** → CloudWatch Logs Insights.
11. **"Enviar logs de EC2"** → CloudWatch Unified Agent.

### CloudTrail

12. **"Quién eliminó el recurso"** → CloudTrail (management events).
13. **"Quién accedió al objeto de S3"** → CloudTrail (data events, NO habilitado por defecto).
14. **"Auditoría de todas las cuentas de la organización"** → Organization Trail.
15. **"Detectar actividad inusual de API"** → CloudTrail Insights.
16. **"Verificar integridad de logs"** → CloudTrail Log File Integrity Validation.
17. **"Analizar logs de CloudTrail con SQL"** → Athena (sobre logs en S3).

### Config

18. **"Verificar que todos los buckets tengan cifrado"** → AWS Config Rule.
19. **"Remediar automáticamente recursos no conformes"** → Config + SSM Automation.
20. **"Vista centralizada de compliance multi-cuenta"** → Config Aggregator.
21. **"Historial de cambios de configuración"** → AWS Config (configuration timeline).
22. **"Config vs CloudTrail"** → Config = "QUÉ configuración tiene el recurso". CloudTrail = "QUIÉN cambió el recurso".

### X-Ray

23. **"Identificar cuellos de botella en microservicios"** → X-Ray.
24. **"Mapa visual de la arquitectura y latencias"** → X-Ray Service Map.
25. **"Tracing distribuido"** → X-Ray.

### Trusted Advisor

26. **"Recomendaciones de mejores prácticas AWS"** → Trusted Advisor.
27. **"Solo 7 checks disponibles"** → Plan Basic/Developer.
28. **"Todos los checks disponibles"** → Plan Business o Enterprise.
29. **"Verificar service limits/cuotas"** → Trusted Advisor (disponible en todos los planes).

### Health Dashboard

30. **"Un servicio AWS está teniendo problemas, afecta a mis recursos?"** → AWS Health Dashboard (Personal).
31. **"Automatizar respuesta ante eventos de mantenimiento de AWS"** → Health Dashboard + EventBridge.

### VPC Flow Logs

32. **"Analizar tráfico rechazado en la VPC"** → VPC Flow Logs.
33. **"Troubleshoot por qué una instancia no se conecta"** → VPC Flow Logs (verificar ACCEPT/REJECT).
34. **"Análisis de Flow Logs con SQL"** → Athena sobre logs en S3.

### Systems Manager

35. **"Acceso a EC2 sin SSH ni bastion"** → Session Manager.
36. **"Almacenar configuraciones y secretos"** → Parameter Store.
37. **"Rotación automática de credenciales de DB"** → Secrets Manager (NO Parameter Store).
38. **"Ejecutar comandos en múltiples instancias"** → Run Command.
39. **"Automatizar parcheo de instancias"** → Patch Manager.
40. **"Remediation automática de Config rules"** → SSM Automation.
