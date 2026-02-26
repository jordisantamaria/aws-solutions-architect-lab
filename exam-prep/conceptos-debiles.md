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

## Instance Store vs EBS como Root Volume

- **EBS-Backed**: root en EBS, puede stop/start, snapshots, datos persisten al stop. Terminate borra por default (configurable).
- **Instance Store-Backed**: root en disco local del host, NO puede hacer stop (solo terminate), NO snapshots, datos se PIERDEN al terminar o si host falla.
- Instance Store como volumen adicional: para cache, temp files, scratch data, altísimo IOPS (NVMe). NUNCA para datos no reproducibles.
- **Clave examen**: "Instance Store-Backed AMI" + "terminate" → datos eliminados permanentemente

## Tipos de EBS

- **SSD**: gp2/gp3 (general, boot), io1/io2 (provisioned IOPS, DBs grandes, multi-attach solo io)
- **HDD**: st1 (throughput optimized, big data), sc1 (cold, datos fríos). HDD NO puede ser boot volume.
- **Magnetic** (standard): legacy, el más barato por GB, acceso infrecuente, puede ser boot volume
- "Spot volumes" NO existe (Spot es tipo de instancia). "SR-IOV volumes" NO existe (SR-IOV es networking).
- Multi-attach: solo io1/io2, solo misma AZ (no multi-AZ). gp3 NO soporta multi-attach.
- **IOPS ratio**: io1 = 50 IOPS/GB, io2 = 500 IOPS/GB. Fórmula: Max IOPS = GB × ratio.
- **Queue length**: SSD → low queue (baja latencia). HDD → high queue (máximo throughput).
- io1 mínimo 100 IOPS, máximo absoluto 64,000. io2 Block Express hasta 256,000.

## S3 vs EFS vs FSx vs EBS

- **S3**: object storage, HTTP API, NO soporta NFS/SMB, NO se monta como filesystem
- **EFS**: NFS v4, Linux, multi-AZ, miles de EC2 simultáneas, serverless, directorios reales
- **FSx Windows**: SMB, Windows, Active Directory
- **FSx Lustre**: HPC, Linux, parallel filesystem de alto rendimiento
- **EBS**: block storage, 1 EC2 (multi-attach io solo misma AZ)
- **Clave examen**: "NFS" + "Linux" + "multiple servers" → EFS. "SMB" + "Windows" → FSx Windows

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

## RDS: Multi-AZ (Standby) vs Read Replica

- **Multi-AZ Standby**: alta disponibilidad. Replicación SÍNCRONA (0 data loss), failover AUTOMÁTICO (~60-120s), NO puedes leer de ella, misma región otra AZ.
- **Read Replica**: escalar lecturas. Replicación ASÍNCRONA (puede haber lag), promote MANUAL, SÍ puedes leer, puede estar en otra región.
- Multi-AZ: endpoint DNS no cambia tras failover. Read Replica: endpoint cambia al promover.
- Aurora combina ambos: replicas legibles + failover automático + hasta 15 replicas.
- **Clave examen**: "AZ outage" + "automatic failover" → Multi-AZ. "Scale reads" → Read Replica.

## Aurora Failover

- **Con replicas**: flips CNAME del endpoint → replica se promueve a primary (~30s). Siempre CNAME, nunca A record.
- **Sin replicas (single instance)**: crea nueva instancia en **otra AZ primero**, si no puede → AZ original (~10-15 min)
- Aurora usa CNAME, no A record. Connection string no cambia tras failover.

## RDS Stop vs Snapshot+Terminate

- **RDS Stop**: no pagas compute pero auto-reinicia después de **7 días máximo**. Sigues pagando storage.
- **Snapshot + Terminate**: no pagas compute ni storage de instancia. Solo snapshot storage ($0.05/GB). Restauras cuando necesitas.
- Para DBs de uso intermitente (testing, dev) → Snapshot + Terminate es más cost-effective
- Restaurar desde snapshot tarda unos minutos

## RDS: Basic vs Enhanced Monitoring

- **Basic** (gratis, hypervisor): CPU Utilization, Database Connections, Freeable Memory, IOPS, Latency, Swap — ve desde "fuera"
- **Enhanced** (extra, agente dentro del SO): OS processes, RDS child processes, CPU por core, memory breakdown, file system — ve desde "dentro"
- Truco: si suena a "sistema operativo" o "procesos" → Enhanced. Si suena a "métrica general de DB" → Basic.
- Enhanced explica el POR QUÉ (qué proceso usa la CPU), Basic solo el QUÉ (CPU al 90%)

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

## ALB Access Logs + Monitoring

- **Access Logs**: DESHABILITADOS por defecto. Se habilitan en ALB attributes → van a S3 cada 5 min (.gz)
  - Contienen: client IP, latencias, status codes, request URL, user-agent, por cada request
- **CloudWatch Metrics**: habilitadas por defecto. Métricas AGREGADAS (RequestCount, ResponseTime). No por request.
- **CloudTrail**: registra quién modificó el ALB (API management calls), NO requests HTTP de clientes.
- **X-Ray**: distributed tracing entre servicios, no access logs del ALB.
- **Clave examen**: "client IP" + "latencies" + "every request" → ALB access logs (S3)

## AWS Config

- **Auditor 24/7**: registra configuración de recursos, evalúa compliance con reglas, remedia
- **Config Rules**: +300 managed rules predefinidas (required-tags, encrypted-volumes, no-public-ip, etc.)
- **Detecta** recursos NON-COMPLIANT existentes (retrospectivo), no previene
- **Remediación**: puede ejecutar SSM Automation para auto-corregir
- Config vs SCP: Config DETECTA (después), SCP PREVIENE (antes, no detecta existentes)
- Config vs Tag Policies: Config detecta falta de tags, Tag Policies solo estandarizan nombres
- Config vs CloudTrail: Config = compliance de configuración, CloudTrail = quién hizo qué (API calls)
- **Clave examen**: "detect/check non-compliant" + "least effort" → AWS Config rule

## CloudTrail Defaults

- Habilitado por defecto en todas las cuentas
- Logs encriptados con **SSE-S3 (AES-256) por defecto** — no necesitas configurar nada
- Management events capturados por defecto. Data events son opcionales.
- Destino: S3 (no Glacier directamente). CloudTrail usa AES-256, no AES-128.
- Opcional: SSE-KMS (audit trail de quién lee logs), multi-region trail, CloudWatch Logs integration

## Service Health Dashboard vs Personal Health Dashboard

- **Service Health Dashboard**: estado GENERAL de todos los servicios AWS, público, no específico de tu cuenta
- **Personal Health Dashboard (PHD)**: eventos que afectan a TUS recursos específicos (retiro de hardware, mantenimiento, degradación)
- PHD se integra con EventBridge para automatizar notificaciones
- **Clave examen**: "events affecting YOUR resources" / "upcoming events" → Personal Health Dashboard + EventBridge + SNS

## Amazon WorkSpaces + Directory Services

- **WorkSpaces**: escritorios virtuales en la nube (DaaS), Windows/Linux, reemplazan PCs físicos
- **AWS Directory Service**: integra Active Directory con AWS
  - AD Connector: proxy a AD on-prem (no guarda datos en AWS)
  - AWS Managed Microsoft AD: AD completo en AWS con trust a on-prem
- **Patrón típico**: VPN (conecta redes) + Directory Service (autenticación AD) + WorkSpaces (escritorios)
- ClassicLink = deprecated, conectaba EC2-Classic con VPC (ya no relevante)

## IAM: Autenticación vs Autorización

- **Autenticación** (quién eres): Console = password, CLI/API = Access Keys, EC2 = IAM Role
- **Autorización** (qué puedes hacer): IAM Policies
- IAM User nuevo: NO tiene password, NO tiene access keys, NO tiene permisos → no puede hacer nada
- Para API calls se necesitan AMBOS: Access Keys (autenticación) + IAM Policy (autorización)
- Best practice: IAM Identity Center (SSO) con credenciales temporales en vez de access keys permanentes
- MFA es extra de seguridad, no requisito para API calls

## S3 Encryption: SSE-S3 vs SSE-KMS vs SSE-C

- **SSE-S3**: AWS gestiona todo, gratis, sin audit trail, sin control de keys. Default.
- **SSE-KMS**: KMS gestiona master key, envelope encryption, audit trail en CloudTrail, rotación automática configurable, $1/key/mes
- **SSE-C**: tú proporcionas la key en cada request, sin audit trail, rotación manual, si pierdes key pierdes datos
- **Envelope encryption**: master key (nunca sale de KMS) → encripta data key → encripta datos. Cada objeto su propia data key.
- **Rotación KMS**: crea nuevo key material, mantiene viejo para decrypt, key ID no cambia, transparente
- **Audit trail**: solo SSE-KMS genera logs en CloudTrail (quién, qué key, cuándo)
- **Clave examen**: "envelope encryption" + "audit trail" + "key rotation" → SSE-KMS

## Clases de S3 y Retrieval Times

- **ms retrieval**: Standard, Intelligent-Tiering, Standard-IA, One Zone-IA, Glacier Instant
- **min-hrs**: Glacier Flexible (1min-12hrs)
- **12-48hrs**: Glacier Deep Archive
- **One Zone-IA**: 20% más barato que Standard-IA, 1 sola AZ, para datos **reproducibles**
- **Intelligent-Tiering**: auto-mueve entre tiers, cobra monitoring fee. Útil si NO sabes el patrón de acceso.
- Lifecycle rules se pueden aplicar a **prefixes específicos** (cada prefix distinta clase)
- **Clave examen**: "reproducible" + "ms retrieval" + "cost-effective" → One Zone-IA. "No retrieval requirement" → Glacier

## SSL/TLS: Wildcard vs SAN vs SNI

- **Wildcard** (*.dominio.com): solo subdominios del MISMO dominio. No sirve para dominios distintos.
- **SAN** (Subject Alternative Name): múltiples dominios en 1 cert. Pero hay que RE-EMITIR al añadir dominio.
- **SNI** (Server Name Indication): ALB con múltiples certificados en 1 listener. Añadir dominio = subir nuevo cert sin tocar los existentes. ACM gratis.
- CloudFront dedicated IPs = $600/mes por cert (opción pre-SNI, cara)
- **Clave examen**: "multiple different domains" + "without reprovision" + "cost-effective" → SNI en ALB con múltiples certs ACM

## Dónde importar certificados SSL/TLS

- **ACM (AWS Certificate Manager)**: servicio principal, genera certs gratis + importa de terceros, renovación automática
- **IAM Certificate Store**: método legacy, solo importar (no genera), sin renovación auto, para regiones sin ACM
- Los dos son válidos para importar certs de CA externas
- CloudFront USA certs pero no los almacena (los obtiene de ACM/IAM). Certs para CF deben estar en **us-east-1**
- S3 NO es un servicio de gestión de certs, no se puede asociar con ALB/CloudFront

## S3 Transfer Acceleration vs Snow Family

- **Transfer Acceleration**: usa edge locations + AWS backbone para acelerar uploads cross-continent. $0.04/GB extra.
  - Mejora throughput efectivo (reduce latencia/packet loss), NO aumenta tu ancho de banda
  - Cross-continent: 130-500% mejora. Cerca del bucket: ~0% (no vale la pena)
  - Solo para uploads (downloads → CloudFront)
  - No sirve para migraciones masivas, el cuello de botella es el volumen no la ruta
- **Snowball Edge**: dispositivo físico 80TB, envío por correo, ~1-2 semanas total
- **Snowcone**: 8-14TB, 2kg, entornos remotos
- **Snowmobile**: 100PB, camión literal, exabytes
- **Regla**: si tarda >1 semana por internet → Snowball. Calcular: TB × 8000 / Mbps = segundos
- 250TB por 100Mbps = 231 días → 4 Snowballs = 1-2 semanas
- Direct Connect tarda meses en establecer, no sirve para migración urgente
- **Snowball NO importa directamente a Glacier** — solo a S3 Standard, luego lifecycle a Glacier
- **S3 Gateway Endpoint ≠ Storage Gateway**: endpoint es ruta de red en VPC, Storage Gateway es VM/appliance on-prem
- "Tape backup" on-prem → **Tape Gateway** (Storage Gateway). Software de backup no cambia.
- Glacier Deep Archive ($0.00099/GB) es 4x más barato que Flexible Retrieval ($0.004/GB)
- **Clave examen**: "10 years" + "once/twice a year" + "cost-effective" → Glacier Deep Archive

## DataSync vs Storage Gateway

- **DataSync**: MOVER datos de A a B (migración o sync recurrente). Rápido (10Gbps), incremental, scheduling. Para: "migrar 50TB a S3"
- **Storage Gateway**: USAR AWS storage desde on-prem continuamente. Bridge permanente, cache local. Para: "mis apps necesitan acceso a S3 cada día"
- "Tape backup continuo" → Storage Gateway (Tape). "Migrar datos existentes" → DataSync
- DataSync soporta: on-prem NFS/SMB → S3/EFS/FSx, y S3↔S3 cross-region/account
- DataSync puede ir por **internet** (default) o por **Direct Connect** (via service/VPC endpoint, red privada)
- Si ya tienen DX → DataSync over service endpoint (no por internet)

## AWS DRS (Elastic Disaster Recovery) + Estrategias DR

- **DRS**: agente en servers on-prem, replicación continua block-level a staging area en AWS (EBS). Sin EC2 corriendo. Al desastre → lanza EC2 desde volumes.
- RPO: segundos (replicación continua). RTO: minutos (lanzar EC2s)
- **4 estrategias DR** (de barato/lento a caro/rápido):
  1. **Backup & Restore**: datos en S3/Glacier, nada corriendo. RPO/RTO: horas. 💰
  2. **Pilot Light**: core mínimo replicado (datos), sin EC2 corriendo. RPO: seg, RTO: min/hrs. 💰💰 ← DRS hace esto
  3. **Warm Standby**: versión reducida corriendo en AWS, escala al hacer DR. RPO: seg, RTO: min. 💰💰💰
  4. **Multi-site Active/Active**: todo corre en ambos sitios. RPO/RTO: ~0. 💰💰💰💰
- **Clave examen**: "cost-effective" + "RPO seconds" + "RTO minutes/hours" → DRS (Pilot Light)

## Servicios de Migración: Discovery vs MGN vs DRS

- **Application Discovery Service**: solo DESCUBRE inventario (CPU, RAM, dependencias). NO migra ni replica nada. Para planificar.
- **MGN (Migration Service)**: lift-and-shift de VMs a AWS. Replication Agent, replicación continua, test instances, cutover. Para MIGRAR permanentemente.
- **DRS (Disaster Recovery)**: replicación continua para DR. On-prem sigue siendo primario. Para BACKUP de emergencia.
- MGN y DRS usan misma tecnología (block-level replication) pero propósito distinto: MGN=mudar, DRS=backup.
- **DataSync**: migra DATOS (archivos), no VMs. **DMS**: migra BASES DE DATOS. **VM Import/Export**: manual, más downtime.
- **Clave examen**: "lift-and-shift" + "minimize downtime" + "VMs" → MGN

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
- **DX Gateway**: recurso global, conecta 1 DX con múltiples VPCs/TGWs sin conexiones físicas adicionales
- **3 formas de conectar DX con VPCs**:
  1. DX + Private VIF → 1 VPC (simple, no escala)
  2. DX + DX GW + Private VIFs → múltiples VPCs (límite 10, VPCs no hablan entre sí)
  3. DX + DX GW + Transit VIF + TGW → todas las VPCs/cuentas (escala, transitivo) ← best practice
- **Transit Gateway**: hub central, conecta VPCs/VPNs/DX, transitivo, multi-cuenta con RAM, escala a miles
- VPC Peering NO es transitivo, NO se asocia con DX Gateway, no escala (n*(n-1)/2 peerings)
- **Clave examen**: "multiple accounts" + "existing DX" + "least overhead" → DX Gateway + Transit Gateway
- **Multi-region**: 1 TGW por región + peering entre TGWs. Tráfico por AWS backbone, no internet.
- TGW soporta: VPCs, VPN, DX (via DX GW), peering inter-region. Escala a miles de attachments.
- VPN CloudHub: solo conecta sites remotos via 1 VGW, no escala para cientos de VPCs.
- **Clave examen**: "hundreds of VPCs" + "multiple regions" + "single gateway" → Transit Gateway per region + peering

## EC2 Placement Groups

- **Cluster**: misma AZ, mismo rack, latencia ultra-baja, 10Gbps. Para HPC, ML training. Si rack falla, todas caen.
- **Spread**: cada instancia en rack distinto, multi-AZ, máx 7 instancias/AZ. Para apps críticas pequeñas. Máxima disponibilidad.
- **Partition**: grupos aislados de fallo, multi-AZ, hasta 7 particiones/AZ, sin límite instancias. Para Hadoop, Kafka, Cassandra.
- **Clave examen**: "HPC" + "low-latency" + "tightly-coupled" → Cluster placement group (1 sola AZ)
- Enhanced Networking + Cluster placement = máximo rendimiento de red entre instancias
- **ENI** (Elastic Network Interface): interfaz básica, toda EC2 tiene una
- **ENA** (Elastic Network Adapter): enhanced networking, hasta 100Gbps, SR-IOV, NO tiene OS-bypass
- **EFA** (Elastic Fabric Adapter): ENA + OS-bypass (apps hablan directo con hardware de red), solo Linux, para HPC/MPI/ML
- **Clave examen**: "OS-bypass" / "HPC" + "Linux" → EFA. "HPC" + "Windows" → ENA (EFA OS-bypass no funciona en Windows).
- **Intel 82599 VF**: legacy (10Gbps), para instancias antiguas (C3, R3). ENA es el reemplazo moderno.
- EFA en Windows funciona solo como ENA normal (sin OS-bypass), no tiene sentido usarlo.

## SQS Standard vs FIFO

- **Standard**: throughput ilimitado, at-least-once (PUEDE duplicar), best-effort ordering
- **FIFO**: exactly-once processing (SIN duplicados), orden garantizado, max 300 msg/s (3000 con batching)
- Standard duplica porque replica en múltiples servers y a veces entrega 2 copias
- FIFO previene con Deduplication ID (descarta mismo mensaje en 5 min)
- Visibility timeout: tiempo que mensaje es invisible tras ser leído. Aumentarlo reduce duplicados por timeout, pero NO los inherentes de Standard
- **Clave examen**: "processed twice" / "duplicate" → SQS FIFO
- **DLQ (Dead Letter Queue)**: cola donde van mensajes tras N fallos (maxReceiveCount). Opcional, funciona igual en Standard y FIFO.
- Fallo → mensaje vuelve a la cola (reintento legítimo, NO es duplicado). Tras N fallos → DLQ.
- FIFO elimina entregas duplicadas simultáneas, NO reintentos legítimos tras fallo.
- FIFO detecta duplicados via: Deduplication ID (tú lo pones) o Content-based (SHA-256 del body, automático). Ventana: 5 minutos.

## AWS AppSync

- NO es solo GraphQL — es un servicio de **data aggregation y orchestration** para múltiples data sources
- **Pipeline Resolvers**: encadenan funciones que conectan DIRECTAMENTE a DynamoDB (sin Lambda), en secuencia o paralelo
- Una request puede leer/escribir de múltiples tablas DynamoDB automáticamente
- Serverless, sin código de orquestación, "operationally efficient"
- **Clave examen**: "multiple DynamoDB tables" + "retrieve and write" + "operationally efficient" → AppSync pipeline resolvers

## EKS Scaling

- **HPA (Horizontal Pod Autoscaler)**: más pods/réplicas. Para: web servers, APIs, microservicios. Necesita Metrics Server.
- **VPA (Vertical Pod Autoscaler)**: más CPU/RAM al pod existente. Requiere restart del pod. Para: DBs, apps que no escalan horizontalmente.
- **Cluster Autoscaler**: más/menos EC2 nodes según pods pending. Legacy.
- **Karpenter**: como Cluster Autoscaler pero mejor, más rápido, elige instancia óptima. AWS lo recomienda.
- Horizontal = más copias. Vertical = más potente.
- **Clave examen**: "more traffic/requests" → HPA. "more resources for pod" → VPA. "no room for pods" → Karpenter/Cluster Autoscaler.

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

## ASG Scaling Policies

- **Target Tracking**: "mantén CPU al 50%". AWS gestiona todo (alarmas, adjustments). El más simple.
- **Step Scaling**: TÚ defines alarmas, thresholds y múltiples escalones (CPU 60%→+1, 80%→+3, 90%→+5). "Set of adjustments".
- **Simple Scaling**: un threshold, una acción, cooldown. Legacy.
- **Scheduled**: a hora/fecha específica (patrones predecibles).
- **Clave examen**: "set of adjustments" + "specify thresholds" + "CloudWatch alarms" → Step Scaling. "Maintain metric at X" → Target Tracking.

## ASG Lifecycle Hooks

- Permiten pausar launch o terminate para ejecutar acciones antes de completar
- **Launch**: `Pending:Wait`. **Terminate**: `Terminating:Wait` (NO confundir)
- Evento correcto para actuar durante terminación: `EC2 Instance-terminate Lifecycle Action` (instancia aún viva)
- `EC2 Instance Terminate Successful` = ya terminada, demasiado tarde
- Patrón: Lifecycle hook → EventBridge → Lambda → CloudWatch Agent (push logs) → CompleteLifecycleAction
- Timeout configurable hasta 48h

## VPC DNS Settings

- **DNS Resolution** (enableDnsSupport): ¿la VPC puede resolver DNS? Default: enabled en todas las VPCs.
- **DNS Hostnames** (enableDnsHostnames): ¿las EC2 reciben hostname DNS público?
  - Default VPC: enabled. Custom VPC: **disabled por defecto** ← truco del examen
- Para que EC2 tenga DNS hostname: DNS Resolution ON + DNS Hostnames ON + IP pública
- Route 53 no controla si una EC2 recibe hostname (es servicio DNS externo)

## NAT Gateway

- NAT Gateway va en **public subnet**, EC2s en **private subnet**
- Private subnet route: `0.0.0.0/0 → NAT Gateway`
- Permite tráfico de SALIDA a internet, bloquea tráfico de ENTRADA desde internet
- NAT GW necesita EIP y acceso al IGW (por eso va en public subnet)
- EIP en EC2 = accesible desde internet (NO es lo mismo que NAT GW)

## Servicios AI/ML para texto

- **Textract**: extrae texto de PDF/imágenes (OCR). Solo extrae, no analiza.
- **Comprehend**: NLP sobre texto — sentimiento, entidades, PII genérico. NO específico médico.
- **Comprehend Medical**: detecta PHI (Protected Health Information) médico — HIPAA compliance.
- **Transcribe**: audio → texto (speech-to-text). NO sirve para PDFs.
- **Polly**: texto → audio. **Rekognition**: imágenes/vídeo. **Macie**: detecta PII en S3.
- "Textract Medical" NO existe como servicio.
- **Clave examen**: PDF + PHI médico → Textract (extraer) + Comprehend Medical (identificar PHI)
- **Evaluación NACL**: reglas en ORDEN NUMÉRICO, primera coincidencia gana. Un ALLOW en rule 100 gana sobre DENY en rule 200
- Rule * (asterisco) = default DENY, siempre la última
- Truco: buscar la regla con número más bajo que coincida con el tráfico → esa decide

## Route 53: Alias vs CNAME

- **CNAME**: mapea nombre DNS → otro nombre DNS. **NO funciona en zone apex** (dominio raíz como `ejemplo.com`)
- **Alias**: extensión propietaria de Route 53. Mapea nombre DNS → recurso AWS. **SÍ funciona en zone apex**
- Alias se crea como tipo A (IPv4) o AAAA (IPv6) con flag "Alias" activado
- **Alias es gratis** (no cobran queries), CNAME sí cobra
- Alias soporta: ALB, NLB, CloudFront, S3 website, Elastic Beanstalk, API Gateway, Global Accelerator
- Alias **NO soporta**: EC2 DNS name → usar CNAME o IP directa
- **Zone apex** = naked domain = root domain (`ejemplo.com` sin www)
- ALB no tiene IP fija → un A record normal con IP no sirve
- **Clave examen**: ves "zone apex" o "root domain" → la respuesta siempre es **Alias record (tipo A)**
- Ves recurso AWS como destino → preferir Alias (gratis + apex)
- CNAME solo cuando el destino es externo (no AWS)

## ALB con targets on-premises + Weighted Target Groups

- Target Groups tienen tipo **instance** (EC2) o tipo **ip** (cualquier IP alcanzable)
- Con tipo **ip** puedes registrar IPs de servidores on-premises si hay Direct Connect o VPN
- **ALB soporta Weighted Target Groups**: una regla del listener puede reenviar a múltiples target groups con pesos distintos (ej: 50/50)
- **NLB NO soporta** weighted forwarding a múltiples target groups → solo ALB
- Para repartir tráfico con pesos entre on-prem y AWS: ALB Weighted TG o Route 53 Weighted routing
- Route 53 **Failover** = activo/pasivo (backup), NO reparte tráfico proporcionalmente
- Route 53 **Weighted** = reparte tráfico por porcentaje entre endpoints
- **Clave examen**: migración gradual on-prem → AWS con % de tráfico → ALB Weighted TG + Route 53 Weighted

## SSM Run Command vs CodePipeline

- **Run Command** (parte de Systems Manager): ejecuta comandos/scripts en EC2 **sin SSH/RDP**, usa SSM Agent
- **CodePipeline**: CI/CD pipeline (Source → Build → Deploy). Para desplegar aplicaciones, no para configurar instancias
- **EC2Config**: servicio legacy de Windows, solo configuración inicial. No es para comandos remotos
- **AWS Config**: audita compliance de recursos AWS. No ejecuta nada
- **Clave examen**: "sin SSH/RDP" + "configurar instancias" + "Systems Manager" → **Run Command**

## WAF vs Network Firewall vs NACLs

- **WAF**: capa 7 (HTTP). Bloqueo por **país** (geo-match), IPs, SQLi, XSS, rate limiting. Se asocia a ALB/CloudFront/API Gateway
- **Network Firewall**: capa 3-4. Inspección profunda (IDS/IPS), filtrado de **dominios salientes**, stateful/stateless rules. Más caro y complejo
- **NACLs**: capa 3-4. Reglas simples IP/puerto por subnet. Límite ~20 reglas. No soporta filtrado por país
- NACLs no pueden bloquear un país → miles de rangos IP cambiantes, límite de reglas insuficiente
- **Clave examen**: "bloquear país" → **WAF geo-match** siempre
- **Network Firewall es correcto cuando**: filtrado egress por dominio, tráfico no-HTTP, IDS/IPS, inspección entre VPCs
- Regla rápida: WAF = proteger apps web (ingress HTTP). Network Firewall = controlar tráfico de red (egress, no-HTTP, IDS/IPS)

## Conectividad entre VPCs y servicios

- **VPC Endpoint**: VPC → servicio AWS (S3, DynamoDB, SSM). NO conecta VPC con VPC
- **VPC Peering**: VPC ↔ VPC directa (misma o distinta región). Requiere actualizar **route tables** en ambas VPCs
- **Transit Gateway**: hub central para conectar muchas VPCs + on-prem (hub-and-spoke)
- **NAT Gateway**: subnet privada → Internet. NO es para conectar VPCs
- **Egress-only IGW**: NAT Gateway pero para IPv6. Tampoco conecta VPCs
- **Clave examen**: "transferir datos entre VPCs sin Internet" → VPC Peering + actualizar route tables

## EBS Snapshots durante uso

- Snapshots son **asíncronos**: el volumen sigue disponible para lectura Y escritura durante el snapshot
- Se puede detach/attach el volumen durante el snapshot sin problemas
- El snapshot captura el estado **point-in-time** del momento que se inicia
- Primer snapshot = completo. Siguientes = incrementales (solo bloques cambiados)
- Se guardan en S3 (gestionado por AWS, no visible en tus buckets)

## Trusted Advisor Service Limits

- Monitoriza uso actual vs cuotas de servicios AWS
- Requiere **Business support plan** mínimo (Developer NO incluye checks completos)
- Los datos se quedan **stale** → necesitas refrescar con `RefreshTrustedAdvisorCheck` API (Lambda cada 24h)
- `DescribeTrustedAdvisorChecks` solo **lista** checks disponibles, NO los ejecuta
- Para notificaciones: EventBridge captura eventos de TA → SNS notifica
- **AWS Config** NO monitoriza service quotas → Config es para compliance de configuración de recursos

