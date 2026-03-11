# Concept Map - AWS SAA-C03

---

## 1. NETWORKING

### VPC Basics
- VPC = virtual network, regional. Subnets = single AZ
- CIDR: you define the IP range (e.g., 10.0.0.0/16)
- Route table `local` = internal VPC traffic (automatic, cannot be deleted)
- `0.0.0.0/0` = default route (all Internet)

### Internet Access
| Service | What it does | Direction |
|---|---|---|
| **Internet Gateway** | Connects VPC to Internet | Bidirectional |
| **NAT Gateway** | IPv4 outbound without inbound | Outbound only. ~$32/month |
| **NAT Instance** | Same but manual EC2 | Cheaper (t3.nano ~$3/month) |
| **Egress-Only IGW** | IPv6 outbound without inbound | IPv6 only. Free |

### Security Groups vs NACLs
| | Security Group | NACL |
|---|---|---|
| Level | Instance | Subnet |
| Stateful | Yes (automatic return) | No (explicit rule for return) |
| Default | Deny all inbound, Allow all outbound | Allow all |
| Rules | ALLOW only | ALLOW and DENY |
| Evaluation | All rules evaluated | Numerical order (first match wins) |

### VPC Endpoints
- **Gateway Endpoint**: S3 and DynamoDB. Free. Configured in route table
- **Interface Endpoint**: other AWS services. ~$7.2/month. Uses ENI + Security Group
- VPC Endpoints do NOT connect VPC to VPC

### VPC-to-VPC and On-Prem Connectivity
| Connect | Tool |
|---|---|
| 2 VPCs | VPC Peering (+ update route tables) |
| Many VPCs (hub-spoke) | Transit Gateway |
| VPC to on-prem (fast) | Site-to-Site VPN (minutes, over Internet) |
| VPC to on-prem (dedicated) | Direct Connect (weeks, physical cable) |

### Load Balancers
| Type | Layer | Use case |
|---|---|---|
| **ALB** | 7 (HTTP) | Web apps, path/host routing, weighted target groups |
| **NLB** | 4 (TCP/UDP) | Ultra-low latency, static IP, millions of requests |
| **GLB** | 3 (GENEVE) | Firewalls, network appliances |
- ALB supports IP targets (on-prem via Direct Connect)
- NLB supports HTTP health checks (even though it operates at layer 4)
- Sticky sessions: cookie that pins a user to one instance. Disable if app is stateless

### Route 53
- **Alias** (Route 53 proprietary): works at zone apex, free, points to AWS resources
- **CNAME**: does NOT work at zone apex, charges, for external destinations
- Zone apex = naked domain = root domain (`example.com`)
- Dual-stack (IPv4+IPv6) = Alias A + Alias AAAA

| Routing Policy | Use |
|---|---|
| Simple | Single resource |
| Weighted | Distribute traffic by % |
| Latency | Lowest latency to user |
| Failover | Active/passive |
| Geolocation | By user's country/continent |
| Multi-value | Health check with multiple IPs |

### CloudFront
- CDN: caches content at edge locations
- **OAC**: private access to S3 (replaces OAI)
- **Signed URLs**: one specific file. **Signed Cookies**: multiple files
- **Origin Groups**: failover between 2 origins (primary + secondary)
- CloudFront Functions (viewer level, lightweight) vs Lambda@Edge (more powerful)

### Global Accelerator
- 2 static AnyCast IPs that route to resources in any region
- Layer 4 (network), does NOT cache content
- "Static IP" + "multiple regions" + "whitelist" -> Global Accelerator

### WAF vs Network Firewall vs NACLs
| Tool | Layer | Use case |
|---|---|---|
| **WAF** | 7 (HTTP) | Block by country, SQLi, XSS, rate limit |
| **Network Firewall** | 3-4 | IDS/IPS, egress domain filtering, non-HTTP traffic |
| **NACLs** | 3-4 | Simple IP/port rules per subnet |

---

## 2. COMPUTE

### EC2 Instance Types
| Family | Optimized for | Example |
|---|---|---|
| T (burstable) | General, CPU credits | Small web servers |
| M | General purpose balanced | Generic apps |
| C | Compute (CPU) | Batch processing, ML |
| R/X | Memory (RAM) | In-memory databases |
| I/D/H | Storage (NVMe disk) | HDFS, Kafka, data warehousing |
| P/G | GPU | ML training, rendering |

### Purchasing Options
| Type | Discount | Commitment | Use case |
|---|---|---|---|
| On-Demand | 0% | None | Unpredictable workloads |
| Reserved | ~72% | 1-3 years | Stable workloads |
| Savings Plans | ~72% | 1-3 years $/hour | Flexible across instance types |
| Spot | ~90% | None (can be reclaimed) | Batch, interrupt-tolerant |
| Dedicated Host | Variable | Per physical host | Per-socket/core licenses |

### EC2 Billing
- **Pending/Terminated**: no charge
- **Stopped**: no compute charge, YES EBS charge
- **Hibernate**: saves RAM to EBS, fast restart. Decision at launch (immutable)
- **Stop+Start != Reboot**: Stop+Start may change physical host. Reboot does not

### Placement Groups
| Type | Where | Purpose |
|---|---|---|
| **Cluster** | Same rack | HPC, low latency |
| **Spread** | Different racks (max 7/AZ) | HA, critical instances |
| **Partition** | Groups in separate racks | Hadoop, Kafka, Cassandra |
- Insufficient capacity in Cluster -> Stop+Start all to relocate to a larger rack

### Networking EC2
| Type | Speed | Use case |
|---|---|---|
| **ENI** | Basic | Default |
| **ENA** | Up to 100 Gbps | Enhanced networking |
| **EFA** | OS-bypass (Linux only) | HPC, MPI |

### Auto Scaling
- **Scaling Policies**: Target Tracking, Step, Simple, Scheduled, Predictive
- **Lifecycle Hooks**: Pending:Wait (before serving traffic), Terminating:Wait (before terminating)
- **Warm Pools**: pre-initialized instances for faster scaling

### Lambda
- Max timeout: 15 min. Memory: 128MB-10GB. /tmp: 10GB
- **Execution Role**: what the Lambda can do (OUTBOUND permissions)
- **Resource Policy**: who can invoke the Lambda (INBOUND permissions)
- **Lambda Function URL**: direct HTTPS endpoint, no API Gateway. Free
- KMS: needs execution role with kms:Decrypt AND key policy allowing the role

### Containers
- **ECS**: AWS native. Task Definitions, Services, Clusters
- **EKS**: Kubernetes managed. HPA/VPA/Cluster Autoscaler/Karpenter
- **Fargate**: Serverless containers (no EC2 management)
- ECS scaling: Service (more tasks) + Cluster (more EC2s) = two levels
- Container Insights: container monitoring with minimal overhead

### Other Compute
- **Elastic Beanstalk**: PaaS, automatic deployment
- **AWS Batch**: Jobs in queue, compute environments
- **Outposts**: AWS in your datacenter. **Wavelength**: 5G edge

---

## 3. STORAGE

### S3 Storage Classes
| Class | Cost/GB | Retrieval | Min Duration | AZs |
|---|---|---|---|---|
| Standard | $0.023 | Immediate | None | 3 |
| Intelligent-Tiering | $0.023-0.004 | Immediate | None | 3 |
| Standard-IA | $0.0125 | Immediate | 30 days | 3 |
| One Zone-IA | $0.01 | Immediate | 30 days | 1 |
| Glacier Instant | $0.004 | Immediate (ms) | 90 days | 3 |
| Glacier Flexible | $0.0036 | 1-5min / 3-5h / 5-12h | 90 days | 3 |
| Glacier Deep Archive | $0.00099 | 12h / 48h | 180 days | 3 |

**Exam traps**:
- Temporary data (hours/days) -> Standard (IA min duration charges 30 days)
- Backup -> never One Zone-IA
- "Within minutes" -> Glacier Flexible (expedited). "Immediately" -> IA or Glacier Instant
- Lifecycle: Standard -> IA minimum **30 days**. Standard -> Glacier **no minimum**

### S3 Encryption
| Type | Who manages the key |
|---|---|
| SSE-S3 | AWS (default, AES-256) |
| SSE-KMS | AWS KMS (audit in CloudTrail) |
| SSE-C | You provide the key. Lose key = data unrecoverable |
| Client-side | You encrypt before uploading |

### S3 Features
- **Versioning**: protects against accidental deletion
- **Replication**: CRR (cross-region), SRR (same-region). Requires versioning
- **Transfer Acceleration**: fast uploads via CloudFront edge
- **Event Notifications**: SQS, SNS, Lambda, EventBridge
- **Server Access Logging**: turnaround time, referrer, error codes (more detailed than CloudTrail)
- **Presigned URLs**: temporary access to private objects
- S3 is global in name but regional in storage

### EBS
| Type | IOPS | Throughput | Use case |
|---|---|---|---|
| gp3 | 3000-16000 | 125-1000 MB/s | General purpose |
| gp2 | 3 IOPS/GB (burst 3000) | 250 MB/s | Legacy general |
| io2 Block Express | Up to 256,000 | 4000 MB/s | Critical databases |
| st1 | N/A | 500 MB/s | Big data, sequential logs |
| sc1 | N/A | 250 MB/s | Cold files, cheapest |

- **Snapshots**: asynchronous, do not block the volume. Point-in-time. Incremental
- **Encryption By Default**: per-region setting. Always symmetric keys (AES-256)
- **Multi-Attach**: io1/io2 only, same AZ
- Instance Store: physical disk of the host. Data is lost on stop/terminate

### EFS
- NFS v4, Linux only. Multi-AZ, multi-EC2
- Serverless, scales automatically
- Modes: General Purpose vs Max I/O. Throughput: Bursting vs Provisioned vs Elastic

### FSx
| Service | Protocol | Use case |
|---|---|---|
| **FSx for Windows** | SMB | Windows file shares |
| **FSx for Lustre** | NFS (Lustre) | HPC, ML, rendering |
| **FSx for NetApp ONTAP** | NFS + SMB + iSCSI | Multi-protocol (unique) |
| **FSx for OpenZFS** | NFS | Linux high-performance |
- Lustre Persistent = HA. Lustre Scratch = temporary, data not replicated

### Storage Gateway
| Type | Protocol | Local cache | Use case |
|---|---|---|---|
| S3 File Gateway | NFS/SMB | Yes | Extend storage to S3 |
| Volume (Cached) | iSCSI | Yes, local cache | Data in S3, frequent cache |
| Volume (Stored) | iSCSI | Yes, full | Data local, backup to S3 |
| Tape Gateway | iSCSI (VTL) | Yes | Replace physical tapes |

### Data Migration
| Service | When |
|---|---|
| **DataSync** | Migrate data on-prem <-> AWS. Preserves metadata and Windows permissions (NTFS) |
| **Snow Family** | Very slow internet, petabytes. Snowcone can run DataSync agent |
| **Transfer Family** | SFTP/FTPS/FTP -> S3 or EFS |
| **S3 Transfer Acceleration** | Fast uploads from far away via CloudFront edge |

---

## 4. DATABASES

### RDS
- Multi-AZ: synchronous standby, automatic failover. Cannot read from standby
- Read Replicas: asynchronous replica, CAN read. Cross-region possible. Manual promotion
- Storage Auto Scaling: grows automatically when full
- Stop: auto-restart after 7 days maximum
- RDS Proxy: connection pooling, 66% faster failover

### Aurora
- 5x MySQL / 3x PostgreSQL performance
- Up to 15 read replicas, automatic failover in ~30s (CNAME flip)
- **Cloning**: copy-on-write in seconds, no impact. Aurora only
- **Global Database**: cross-region, RPO <1s, RTO <1min
- **Serverless v2**: scales automatically. v1 = separate cluster
- **Backtracking**: "rewind" the DB to a point in time (MySQL only)

### DynamoDB
- Serverless NoSQL, millisecond latency
- Partition Key + Sort Key. GSI/LSI for additional queries
- **DAX**: in-memory cache for DynamoDB, microseconds
- **Global Tables**: multi-region active-active. Last writer wins
- **PITR**: restore to any second within 35 days. "Accidental delete" -> PITR
- **Streams**: captures changes in the table (for Lambda triggers, replication)
- On-Demand vs Provisioned capacity mode

### ElastiCache
| | Redis | Memcached |
|---|---|---|
| Persistence | Yes | No |
| HA (replication) | Yes | No |
| Pub/Sub | Yes | No |
| Multi-AZ | Yes | No |
| Multi-thread | No | Yes |

### Redshift
- Data warehouse, columnar, SQL analytics over TB/PB
- Latency: seconds to minutes (NOT milliseconds)
- Redshift Spectrum: query directly on S3 without loading data
- "Analytics" + "reporting" + "terabytes" -> Redshift

### Others
- **Neptune**: graph database (social networks, fraud detection)
- **DocumentDB**: MongoDB compatible
- **QLDB**: immutable ledger (finance, blockchain-like)
- **Timestream**: time series (IoT, metrics)
- **Keyspaces**: Cassandra compatible

---

## 5. SECURITY

### IAM
- **Users**: people. **Groups**: collection of users. **Roles**: for services/cross-account
- Policy evaluation: Explicit Deny > Explicit Allow > Implicit Deny
- **Permission Boundary**: maximum permissions limit for a user/role
- IAM is **global** (works in all regions)

### Organizations
- **SCPs**: maximum limit per account/OU. Do not grant permissions, only restrict
- **Consolidated Billing**: one invoice, shared volume discounts
- Effective permission = SCP intersection IAM Policy

### Control Tower
- Automates Organizations + guardrails + Account Factory + Landing Zone
- **Guardrails**: Preventive (SCP) + Detective (Config rules)
- **Account Factory**: creates pre-configured accounts with best practices

### KMS
| Key type | Rotation | Control |
|---|---|---|
| AWS owned | AWS decides | None |
| AWS managed | 1 year auto, not configurable | Low |
| Customer managed | You define the period | Full |
| External/imported | Manual | Full (more overhead) |
- EBS: always symmetric keys (AES-256). Asymmetric keys do NOT work
- SSE-C / CloudHSM: lose key = data unrecoverable forever

### Other Security
- **Secrets Manager**: automatic secret rotation. **Parameter Store**: cheaper, no auto-rotation
- **CloudHSM**: FIPS 140-2 Level 3, single-tenant
- **Cognito**: User Pools (authentication), Identity Pools (authorization)
- **GuardDuty**: threat detection. **Inspector**: vulnerabilities. **Macie**: PII in S3
- **Shield Standard**: DDoS free. **Shield Advanced**: DDoS + DRT + cost protection
- **ACM**: free SSL/TLS certificates, automatic renewal on ALB
- **Vault Lock Compliance**: nobody can delete, not even root. **Governance**: admin can override

---

## 6. MIGRATION

### Strategies (7 Rs)
- **Rehost**: lift-and-shift (MGN)
- **Replatform**: lift-and-reshape (e.g., MySQL -> RDS)
- **Refactor**: re-architect for cloud-native
- **Repurchase**: switch to SaaS
- **Retire/Retain/Relocate**: shut down, keep, move

### Services
| Service | What it migrates |
|---|---|
| **MGN** | EC2 lift-and-shift (block-level replication) |
| **DMS** | Databases (Full Load + CDC, near-zero downtime) |
| **DataSync** | Data/files (preserves metadata and NTFS permissions) |
| **Snow Family** | Massive data (physical device) |
| **Application Discovery** | Discover what you have on-prem (agentless or agent-based) |

### DMS
- Same engine -> homogeneous. Different engine -> heterogeneous (needs SCT first)
- Full Load + CDC = near-zero downtime
- Aurora Serverless v1 -> use DMS (cannot mix provisioned + serverless)

### DR Strategies
| Strategy | RPO | RTO | Cost |
|---|---|---|---|
| Backup & Restore | Hours | Hours | $ |
| Pilot Light | Minutes | Minutes-hours | $$ |
| Warm Standby | Seconds-min | Minutes | $$$ |
| Multi-Site/Hot | ~0 | Seconds-min | $$$$ |
- **AWS DRS**: block-level replication, RPO seconds, RTO minutes

---

## 7. MONITORING

### CloudWatch
- **Metrics**: CPU, Network, Disk. Detailed monitoring = 1 min (default 5 min)
- **CloudWatch Agent**: RAM, disk, custom metrics (not included by default)
- **Alarms**: trigger actions (ASG, SNS, EC2 actions)
- **Container Insights**: ECS/EKS monitoring with minimal overhead

### CloudTrail
| Type | What it records | Default |
|---|---|---|
| Management Events | Create/delete/modify resources | Yes |
| Data Events | GetObject, PutObject, Invoke Lambda | No (expensive) |
| Insights | Anomalous activity | No |
- **Log File Validation**: detects if log was tampered (digest file with hash)
- Default encryption: SSE-S3 (AES-256)

### AWS Config
- Audits **configuration compliance** of resources
- Managed rules + custom rules
- Detects non-compliance, does NOT prevent (SCPs prevent)
- Does NOT monitor service quotas (that is Trusted Advisor)

### X-Ray
- Distributed tracing: see the path of a request across services
- Service map, segments, subsegments
- "Latency between services" -> X-Ray. "Metrics of a service" -> CloudWatch

### Trusted Advisor
- Best practices: security, performance, cost, fault tolerance, service limits
- Service Limits check: requires **Business support plan** minimum
- Refresh with `RefreshTrustedAdvisorCheck` API (Lambda every 24h)

### Systems Manager
- **Run Command**: execute commands on EC2 without SSH/RDP (via SSM Agent)
- **Session Manager**: interactive terminal without opening ports
- **Parameter Store**: store configuration/secrets
- **Patch Manager**: automatic patching

---

## 8. APPLICATION INTEGRATION

### Messaging
| Service | Model | Use case |
|---|---|---|
| **SQS Standard** | Queue, at-least-once | Decouple services |
| **SQS FIFO** | Queue, exactly-once, ordered | Transactions in order |
| **SNS** | Pub/Sub, fan-out | Notify multiple subscribers |
| **EventBridge** | Event bus, rules | Event routing between services |

### Streaming
| Service | Latency | Consumer |
|---|---|---|
| **Kinesis Data Streams** | Real-time (ms) | You write (Lambda, KCL) |
| **Data Firehose** | Near real-time (60s+) | Automatic to S3/Redshift/OpenSearch |
- Shards = capacity. More shards = more throughput. Each shard: 1MB/s in, 2MB/s out
- "Kinesis slow" -> UpdateShardCount (more shards)
- Kinesis does NOT have auto-scaling. Scales manually

### Analytics
| Service | What it does |
|---|---|
| **Athena** | SQL on S3 (serverless, $5/TB) |
| **Glue** | Serverless ETL (Crawlers + Data Catalog + Jobs) |
| **EMR** | Hadoop/Spark managed (Primary On-Demand, Task Spot safe) |
| **QuickSight** | BI dashboards |
| **Lake Formation** | Data lake governance, column-level security |
| **OpenSearch** | Full-text search, log analytics |

### Workflow
- **Step Functions**: serverless orchestration (Standard: up to 1 year, Express: <5min)
- **API Gateway**: REST/HTTP/WebSocket API. Rate limiting, API keys
- **AppSync**: GraphQL API, real-time subscriptions
- **Lambda Function URL**: simple HTTPS endpoint, no API Gateway, free

---

## 9. AI/ML SERVICES

| Service | Input -> Output |
|---|---|
| **Textract** | Image/PDF -> text (OCR) |
| **Comprehend** | Text -> sentiment, entities, PII |
| **Comprehend Medical** | Text -> medical PHI (HIPAA) |
| **Transcribe** | Audio -> text |
| **Polly** | Text -> audio |
| **Rekognition** | Image/video -> objects, faces |
| **Translate** | Text -> another language |
| **Lex** | Chatbot (intent recognition) |
| **Kendra** | Semantic search in documents |
| **Personalize** | Personalized recommendations |
| **Forecast** | Time series prediction |
| **SageMaker** | Custom ML (more overhead) |
| **Bedrock** | GenAI/LLMs (Claude, Titan) |

---

## 10. COST OPTIMIZATION

### Tools
| Service | What it does |
|---|---|
| **Cost Explorer** | Analyze past costs, forecast |
| **AWS Budgets** | Alerts when exceeding threshold + automatic actions |
| **Compute Optimizer** | Rightsizing EC2, EBS, Lambda |
| **CUR** | Detailed report per resource (Athena/QuickSight) |

### Data Transfer Costs
- **Same AZ (private IP)**: free
- **Between AZs**: $0.01/GB per side
- **To Internet**: ~$0.09/GB
- **S3 ingress**: free. **S3 -> EC2 same region**: free

### Savings Patterns
- Temporary data -> S3 Standard (not IA due to min duration)
- "Cost-effective" + Internet egress -> same AZ
- "Cost-effective" + NAT -> NAT Instance (vs NAT Gateway)
- RDS not used for a while -> Stop (max 7 days) or Snapshot + Terminate
- Reserved/Savings Plans: stable 24/7 workloads
- Spot: batch, interrupt-tolerant, EMR task nodes
