# Conceptos que más fallo - Repaso rápido

---

## AWS DMS (Database Migration Service)

- **Full Load + CDC (Change Data Capture)**: copia datos existentes y luego replica cambios en near-real-time leyendo el transaction log
- **Near-zero downtime**: el source sigue operativo. El único downtime real es el cutover (cambiar la app al target)
- **Caso de uso principal**: migraciones entre motores distintos (Oracle→Aurora, on-prem→cloud, MySQL→PostgreSQL)
- **NO usar DMS** para migrar dentro del mismo cluster Aurora → usar replicación nativa (añadir replica + failover)

## Aurora: Migración Provisioned → Serverless

- **Aurora Serverless v1 vs v2 son arquitecturas distintas**:
  - **v2**: permite mezclar instancias provisioned y serverless en el mismo cluster (replica + failover funciona)
  - **v1**: cluster completamente separado, NO puedes añadir replicas serverless a un cluster provisioned
- **En el examen**: si dice "Aurora Serverless" a secas → asumir v1 → **usar DMS** para migrar con near-zero downtime
- DMS con CDC es la opción segura para migrar **entre arquitecturas distintas de Aurora**
- Snapshot + nuevo cluster = downtime significativo (datos post-snapshot se pierden)
- Cambiar instance class directamente = NO posible entre provisioned y serverless v1

## Data Firehose vs Kinesis Data Streams vs Redshift

- **Kinesis Data Streams**: "tubería con retención" — captura streaming real-time, retiene 1-365d, múltiples consumers leen simultáneamente (Lambda, apps, Firehose, Analytics). No procesa ni entrega por sí solo, necesita consumers.
- **Data Firehose**: "manguera" — entrega serverless near-real-time (mín 60s buffer) a destinos fijos: **S3, Redshift, OpenSearch, Splunk, HTTP endpoint**
  - Puede transformar con Lambda al vuelo
  - Sin retención, solo delivery
- **Redshift**: data warehouse — analytics SQL sobre datos históricos, petabytes, batch
- **Clave examen**: si dice "capture, transform, load streaming into S3/OpenSearch/Splunk" → Firehose
- **Firehose NO necesita Kinesis Streams** — puede recibir datos directo via SDK/API, CloudWatch Logs, IoT, etc.
- Solo usas Streams + Firehose juntos cuando necesitas procesamiento custom real-time Y entrega a destinos
- Flujo con ambos (opcional): Sensores → Kinesis Streams → Firehose → S3 → Redshift

## AWS Glue

- Servicio **serverless de ETL** (Extract, Transform, Load)
- **Crawlers**: escanean datos en S3/RDS/DynamoDB, descubren schema automáticamente
- **Data Catalog**: base de datos central de metadatos (compatible con Athena, Redshift Spectrum, EMR)
- **ETL Jobs**: scripts PySpark/Scala que transforman datos, serverless
- **Job Bookmarks**: mecanismo que recuerda qué datos ya se procesaron
  - **Enabled**: solo procesa datos nuevos desde el último run
  - **Disabled** (default): procesa todo cada vez
  - **Pause**: procesa todo pero no actualiza el bookmark
  - Para S3: trackea por path/timestamp de ficheros
  - Para JDBC: trackea por columna incremental (id, timestamp)
- **Clave examen**: si el problema es "reprocesar datos antiguos" → habilitar Job Bookmark

## IAM, Organizations, SCPs y Multi-cuenta

- **IAM Groups**: agrupan users y les aplicas policies. No puedes adjuntar Roles a Groups.
- **IAM Roles**: credenciales temporales, se asumen (no se adjuntan a users/groups permanentemente)
- **SCPs**: límite máximo de permisos para **cuentas/OUs enteras**, NO para users individuales. No dan permisos, solo restringen.
- **Permissions Boundary**: límite máximo para un user/role específico dentro de una cuenta
- **Permisos efectivos** = intersección de SCP ∩ Permissions Boundary ∩ IAM Policy
- SCPs NO afectan a la Management Account
- **Organizations**: múltiples cuentas, consolidated billing, estructura Root→OUs→Accounts
- **Control Tower**: automatiza Organizations + guardrails + account factory + landing zone
- **Clave examen**: "departments + users + MFA" → IAM Groups + IAM Policy. "Restrict entire accounts" → SCPs
- **Cuándo Organizations**: múltiples equipos, aislar entornos, compliance, >10 personas
- **Cuándo IAM Users solos**: una cuenta, pocos devs, sin requisitos de aislamiento estricto
- **Cross-account access**: IAM Role en cuenta destino + AssumeRole desde cuenta origen (credenciales temporales)
- **Ventaja real de multi-cuenta**: aislamiento total, un error de policy en dev NO puede afectar prod
- **NO necesitas múltiples logins**: un login en Identity Center (SSO) → Switch Role / portal a cualquier cuenta
- **IAM Identity Center** (antes AWS SSO): best practice actual, un portal web, credenciales temporales, sin IAM Users
- CLI: `~/.aws/config` con profiles + `role_arn` + `source_profile` → `aws s3 ls --profile prod`
- **Clave examen**: "centralized access across accounts" / "single sign-on" → IAM Identity Center

## EC2 Billing por Estado

- **pending**: NO cobra
- **running**: SÍ cobra
- **stopping (normal)**: NO cobra
- **stopping (hibernate)**: SÍ cobra (vuelca RAM a EBS, instancia activa)
- **stopped**: NO cobra compute (SÍ cobra EBS)
- **shutting-down / terminated**: NO cobra
- **Reserved Instance terminated**: SÍ sigue cobrando (es un contrato, no una instancia)
- **Spot interrumpida por AWS (stopping)**: NO cobra la hora parcial (culpa de AWS)
- Reserved Instance = contrato de descuento 1-3 años, pagas aunque no haya instancia corriendo

## EC2 Hibernate

- **Decisión INMUTABLE al launch** — no se puede habilitar NI deshabilitar después
- Si necesitas hibernate en instancia existente → **migrar a nueva instancia** con hibernate habilitado
- Hibernate guarda RAM en EBS root → arranque rápido (restaura RAM, como suspender un portátil)
- Requisitos: root EBS encriptado, suficiente espacio para RAM, máx 150GB RAM, máx 60 días hibernando
- Stop normal: pierde RAM → boot lento. Hibernate: restaura RAM → boot rápido
- **Trampa examen**: "enable hibernate" (en existente, imposible) vs "migrate to instance with hibernate" (correcto)

## AWS Storage Gateway

- Bridge entre on-premises y AWS. VM/appliance en tu datacenter que conecta con AWS.
- **File Gateway**: NFS/SMB → S3 (tus apps ven carpeta de red, AWS guarda objetos en S3)
- **Volume Gateway**: iSCSI → S3/EBS snapshots (tus apps ven disco duro, block storage)
  - Cached: datos en S3, cache local | Stored: datos locales, backup a S3
- **Tape Gateway**: iSCSI → S3 Glacier (reemplaza cintas físicas, compatible Veeam/Veritas)
- S3 es object storage, pero File Gateway lo hace parecer file storage desde on-prem
- **Clave examen**: "file protocols/NFS/SMB" → File GW. "iSCSI/block" → Volume GW. "tape/backup software" → Tape GW

## Parameter Store vs Secrets Manager

- **Parameter Store**: config general + secretos, **GRATIS** (standard), SecureString + KMS, jerárquico (/app/prod/db), NO rotación automática
- **Secrets Manager**: solo secretos, **$0.40/secreto/mes**, rotación automática integrada con RDS/Redshift/DocumentDB
- Ambos encriptan con KMS
- **Clave examen**: "cost-effective" + config general → Parameter Store. "Automatic rotation" → Secrets Manager
- OpsCenter NO es para guardar config (es gestión de incidentes)

## DynamoDB: Capacidad y Auto Scaling

- **On-Demand mode**: escala automático, pagas por request, sin gestionar RCU/WCU, más caro
- **Provisioned mode** (default): tú defines RCU/WCU, más barato si tráfico predecible
  - Creado con **Console**: Auto Scaling habilitado por defecto
  - Creado con **CLI**: Auto Scaling **NO habilitado** por defecto → hay que activarlo
- **DAX (DynamoDB Accelerator)**: cache in-memory, reduce latencia de ms a μs, solo para DynamoDB, compatible con DynamoDB API
- **Global Tables**: replicación multi-región para apps globales
- DynamoDB NO puede ser origin de CloudFront
- **Clave examen**: si dice "created with CLI" → Auto Scaling probablemente no está habilitado

## Lambda: Execution Role vs Resource Policy + KMS

- **Execution Role** (IAM Role): qué puede hacer Lambda HACIA FUERA (S3, DynamoDB, KMS, etc.)
- **Resource Policy**: quién puede INVOCAR Lambda DESDE FUERA (S3 trigger, API GW, SNS, cross-account)
- **KMS doble autorización**: necesitas permiso en AMBOS lados (IAM del caller + KMS Key Policy)
- KMS Key Policy Principal debe ser el **Execution Role ARN**, NO el function ARN
  - KMS ve la identidad del caller = el role que Lambda asume, no la función en sí
  - Lambda function ARN no es un IAM principal válido para KMS
- **Clave examen**: "Lambda decrypt KMS" → kms:Decrypt en execution role + KMS key policy grants al execution role

## Cost Explorer vs AWS Budgets

- **Cost Explorer**: analizar costes pasados + forecast futuro. Tiene API (GetCostAndUsage, GetCostForecast). Para: "¿cuánto gasté/gastaré?"
- **AWS Budgets**: alertas de presupuesto. Notifica via SNS/email cuando llegas a un límite. Puede ejecutar acciones (parar instancias). NO tiene API para extraer datos de coste. Para: "avísame si gasto más de $X"
- **Clave examen**: "programmatically access costs" + "forecast" → Cost Explorer API

## AWS Config

- **Auditor 24/7**: registra configuración de recursos, evalúa compliance con reglas, remedia
- **Config Rules**: +300 managed rules predefinidas (required-tags, encrypted-volumes, no-public-ip, etc.)
- **Detecta** recursos NON-COMPLIANT existentes (retrospectivo), no previene
- **Remediación**: puede ejecutar SSM Automation para auto-corregir
- Config vs SCP: Config DETECTA (después), SCP PREVIENE (antes, no detecta existentes)
- Config vs Tag Policies: Config detecta falta de tags, Tag Policies solo estandarizan nombres
- Config vs CloudTrail: Config = compliance de configuración, CloudTrail = quién hizo qué (API calls)
- **Clave examen**: "detect/check non-compliant" + "least effort" → AWS Config rule

## SSL/TLS: Wildcard vs SAN vs SNI

- **Wildcard** (*.dominio.com): solo subdominios del MISMO dominio. No sirve para dominios distintos.
- **SAN** (Subject Alternative Name): múltiples dominios en 1 cert. Pero hay que RE-EMITIR al añadir dominio.
- **SNI** (Server Name Indication): ALB con múltiples certificados en 1 listener. Añadir dominio = subir nuevo cert sin tocar los existentes. ACM gratis.
- CloudFront dedicated IPs = $600/mes por cert (opción pre-SNI, cara)
- **Clave examen**: "multiple different domains" + "without reprovision" + "cost-effective" → SNI en ALB con múltiples certs ACM

## CloudFront Contenido Privado: OAC + Signed URLs/Cookies

- **S3 Presigned URL**: acceso directo a S3, NO pasa por CloudFront, sin CDN. Para subir/bajar 1 archivo rápido.
- **CloudFront Signed URL**: acceso a 1 archivo via CDN, puede restringir por IP/fecha/path
- **CloudFront Signed Cookie**: acceso a MÚLTIPLES archivos via CDN, no cambia URLs (transparente)
- **OAC (Origin Access Control)**: solo CloudFront puede leer S3, bloquea acceso directo al bucket
- **Patrón completo**: OAC (bloquea S3 directo) + Signed URLs/Cookies (controla quién accede via CF)
- Origin Shield = capa extra de CACHE, NO es seguridad
- **Clave examen**: "serve private content via CloudFront only" → OAC + Signed URLs/Cookies

## AWS Direct Connect (DX)

- Conexión **física dedicada** entre on-prem y AWS (no internet). Tarda **semanas/meses** en establecer.
- Velocidades: Dedicated (1/10/100 Gbps, puerto exclusivo), Hosted (50Mbps-10Gbps, puerto compartido)
- **VIFs**: Private VIF (→VPC), Public VIF (→servicios públicos S3 etc.), Transit VIF (→Transit Gateway)
- **DX Gateway**: un solo DX accede a VPCs en múltiples regiones
- **NO tiene encriptación nativa** — añadir VPN sobre DX si se necesita encriptar
- **HA**: 2 locations × 2 conexiones, o DX + VPN Site-to-Site como backup económico
- **Clave examen**: "consistent latency" / "high bandwidth" + on-prem → DX. "Quickly"/"immediately" → VPN (DX tarda meses)

## EC2 Placement Groups

- **Cluster**: misma AZ, mismo rack, latencia ultra-baja, 10Gbps. Para HPC, ML training. Si rack falla, todas caen.
- **Spread**: cada instancia en rack distinto, multi-AZ, máx 7 instancias/AZ. Para apps críticas pequeñas. Máxima disponibilidad.
- **Partition**: grupos aislados de fallo, multi-AZ, hasta 7 particiones/AZ, sin límite instancias. Para Hadoop, Kafka, Cassandra.
- **Clave examen**: "HPC" + "low-latency" + "tightly-coupled" → Cluster placement group (1 sola AZ)
- Enhanced Networking + Cluster placement = máximo rendimiento de red entre instancias

## VPC Endpoints: Gateway vs Interface

- **Gateway Endpoint**: entrada en route table, GRATIS, solo **S3 y DynamoDB**
- **Interface Endpoint (PrivateLink)**: crea ENI con IP privada, cuesta ~$7.2/mes + data, soporta +200 servicios
- S3 soporta AMBOS tipos. Usar Gateway (gratis) salvo que necesites acceso from on-prem via VPN/DX
- NAT Gateway también funciona pero es lo más caro (~$32/mes + $0.045/GB)
- **Clave examen**: S3/DynamoDB + "cost-efficient" + subnet privada → Gateway Endpoint siempre

## S3 Event Notifications

- **Destinos válidos**: SQS, SNS, Lambda, EventBridge. **NO**: Amazon MQ, Kinesis
- Eventos principales: `s3:ObjectCreated:*`, `s3:ObjectRemoved:*`, `s3:ObjectRestore:*`, `s3:Replication:*`
- **s3:ObjectRemoved:Delete** = borrado permanente de una versión específica (con version ID)
- **s3:ObjectRemoved:DeleteMarkerCreated** = solo crea delete marker (esconde objeto, no lo borra)
- **Clave examen**: "permanently deleted" → `s3:ObjectRemoved:Delete`, NO `DeleteMarkerCreated`
- `s3:ObjectAdded:*` NO existe → el correcto es `s3:ObjectCreated:*`
- Amazon MQ (RabbitMQ/ActiveMQ gestionado) NO es destino de S3 events

## CloudFormation Attributes y Helper Scripts

- **CreationPolicy**: espera señal (cfn-signal) antes de marcar recurso como COMPLETE. Caso: "espera a que mi software esté listo"
- **DependsOn**: solo garantiza orden de creación, NO que el software dentro funcione
- **UpdatePolicy**: gestiona rolling updates en ASGs, no creación inicial
- **UpdateReplacePolicy**: qué hacer con recurso viejo al reemplazar (Delete/Retain/Snapshot)
- **DeletionPolicy**: qué hacer al borrar stack (Delete/Retain/Snapshot)
- Helper scripts (se ejecutan dentro de EC2):
  - **cfn-init**: lee metadata del template, instala paquetes y configura
  - **cfn-signal**: envía señal a CloudFormation ("estoy listo" / "fallé") — usado con CreationPolicy
  - **cfn-hup**: daemon que detecta cambios en metadata y re-ejecuta cfn-init
- **Clave examen**: "ensure components running before stack proceeds" → CreationPolicy + cfn-signal

## EC2 Instance Limits (vCPU-based)

- El límite ya NO es por número de instancias, es por **vCPUs totales por familia por región**
- Default típico: 64 vCPUs On-Demand para instancias Standard (A, C, D, H, I, M, R, T, Z)
- El límite es por **región**, NO por AZ
- Para aumentar: Service Quotas → EC2 → Request increase
- Error típico: `InstanceLimitExceeded`

## RDS Storage Auto Scaling

- **Existe y es real** — monitoriza espacio libre, escala automáticamente cuando queda poco (5 min)
- Requiere configurar un **Maximum Storage Threshold**
- **Solo escala hacia arriba, nunca reduce** — si sube a 500GB por pico, pagas 500GB para siempre
- Pausa de 6h entre escalados, incremento mínimo de 10%
- **No es default porque**: coste impredecible, enmascara problemas (logs descontrolados, datos sin purgar), storage irreversible
- **Clave examen**: "LEAST operational overhead" + problema de capacidad → auto scaling siempre

## NACLs vs Security Groups

- **Security Groups = STATEFUL**: si permites inbound, la respuesta outbound es automática
- **NACLs = STATELESS**: necesitas reglas explícitas para inbound Y outbound
- **Ephemeral ports (32768-65535)**: las respuestas del servidor salen por estos puertos, NO por el puerto del servicio
- Para permitir HTTPS entrante en una NACL necesitas:
  - Inbound: TCP 443 desde 0.0.0.0/0
  - Outbound: TCP 32768-65535 a 0.0.0.0/0 (para la respuesta)
- NACLs se evalúan en **orden numérico de regla** (primera coincidencia gana)
- Security Groups evalúan **todas las reglas juntas** (solo ALLOW, sin orden)
- SG aplica a nivel de ENI (instancia), NACL aplica a nivel de subnet
- **Default NACL**: permite todo (no suele ser el problema en preguntas)
- **Non-default / custom NACL**: deniega todo por defecto → hay que configurar inbound + outbound
- **Default SG**: permite todo outbound, deniega todo inbound → añadir regla inbound
- **NACLs en la vida real**: rara vez se tocan, se usan para bloquear IPs específicas (SGs no pueden hacer DENY) o compliance
- **Clave examen**: si mencionan "non-default NACL" o "blocks all" → siempre necesitas reglas en ambas direcciones
- **Evaluación NACL**: reglas en ORDEN NUMÉRICO, primera coincidencia gana. Un ALLOW en rule 100 gana sobre DENY en rule 200
- Rule * (asterisco) = default DENY, siempre la última
- Truco: buscar la regla con número más bajo que coincida con el tráfico → esa decide

