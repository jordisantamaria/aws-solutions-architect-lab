# Mapa Conceptual - AWS SAA-C03

---

## 1. NETWORKING

### VPC Basics
- VPC = red virtual, regional. Subnets = single AZ
- CIDR: tú defines el rango IP (ej: 10.0.0.0/16)
- Route table `local` = tráfico interno VPC (automático, no se borra)
- `0.0.0.0/0` = default route (todo Internet)

### Acceso a Internet
| Servicio | Qué hace | Dirección |
|---|---|---|
| **Internet Gateway** | Conecta VPC a Internet | Bidireccional |
| **NAT Gateway** | Salida IPv4 sin entrada | Solo outbound. ~$32/mes |
| **NAT Instance** | Igual pero EC2 manual | Más barato (t3.nano ~$3/mes) |
| **Egress-Only IGW** | Salida IPv6 sin entrada | Solo IPv6. Gratis |

### Security Groups vs NACLs
| | Security Group | NACL |
|---|---|---|
| Nivel | Instancia | Subnet |
| Stateful | ✅ (retorno automático) | ❌ (regla explícita para retorno) |
| Default | Deny all inbound, Allow all outbound | Allow all |
| Reglas | Solo ALLOW | ALLOW y DENY |
| Evaluación | Todas las reglas | Orden numérico (primera coincidencia gana) |

### VPC Endpoints
- **Gateway Endpoint**: S3 y DynamoDB. Gratis. Se configura en route table
- **Interface Endpoint**: otros servicios AWS. ~$7.2/mes. Usa ENI + Security Group
- VPC Endpoints NO conectan VPC con VPC

### Conectividad VPC-VPC y on-prem
| Conectar | Herramienta |
|---|---|
| 2 VPCs | VPC Peering (+ actualizar route tables) |
| Muchas VPCs (hub-spoke) | Transit Gateway |
| VPC → on-prem (rápido) | Site-to-Site VPN (minutos, por Internet) |
| VPC → on-prem (dedicado) | Direct Connect (semanas, cable físico) |

### Load Balancers
| Tipo | Capa | Caso de uso |
|---|---|---|
| **ALB** | 7 (HTTP) | Web apps, routing por path/host, weighted target groups |
| **NLB** | 4 (TCP/UDP) | Ultra baja latencia, IP estática, millones de requests |
| **GLB** | 3 (GENEVE) | Firewalls, appliances de red |
- ALB soporta targets por IP (on-prem via Direct Connect)
- NLB soporta HTTP health checks (aunque opera en capa 4)
- Sticky sessions: cookie que fija usuario a una instancia. Desactivar si app es stateless

### Route 53
- **Alias** (Route 53 propio): funciona en zone apex, gratis, apunta a recursos AWS
- **CNAME**: NO funciona en zone apex, cobra, para destinos externos
- Zone apex = naked domain = root domain (`ejemplo.com`)
- Dual-stack (IPv4+IPv6) = Alias A + Alias AAAA

| Routing Policy | Uso |
|---|---|
| Simple | Un solo recurso |
| Weighted | Repartir tráfico por % |
| Latency | Menor latencia al usuario |
| Failover | Activo/pasivo |
| Geolocation | Por país/continente del usuario |
| Multi-value | Health check con múltiples IPs |

### CloudFront
- CDN: cachea contenido en edge locations
- **OAC**: acceso privado a S3 (reemplaza OAI)
- **Signed URLs**: un archivo específico. **Signed Cookies**: múltiples archivos
- **Origin Groups**: failover entre 2 origins (primary + secondary)
- CloudFront Functions (viewer level, ligero) vs Lambda@Edge (más potente)

### Global Accelerator
- 2 IPs estáticas AnyCast → enrutan a recursos en cualquier región
- Capa 4 (red), NO cachea contenido
- "Static IP" + "multiple regions" + "whitelist" → Global Accelerator

### WAF vs Network Firewall vs NACLs
| Herramienta | Capa | Caso |
|---|---|---|
| **WAF** | 7 (HTTP) | Bloqueo por país, SQLi, XSS, rate limit |
| **Network Firewall** | 3-4 | IDS/IPS, filtrado egress por dominio, tráfico no-HTTP |
| **NACLs** | 3-4 | Reglas simples IP/puerto por subnet |

---

## 2. COMPUTE

### EC2 Instance Types
| Familia | Optimizado para | Ejemplo |
|---|---|---|
| T (burstable) | General, créditos CPU | Web servers pequeños |
| M | General purpose equilibrado | Apps genéricas |
| C | Compute (CPU) | Batch processing, ML |
| R/X | Memory (RAM) | Bases de datos in-memory |
| I/D/H | Storage (disco NVMe) | HDFS, Kafka, data warehousing |
| P/G | GPU | ML training, rendering |

### Purchasing Options
| Tipo | Descuento | Compromiso | Caso |
|---|---|---|---|
| On-Demand | 0% | Ninguno | Workloads impredecibles |
| Reserved | ~72% | 1-3 años | Workloads estables |
| Savings Plans | ~72% | 1-3 años $/hora | Flexible entre instance types |
| Spot | ~90% | Ninguno (te lo quitan) | Batch, tolerante a interrupciones |
| Dedicated Host | Variable | Por host físico | Licencias por socket/core |

### EC2 Billing
- **Pending/Terminated**: no cobra
- **Stopped**: no cobra compute, SÍ cobra EBS
- **Hibernate**: guarda RAM en EBS, reinicio rápido. Decisión al lanzar (inmutable)
- **Stop+Start ≠ Reboot**: Stop+Start puede cambiar host físico. Reboot no

### Placement Groups
| Tipo | Dónde | Para qué |
|---|---|---|
| **Cluster** | Mismo rack | HPC, baja latencia |
| **Spread** | Racks distintos (máx 7/AZ) | HA, instancias críticas |
| **Partition** | Grupos en racks separados | Hadoop, Kafka, Cassandra |
- Insufficient capacity en Cluster → Stop+Start todas para reubicar en rack más grande

### Networking EC2
| Tipo | Velocidad | Caso |
|---|---|---|
| **ENI** | Básico | Default |
| **ENA** | Hasta 100 Gbps | Enhanced networking |
| **EFA** | OS-bypass (solo Linux) | HPC, MPI |

### Auto Scaling
- **Scaling Policies**: Target Tracking, Step, Simple, Scheduled, Predictive
- **Lifecycle Hooks**: Pending:Wait (antes de servir tráfico), Terminating:Wait (antes de terminar)
- **Warm Pools**: instancias pre-inicializadas para escalar más rápido

### Lambda
- Timeout máximo: 15 min. Memoria: 128MB-10GB. /tmp: 10GB
- **Execution Role**: qué puede hacer la Lambda (permisos OUTBOUND)
- **Resource Policy**: quién puede invocar la Lambda (permisos INBOUND)
- **Lambda Function URL**: endpoint HTTPS directo, sin API Gateway. Gratis
- KMS: necesita execution role con kms:Decrypt Y key policy permitiendo el role

### Containers
- **ECS**: AWS nativo. Task Definitions, Services, Clusters
- **EKS**: Kubernetes managed. HPA/VPA/Cluster Autoscaler/Karpenter
- **Fargate**: Serverless containers (sin gestionar EC2)
- ECS scaling: Service (más tasks) + Cluster (más EC2s) = dos niveles
- Container Insights: monitorización de contenedores con mínimo overhead

### Otros Compute
- **Elastic Beanstalk**: PaaS, deploy automático
- **AWS Batch**: Jobs en cola, compute environments
- **Outposts**: AWS en tu datacenter. **Wavelength**: 5G edge

---

## 3. STORAGE

### S3 Storage Classes
| Clase | Coste/GB | Retrieval | Min Duration | AZs |
|---|---|---|---|---|
| Standard | $0.023 | Inmediato | Ninguno | 3 |
| Intelligent-Tiering | $0.023-0.004 | Inmediato | Ninguno | 3 |
| Standard-IA | $0.0125 | Inmediato | 30 días | 3 |
| One Zone-IA | $0.01 | Inmediato | 30 días | 1 |
| Glacier Instant | $0.004 | Inmediato (ms) | 90 días | 3 |
| Glacier Flexible | $0.0036 | 1-5min / 3-5h / 5-12h | 90 días | 3 |
| Glacier Deep Archive | $0.00099 | 12h / 48h | 180 días | 3 |

**Trampas examen**:
- Datos temporales (horas/días) → Standard (min duration de IA cobra 30 días)
- Backup → nunca One Zone-IA
- "Within minutes" → Glacier Flexible (expedited). "Immediately" → IA o Glacier Instant
- Lifecycle: Standard → IA mínimo **30 días**. Standard → Glacier **sin mínimo**

### S3 Encryption
| Tipo | Quién gestiona la key |
|---|---|
| SSE-S3 | AWS (default, AES-256) |
| SSE-KMS | AWS KMS (auditoría en CloudTrail) |
| SSE-C | Tú proporcionas la key. Pierdes key = datos irrecuperables |
| Client-side | Tú cifras antes de subir |

### S3 Features
- **Versioning**: protege contra borrado accidental
- **Replication**: CRR (cross-region), SRR (same-region). Requiere versioning
- **Transfer Acceleration**: uploads rápidos via CloudFront edge
- **Event Notifications**: SQS, SNS, Lambda, EventBridge
- **Server Access Logging**: turnaround time, referrer, error codes (más detallado que CloudTrail)
- **Presigned URLs**: acceso temporal a objetos privados
- S3 es global en nombre pero regional en almacenamiento

### EBS
| Tipo | IOPS | Throughput | Caso |
|---|---|---|---|
| gp3 | 3000-16000 | 125-1000 MB/s | General purpose |
| gp2 | 3 IOPS/GB (burst 3000) | 250 MB/s | Legacy general |
| io2 Block Express | Hasta 256,000 | 4000 MB/s | Bases de datos críticas |
| st1 | N/A | 500 MB/s | Big data, logs secuenciales |
| sc1 | N/A | 250 MB/s | Archivos fríos, más barato |

- **Snapshots**: asíncronos, no bloquean el volumen. Point-in-time. Incrementales
- **Encryption By Default**: setting por región. Siempre keys simétricas (AES-256)
- **Multi-Attach**: solo io1/io2, mismo AZ
- Instance Store: disco físico del host. Dato se pierde al stop/terminate

### EFS
- NFS v4, solo Linux. Multi-AZ, multi-EC2
- Serverless, escala automáticamente
- Modos: General Purpose vs Max I/O. Throughput: Bursting vs Provisioned vs Elastic

### FSx
| Servicio | Protocolo | Caso |
|---|---|---|
| **FSx for Windows** | SMB | Windows file shares |
| **FSx for Lustre** | NFS (Lustre) | HPC, ML, rendering |
| **FSx for NetApp ONTAP** | NFS + SMB + iSCSI | Multi-protocol (único) |
| **FSx for OpenZFS** | NFS | Linux high-performance |
- Lustre Persistent = HA. Lustre Scratch = temporal, datos no replicados

### Storage Gateway
| Tipo | Protocolo | Cache local | Caso |
|---|---|---|---|
| S3 File Gateway | NFS/SMB | ✅ | Extender storage a S3 |
| Volume (Cached) | iSCSI | ✅ Cache local | Datos en S3, cache frecuente |
| Volume (Stored) | iSCSI | ✅ Completo | Datos locales, backup en S3 |
| Tape Gateway | iSCSI (VTL) | ✅ | Reemplazar cintas físicas |

### Migración de datos
| Servicio | Cuándo |
|---|---|
| **DataSync** | Migrar datos on-prem ↔ AWS. Preserva metadata y Windows permissions (NTFS) |
| **Snow Family** | Internet muy lento, petabytes. Snowcone puede correr DataSync agent |
| **Transfer Family** | SFTP/FTPS/FTP → S3 o EFS |
| **S3 Transfer Acceleration** | Uploads rápidos desde lejos via CloudFront edge |

---

## 4. DATABASES

### RDS
- Multi-AZ: standby síncrono, failover automático. NO lee del standby
- Read Replicas: réplica asíncrona, SÍ lee. Cross-region posible. Promoción manual
- Storage Auto Scaling: crece automáticamente cuando se llena
- Stop: auto-restart después de 7 días máximo
- RDS Proxy: connection pooling, failover 66% más rápido

### Aurora
- 5x MySQL / 3x PostgreSQL performance
- Hasta 15 read replicas, failover automático en ~30s (CNAME flip)
- **Cloning**: copy-on-write en segundos, sin impacto. Solo Aurora
- **Global Database**: cross-region, RPO <1s, RTO <1min
- **Serverless v2**: escala automáticamente. v1 = cluster separado
- **Backtracking**: "rebobinar" la DB a un punto en el tiempo (MySQL only)

### DynamoDB
- Serverless NoSQL, millisecond latency
- Partition Key + Sort Key. GSI/LSI para queries adicionales
- **DAX**: cache in-memory para DynamoDB, microsegundos
- **Global Tables**: multi-region active-active. Last writer wins
- **PITR**: restore a cualquier segundo en 35 días. "Accidental delete" → PITR
- **Streams**: captura cambios en la tabla (para triggers Lambda, replicación)
- On-Demand vs Provisioned capacity mode

### ElastiCache
| | Redis | Memcached |
|---|---|---|
| Persistencia | ✅ | ❌ |
| HA (replicación) | ✅ | ❌ |
| Pub/Sub | ✅ | ❌ |
| Multi-AZ | ✅ | ❌ |
| Multi-thread | ❌ | ✅ |

### Redshift
- Data warehouse, columnar, SQL analytics sobre TB/PB
- Latencia: segundos a minutos (NO milliseconds)
- Redshift Spectrum: query directamente sobre S3 sin cargar datos
- "Analytics" + "reporting" + "terabytes" → Redshift

### Otros
- **Neptune**: graph database (redes sociales, fraud detection)
- **DocumentDB**: MongoDB compatible
- **QLDB**: ledger inmutable (finanzas, blockchain-like)
- **Timestream**: time series (IoT, métricas)
- **Keyspaces**: Cassandra compatible

---

## 5. SECURITY

### IAM
- **Users**: personas. **Groups**: colección de users. **Roles**: para servicios/cross-account
- Policy evaluation: Explicit Deny > Explicit Allow > Implicit Deny
- **Permission Boundary**: límite máximo de permisos para un user/role
- IAM es **global** (funciona en todas las regiones)

### Organizations
- **SCPs**: límite máximo por cuenta/OU. No conceden permisos, solo restringen
- **Consolidated Billing**: una factura, volume discounts compartidos
- Permiso efectivo = SCP ∩ IAM Policy

### Control Tower
- Automatiza Organizations + guardrails + Account Factory + Landing Zone
- **Guardrails**: Preventive (SCP) + Detective (Config rules)
- **Account Factory**: crea cuentas preconfiguradas con best practices

### KMS
| Tipo key | Rotación | Control |
|---|---|---|
| AWS owned | AWS decide | Ninguno |
| AWS managed | 1 año auto, no configurable | Bajo |
| Customer managed | Tú defines periodo | Total |
| External/imported | Manual | Total (más overhead) |
- EBS: siempre keys simétricas (AES-256). Asimétricas NO sirven
- SSE-C / CloudHSM: pierdes key = datos irrecuperables para siempre

### Otros Security
- **Secrets Manager**: rotación automática de secrets. **Parameter Store**: más barato, sin auto-rotación
- **CloudHSM**: FIPS 140-2 Level 3, single-tenant
- **Cognito**: User Pools (autenticación), Identity Pools (autorización)
- **GuardDuty**: detección de amenazas. **Inspector**: vulnerabilidades. **Macie**: PII en S3
- **Shield Standard**: DDoS gratis. **Shield Advanced**: DDoS + DRT + protección de costes
- **ACM**: certificados SSL/TLS gratis, renovación automática en ALB
- **Vault Lock Compliance**: nadie puede borrar, ni root. **Governance**: admin puede override

---

## 6. MIGRATION

### Estrategias (7 Rs)
- **Rehost**: lift-and-shift (MGN)
- **Replatform**: lift-and-reshape (ej: MySQL → RDS)
- **Refactor**: re-architect para cloud-native
- **Repurchase**: cambiar a SaaS
- **Retire/Retain/Relocate**: apagar, mantener, mover

### Servicios
| Servicio | Qué migra |
|---|---|
| **MGN** | EC2 lift-and-shift (block-level replication) |
| **DMS** | Bases de datos (Full Load + CDC, near-zero downtime) |
| **DataSync** | Datos/archivos (preserva metadata y NTFS permissions) |
| **Snow Family** | Datos masivos (dispositivo físico) |
| **Application Discovery** | Descubrir qué tienes on-prem (agentless o agent-based) |

### DMS
- Same engine → homogeneous. Different engine → heterogeneous (necesita SCT primero)
- Full Load + CDC = near-zero downtime
- Aurora Serverless v1 → usar DMS (no mezcla provisioned + serverless)

### DR Strategies
| Estrategia | RPO | RTO | Coste |
|---|---|---|---|
| Backup & Restore | Horas | Horas | $ |
| Pilot Light | Minutos | Minutos-horas | $$ |
| Warm Standby | Segundos-min | Minutos | $$$ |
| Multi-Site/Hot | ~0 | Segundos-min | $$$$ |
- **AWS DRS**: block-level replication, RPO segundos, RTO minutos

---

## 7. MONITORING

### CloudWatch
- **Metrics**: CPU, Network, Disk. Detailed monitoring = 1 min (default 5 min)
- **CloudWatch Agent**: RAM, disco, custom metrics (no viene por defecto)
- **Alarms**: trigger acciones (ASG, SNS, EC2 actions)
- **Container Insights**: monitorización de ECS/EKS con mínimo overhead

### CloudTrail
| Tipo | Qué registra | Default |
|---|---|---|
| Management Events | Crear/borrar/modificar recursos | ✅ |
| Data Events | GetObject, PutObject, Invoke Lambda | ❌ (caro) |
| Insights | Actividad anómala | ❌ |
- **Log File Validation**: detecta si log fue tampered (digest file con hash)
- Cifrado por defecto: SSE-S3 (AES-256)

### AWS Config
- Audita **compliance de configuración** de recursos
- Managed rules + custom rules
- Detecta non-compliance, NO previene (SCPs previenen)
- NO monitoriza service quotas (eso es Trusted Advisor)

### X-Ray
- Tracing distribuido: ve el recorrido de una request entre servicios
- Service map, segments, subsegments
- "Latencia entre servicios" → X-Ray. "Métricas de un servicio" → CloudWatch

### Trusted Advisor
- Best practices: security, performance, cost, fault tolerance, service limits
- Service Limits check: requiere **Business support plan** mínimo
- Refresh con `RefreshTrustedAdvisorCheck` API (Lambda cada 24h)

### Systems Manager
- **Run Command**: ejecutar comandos en EC2 sin SSH/RDP (via SSM Agent)
- **Session Manager**: terminal interactivo sin abrir puertos
- **Parameter Store**: guardar configuración/secrets
- **Patch Manager**: parches automáticos

---

## 8. APPLICATION INTEGRATION

### Mensajería
| Servicio | Modelo | Caso |
|---|---|---|
| **SQS Standard** | Cola, at-least-once | Desacoplar servicios |
| **SQS FIFO** | Cola, exactly-once, ordenado | Transacciones en orden |
| **SNS** | Pub/Sub, fan-out | Notificar a múltiples suscriptores |
| **EventBridge** | Event bus, rules | Routing de eventos entre servicios |

### Streaming
| Servicio | Latencia | Consumidor |
|---|---|---|
| **Kinesis Data Streams** | Real-time (ms) | Tú escribes (Lambda, KCL) |
| **Data Firehose** | Near real-time (60s+) | Automático a S3/Redshift/OpenSearch |
- Shards = capacidad. Más shards = más throughput. Cada shard: 1MB/s in, 2MB/s out
- "Kinesis lento" → UpdateShardCount (más shards)
- Kinesis NO tiene auto-scaling. Escala manual

### Analytics
| Servicio | Qué hace |
|---|---|
| **Athena** | SQL sobre S3 (serverless, $5/TB) |
| **Glue** | ETL serverless (Crawlers + Data Catalog + Jobs) |
| **EMR** | Hadoop/Spark managed (Primary On-Demand, Task Spot safe) |
| **QuickSight** | Dashboards BI |
| **Lake Formation** | Governance data lake, column-level security |
| **OpenSearch** | Full-text search, log analytics |

### Workflow
- **Step Functions**: orquestación serverless (Standard: hasta 1 año, Express: <5min)
- **API Gateway**: REST/HTTP/WebSocket API. Rate limiting, API keys
- **AppSync**: GraphQL API, real-time subscriptions
- **Lambda Function URL**: endpoint HTTPS simple, sin API Gateway, gratis

---

## 9. AI/ML SERVICES

| Servicio | Input → Output |
|---|---|
| **Textract** | Imagen/PDF → texto (OCR) |
| **Comprehend** | Texto → sentimiento, entidades, PII |
| **Comprehend Medical** | Texto → PHI médico (HIPAA) |
| **Transcribe** | Audio → texto |
| **Polly** | Texto → audio |
| **Rekognition** | Imagen/vídeo → objetos, caras |
| **Translate** | Texto → otro idioma |
| **Lex** | Chatbot (intent recognition) |
| **Kendra** | Búsqueda semántica en documentos |
| **Personalize** | Recomendaciones personalizadas |
| **Forecast** | Predicción time series |
| **SageMaker** | ML custom (más overhead) |
| **Bedrock** | GenAI/LLMs (Claude, Titan) |

---

## 10. COST OPTIMIZATION

### Herramientas
| Servicio | Qué hace |
|---|---|
| **Cost Explorer** | Analizar costes pasados, forecast |
| **AWS Budgets** | Alertas cuando superas umbral + acciones automáticas |
| **Compute Optimizer** | Rightsizing EC2, EBS, Lambda |
| **CUR** | Reporte detallado por recurso (Athena/QuickSight) |

### Data Transfer Costs
- **Misma AZ (private IP)**: gratis
- **Entre AZs**: $0.01/GB por lado
- **A Internet**: ~$0.09/GB
- **S3 ingress**: gratis. **S3 → EC2 misma región**: gratis

### Patrones de ahorro
- Datos temporales → S3 Standard (no IA por min duration)
- "Cost-effective" + salida Internet → misma AZ
- "Cost-effective" + NAT → NAT Instance (vs NAT Gateway)
- RDS no se usa por tiempo → Stop (max 7 días) o Snapshot + Terminate
- Reserved/Savings Plans: workloads estables 24/7
- Spot: batch, tolerante a interrupciones, EMR task nodes
