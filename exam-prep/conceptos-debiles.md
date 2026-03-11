# Concepts I Get Wrong Most - Quick Review

---

## AWS DMS (Database Migration Service)

- **Full Load + CDC (Change Data Capture)**: copies existing data and then replicates changes in near-real-time by reading the transaction log
- **Near-zero downtime**: the source remains operational. The only real downtime is the cutover (switching the app to the target)
- **Main use case**: migrations between different engines (Oracle->Aurora, on-prem->cloud, MySQL->PostgreSQL)
- **Do NOT use DMS** to migrate within the same Aurora cluster -> use native replication (add replica + failover)

## Aurora: Migration Provisioned -> Serverless

- **Aurora Serverless v1 vs v2 are different architectures**:
  - **v2**: allows mixing provisioned and serverless instances in the same cluster (replica + failover works)
  - **v1**: completely separate cluster, you CANNOT add serverless replicas to a provisioned cluster
- **On the exam**: if it says "Aurora Serverless" without specifying -> assume v1 -> **use DMS** to migrate with near-zero downtime
- DMS with CDC is the safe option to migrate **between different Aurora architectures**
- Snapshot + new cluster = significant downtime (data post-snapshot is lost)
- Change instance class directly = NOT possible between provisioned and serverless v1

## Data Firehose vs Kinesis Data Streams vs Redshift

- **Kinesis Data Streams**: "pipe with retention" -- captures real-time streaming, retains 1-365d, multiple consumers read simultaneously (Lambda, apps, Firehose, Analytics). Does not process or deliver on its own, needs consumers.
- **Data Firehose**: "hose" -- serverless near-real-time delivery (min 60s buffer) to fixed destinations: **S3, Redshift, OpenSearch, Splunk, HTTP endpoint**
  - Can transform with Lambda on the fly
  - No retention, delivery only
- **Redshift**: data warehouse -- SQL analytics on historical data, petabytes, batch
- **Exam key**: if it says "capture, transform, load streaming into S3/OpenSearch/Splunk" -> Firehose
- **Firehose does NOT need Kinesis Streams** -- can receive data directly via SDK/API, CloudWatch Logs, IoT, etc.
- You only use Streams + Firehose together when you need custom real-time processing AND delivery to destinations
- Flow with both (optional): Sensors -> Kinesis Streams -> Firehose -> S3 -> Redshift

## AWS Glue

- **Serverless ETL** service (Extract, Transform, Load)
- **Crawlers**: scan data in S3/RDS/DynamoDB, discover schema automatically
- **Data Catalog**: central metadata database (compatible with Athena, Redshift Spectrum, EMR)
- **ETL Jobs**: PySpark/Scala scripts that transform data, serverless
- **Job Bookmarks**: mechanism that remembers what data has already been processed
  - **Enabled**: only processes new data since the last run
  - **Disabled** (default): processes everything each time
  - **Pause**: processes everything but does not update the bookmark
  - For S3: tracks by file path/timestamp
  - For JDBC: tracks by incremental column (id, timestamp)
- **Exam key**: if the problem is "reprocessing old data" -> enable Job Bookmark

## IAM, Organizations, SCPs and Multi-Account

- **IAM Groups**: group users and apply policies to them. You cannot attach Roles to Groups.
- **IAM Roles**: temporary credentials, assumed (not permanently attached to users/groups)
- **SCPs**: maximum permission limit for **entire accounts/OUs**, NOT for individual users. They do not grant permissions, only restrict.
- **Permissions Boundary**: maximum limit for a specific user/role within an account
- **Effective permissions** = intersection of SCP + Permissions Boundary + IAM Policy
- SCPs do NOT affect the Management Account
- **Organizations**: multiple accounts, consolidated billing, structure Root->OUs->Accounts
- **Control Tower**: automates Organizations + guardrails + account factory + landing zone
- **Exam key**: "departments + users + MFA" -> IAM Groups + IAM Policy. "Restrict entire accounts" -> SCPs
- **When to use Organizations**: multiple teams, isolate environments, compliance, >10 people
- **When to use IAM Users alone**: one account, few devs, no strict isolation requirements
- **Cross-account access**: IAM Role in destination account + AssumeRole from source account (temporary credentials)
- **Real advantage of multi-account**: total isolation, a policy error in dev CANNOT affect prod
- **You do NOT need multiple logins**: one login in Identity Center (SSO) -> Switch Role / portal to any account
- **IAM Identity Center** (formerly AWS SSO): current best practice, one web portal, temporary credentials, no IAM Users
- CLI: `~/.aws/config` with profiles + `role_arn` + `source_profile` -> `aws s3 ls --profile prod`
- **Exam key**: "centralized access across accounts" / "single sign-on" -> IAM Identity Center

## EC2 Billing by State

- **pending**: NO charge
- **running**: YES charge
- **stopping (normal)**: NO charge
- **stopping (hibernate)**: YES charge (dumps RAM to EBS, instance active)
- **stopped**: NO compute charge (YES EBS charge)
- **shutting-down / terminated**: NO charge
- **Reserved Instance terminated**: YES still charges (it is a contract, not an instance)
- **Spot interrupted by AWS (stopping)**: NO charge for the partial hour (AWS's fault)
- Reserved Instance = discount contract for 1-3 years, you pay even if no instance is running

## EC2 Hibernate

- **IMMUTABLE decision at launch** -- cannot be enabled NOR disabled afterwards
- If you need hibernate on an existing instance -> **migrate to a new instance** with hibernate enabled
- Hibernate saves RAM to EBS root -> fast boot (restores RAM, like suspending a laptop)
- Requirements: encrypted root EBS, enough space for RAM, max 150GB RAM, max 60 days hibernating
- Normal stop: loses RAM -> slow boot. Hibernate: restores RAM -> fast boot
- **Exam trap**: "enable hibernate" (on existing, impossible) vs "migrate to instance with hibernate" (correct)

## Instance Store vs EBS as Root Volume

- **EBS-Backed**: root on EBS, can stop/start, snapshots, data persists on stop. Terminate deletes by default (configurable).
- **Instance Store-Backed**: root on host's local disk, CANNOT stop (only terminate), NO snapshots, data is LOST on terminate or if host fails.
- Instance Store as additional volume: for cache, temp files, scratch data, very high IOPS (NVMe). NEVER for non-reproducible data.
- **Exam key**: "Instance Store-Backed AMI" + "terminate" -> data permanently deleted

## EBS Types

- **SSD**: gp2/gp3 (general, boot), io1/io2 (provisioned IOPS, large DBs, multi-attach io only)
- **HDD**: st1 (throughput optimized, big data), sc1 (cold, infrequent data). HDD CANNOT be a boot volume.
- **Magnetic** (standard): legacy, cheapest per GB, infrequent access, can be boot volume
- "Spot volumes" do NOT exist (Spot is an instance type). "SR-IOV volumes" do NOT exist (SR-IOV is networking).
- Multi-attach: io1/io2 only, same AZ only (not multi-AZ). gp3 does NOT support multi-attach.
- **IOPS ratio**: io1 = 50 IOPS/GB, io2 = 500 IOPS/GB. Formula: Max IOPS = GB x ratio.
- **Queue length**: SSD -> low queue (low latency). HDD -> high queue (maximum throughput).
- io1 minimum 100 IOPS, maximum absolute 64,000. io2 Block Express up to 256,000.

## S3 vs EFS vs FSx vs EBS

- **S3**: object storage, HTTP API, does NOT support NFS/SMB, CANNOT be mounted as filesystem
- **EFS**: NFS v4, Linux, multi-AZ, thousands of simultaneous EC2s, serverless, real directories
- **FSx Windows**: SMB, Windows, Active Directory
- **FSx Lustre**: HPC, Linux, high-performance parallel filesystem
- **EBS**: block storage, 1 EC2 (multi-attach io same AZ only)
- **Exam key**: "NFS" + "Linux" + "multiple servers" -> EFS. "SMB" + "Windows" -> FSx Windows

## AWS Storage Gateway

- Bridge between on-premises and AWS. VM/appliance in your datacenter that connects with AWS.
- **File Gateway**: NFS/SMB -> S3 (your apps see a network folder, AWS stores objects in S3)
- **Volume Gateway**: iSCSI -> S3/EBS snapshots (your apps see a hard drive, block storage)
  - Cached: data in S3, local cache | Stored: data local, backup to S3
- **Tape Gateway**: iSCSI -> S3 Glacier (replaces physical tapes, compatible with Veeam/Veritas)
- S3 is object storage, but File Gateway makes it look like file storage from on-prem
- **Exam key**: "file protocols/NFS/SMB" -> File GW. "iSCSI/block" -> Volume GW. "tape/backup software" -> Tape GW

## Parameter Store vs Secrets Manager

- **Parameter Store**: general config + secrets, **FREE** (standard), SecureString + KMS, hierarchical (/app/prod/db), NO automatic rotation
- **Secrets Manager**: secrets only, **$0.40/secret/month**, automatic rotation integrated with RDS/Redshift/DocumentDB
- Both encrypt with KMS
- **Exam key**: "cost-effective" + general config -> Parameter Store. "Automatic rotation" -> Secrets Manager
- OpsCenter is NOT for storing config (it is for incident management)

## DynamoDB: Capacity and Auto Scaling

- **On-Demand mode**: scales automatically, pay per request, no managing RCU/WCU, more expensive
- **Provisioned mode** (default): you define RCU/WCU, cheaper if traffic is predictable
  - Created with **Console**: Auto Scaling enabled by default
  - Created with **CLI**: Auto Scaling **NOT enabled** by default -> must be activated
- **DAX (DynamoDB Accelerator)**: in-memory cache, reduces latency from ms to us, DynamoDB only, compatible with DynamoDB API
- **Global Tables**: multi-region replication for global apps
- DynamoDB CANNOT be a CloudFront origin
- **Exam key**: if it says "created with CLI" -> Auto Scaling is probably not enabled

## RDS: Multi-AZ (Standby) vs Read Replica

- **Multi-AZ Standby**: high availability. SYNCHRONOUS replication (0 data loss), AUTOMATIC failover (~60-120s), you CANNOT read from it, same region different AZ.
- **Read Replica**: scale reads. ASYNCHRONOUS replication (may have lag), MANUAL promote, you CAN read from it, can be in another region.
- Multi-AZ: DNS endpoint does not change after failover. Read Replica: endpoint changes when promoted.
- Aurora combines both: readable replicas + automatic failover + up to 15 replicas.
- **Exam key**: "AZ outage" + "automatic failover" -> Multi-AZ. "Scale reads" -> Read Replica.

## Aurora Failover

- **With replicas**: flips CNAME of the endpoint -> replica is promoted to primary (~30s). Always CNAME, never A record.
- **Without replicas (single instance)**: creates new instance in **another AZ first**, if it cannot -> original AZ (~10-15 min)
- Aurora uses CNAME, not A record. Connection string does not change after failover.

## RDS Stop vs Snapshot+Terminate

- **RDS Stop**: no compute charge but auto-restarts after **7 days maximum**. You still pay for storage.
- **Snapshot + Terminate**: no compute or instance storage charge. Only snapshot storage ($0.05/GB). Restore when needed.
- For intermittently used DBs (testing, dev) -> Snapshot + Terminate is more cost-effective
- Restoring from snapshot takes a few minutes

## RDS: Basic vs Enhanced Monitoring

- **Basic** (free, hypervisor): CPU Utilization, Database Connections, Freeable Memory, IOPS, Latency, Swap -- seen from "outside"
- **Enhanced** (extra, agent inside the OS): OS processes, RDS child processes, CPU per core, memory breakdown, file system -- seen from "inside"
- Trick: if it sounds like "operating system" or "processes" -> Enhanced. If it sounds like "general DB metric" -> Basic.
- Enhanced explains the WHY (which process uses CPU), Basic only the WHAT (CPU at 90%)

## Lambda: Execution Role vs Resource Policy + KMS

- **Execution Role** (IAM Role): what Lambda can do OUTWARD (S3, DynamoDB, KMS, etc.)
- **Resource Policy**: who can INVOKE Lambda FROM OUTSIDE (S3 trigger, API GW, SNS, cross-account)
- **KMS double authorization**: need permission on BOTH sides (caller's IAM + KMS Key Policy)
- KMS Key Policy Principal must be the **Execution Role ARN**, NOT the function ARN
  - KMS sees the caller's identity = the role Lambda assumes, not the function itself
  - Lambda function ARN is not a valid IAM principal for KMS
- **Exam key**: "Lambda decrypt KMS" -> kms:Decrypt in execution role + KMS key policy grants to the execution role

## Cost Explorer vs AWS Budgets

- **Cost Explorer**: analyze past costs + future forecast. Has API (GetCostAndUsage, GetCostForecast). For: "how much did I spend/will I spend?"
- **AWS Budgets**: budget alerts. Notifies via SNS/email when you reach a limit. Can execute actions (stop instances). Does NOT have API to extract cost data. For: "notify me if I spend more than $X"
- **Exam key**: "programmatically access costs" + "forecast" -> Cost Explorer API

## ALB Access Logs + Monitoring

- **Access Logs**: DISABLED by default. Enabled in ALB attributes -> go to S3 every 5 min (.gz)
  - Contain: client IP, latencies, status codes, request URL, user-agent, per request
- **CloudWatch Metrics**: enabled by default. AGGREGATED metrics (RequestCount, ResponseTime). Not per request.
- **CloudTrail**: records who modified the ALB (API management calls), NOT client HTTP requests.
- **X-Ray**: distributed tracing between services, not ALB access logs.
- **Exam key**: "client IP" + "latencies" + "every request" -> ALB access logs (S3)

## AWS Config

- **24/7 auditor**: records resource configuration, evaluates compliance with rules, remediates
- **Config Rules**: 300+ predefined managed rules (required-tags, encrypted-volumes, no-public-ip, etc.)
- **Detects** existing NON-COMPLIANT resources (retrospective), does not prevent
- **Remediation**: can execute SSM Automation to auto-correct
- Config vs SCP: Config DETECTS (after), SCP PREVENTS (before, does not detect existing)
- Config vs Tag Policies: Config detects missing tags, Tag Policies only standardize names
- Config vs CloudTrail: Config = configuration compliance, CloudTrail = who did what (API calls)
- **Exam key**: "detect/check non-compliant" + "least effort" -> AWS Config rule

## CloudTrail Defaults

- Enabled by default in all accounts
- Logs encrypted with **SSE-S3 (AES-256) by default** -- no configuration needed
- Management events captured by default. Data events are optional.
- Destination: S3 (not Glacier directly). CloudTrail uses AES-256, not AES-128.
- Optional: SSE-KMS (audit trail of who reads logs), multi-region trail, CloudWatch Logs integration

## Service Health Dashboard vs Personal Health Dashboard

- **Service Health Dashboard**: GENERAL status of all AWS services, public, not specific to your account
- **Personal Health Dashboard (PHD)**: events that affect YOUR specific resources (hardware retirement, maintenance, degradation)
- PHD integrates with EventBridge to automate notifications
- **Exam key**: "events affecting YOUR resources" / "upcoming events" -> Personal Health Dashboard + EventBridge + SNS

## Amazon WorkSpaces + Directory Services

- **WorkSpaces**: virtual desktops in the cloud (DaaS), Windows/Linux, replace physical PCs
- **AWS Directory Service**: integrates Active Directory with AWS
  - AD Connector: proxy to on-prem AD (does not store data in AWS)
  - AWS Managed Microsoft AD: full AD in AWS with trust to on-prem
- **Typical pattern**: VPN (connects networks) + Directory Service (AD authentication) + WorkSpaces (desktops)
- ClassicLink = deprecated, connected EC2-Classic with VPC (no longer relevant)

## IAM: Authentication vs Authorization

- **Authentication** (who you are): Console = password, CLI/API = Access Keys, EC2 = IAM Role
- **Authorization** (what you can do): IAM Policies
- New IAM User: has NO password, NO access keys, NO permissions -> cannot do anything
- For API calls you need BOTH: Access Keys (authentication) + IAM Policy (authorization)
- Best practice: IAM Identity Center (SSO) with temporary credentials instead of permanent access keys
- MFA is extra security, not a requirement for API calls

## S3 Encryption: SSE-S3 vs SSE-KMS vs SSE-C

- **SSE-S3**: AWS manages everything, free, no audit trail, no key control. Default.
- **SSE-KMS**: KMS manages master key, envelope encryption, audit trail in CloudTrail, configurable automatic rotation, $1/key/month
- **SSE-C**: you provide the key in each request, no audit trail, manual rotation, if you lose the key you lose the data
- **Envelope encryption**: master key (never leaves KMS) -> encrypts data key -> encrypts data. Each object has its own data key.
- **KMS Rotation**: creates new key material, keeps old for decrypt, key ID does not change, transparent
- **Audit trail**: only SSE-KMS generates logs in CloudTrail (who, which key, when)
- **Exam key**: "envelope encryption" + "audit trail" + "key rotation" -> SSE-KMS

## S3 Classes and Retrieval Times

- **ms retrieval**: Standard, Intelligent-Tiering, Standard-IA, One Zone-IA, Glacier Instant
- **min-hrs**: Glacier Flexible (1min-12hrs)
- **12-48hrs**: Glacier Deep Archive
- **One Zone-IA**: 20% cheaper than Standard-IA, 1 AZ only, for **reproducible** data
- **Intelligent-Tiering**: auto-moves between tiers, charges monitoring fee. Useful if you do NOT know the access pattern.
- Lifecycle rules can be applied to **specific prefixes** (each prefix different class)
- **Exam key**: "reproducible" + "ms retrieval" + "cost-effective" -> One Zone-IA. "No retrieval requirement" -> Glacier

## SSL/TLS: Wildcard vs SAN vs SNI

- **Wildcard** (*.domain.com): subdomains of the SAME domain only. Does not work for different domains.
- **SAN** (Subject Alternative Name): multiple domains in 1 cert. But must RE-ISSUE when adding a domain.
- **SNI** (Server Name Indication): ALB with multiple certificates on 1 listener. Adding a domain = upload new cert without touching existing ones. ACM free.
- CloudFront dedicated IPs = $600/month per cert (pre-SNI option, expensive)
- **Exam key**: "multiple different domains" + "without reprovision" + "cost-effective" -> SNI on ALB with multiple ACM certs

## Where to Import SSL/TLS Certificates

- **ACM (AWS Certificate Manager)**: primary service, generates free certs + imports third-party, automatic renewal
- **IAM Certificate Store**: legacy method, import only (does not generate), no auto renewal, for regions without ACM
- Both are valid for importing certs from external CAs
- CloudFront USES certs but does not store them (gets them from ACM/IAM). Certs for CF must be in **us-east-1**
- S3 is NOT a cert management service, cannot be associated with ALB/CloudFront

## S3 Transfer Acceleration vs Snow Family

- **Transfer Acceleration**: uses edge locations + AWS backbone to accelerate cross-continent uploads. $0.04/GB extra.
  - Improves effective throughput (reduces latency/packet loss), does NOT increase your bandwidth
  - Cross-continent: 130-500% improvement. Close to bucket: ~0% (not worth it)
  - Uploads only (downloads -> CloudFront)
  - Not useful for massive migrations, the bottleneck is volume not the route
- **Snowball Edge**: physical device 80TB, shipped by courier, ~1-2 weeks total
- **Snowcone**: 8-14TB, 2kg, remote environments
- **Snowmobile**: 100PB, literal truck, exabytes
- **Rule**: if it takes >1 week via internet -> Snowball. Calculate: TB x 8000 / Mbps = seconds
- 250TB at 100Mbps = 231 days -> 4 Snowballs = 1-2 weeks
- Direct Connect takes months to establish, not suitable for urgent migration
- **Snowball does NOT import directly to Glacier** -- only to S3 Standard, then lifecycle to Glacier
- **S3 Gateway Endpoint != Storage Gateway**: endpoint is a network route in VPC, Storage Gateway is a VM/appliance on-prem
- "Tape backup" on-prem -> **Tape Gateway** (Storage Gateway). Backup software does not change.
- Glacier Deep Archive ($0.00099/GB) is 4x cheaper than Flexible Retrieval ($0.004/GB)
- **Exam key**: "10 years" + "once/twice a year" + "cost-effective" -> Glacier Deep Archive

## DataSync vs Storage Gateway

- **DataSync**: MOVE data from A to B (migration or recurring sync). Fast (10Gbps), incremental, scheduling. For: "migrate 50TB to S3"
- **Storage Gateway**: USE AWS storage from on-prem continuously. Permanent bridge, local cache. For: "my apps need access to S3 every day"
- "Continuous tape backup" -> Storage Gateway (Tape). "Migrate existing data" -> DataSync
- DataSync supports: on-prem NFS/SMB -> S3/EFS/FSx, and S3<->S3 cross-region/account
- DataSync can go over **internet** (default) or over **Direct Connect** (via service/VPC endpoint, private network)
- If they already have DX -> DataSync over service endpoint (not over internet)

## AWS DRS (Elastic Disaster Recovery) + DR Strategies

- **DRS**: agent on on-prem servers, continuous block-level replication to staging area in AWS (EBS). No EC2 running. On disaster -> launch EC2 from volumes.
- RPO: seconds (continuous replication). RTO: minutes (launch EC2s)
- **4 DR strategies** (from cheap/slow to expensive/fast):
  1. **Backup & Restore**: data in S3/Glacier, nothing running. RPO/RTO: hours. $
  2. **Pilot Light**: minimal core replicated (data), no EC2 running. RPO: sec, RTO: min/hrs. $$ <- DRS does this
  3. **Warm Standby**: reduced version running in AWS, scales on DR. RPO: sec, RTO: min. $$$
  4. **Multi-site Active/Active**: everything runs in both sites. RPO/RTO: ~0. $$$$
- **Exam key**: "cost-effective" + "RPO seconds" + "RTO minutes/hours" -> DRS (Pilot Light)

## Migration Services: Discovery vs MGN vs DRS

- **Application Discovery Service**: only DISCOVERS inventory (CPU, RAM, dependencies). Does NOT migrate or replicate anything. For planning.
- **MGN (Migration Service)**: lift-and-shift of VMs to AWS. Replication Agent, continuous replication, test instances, cutover. For MIGRATING permanently.
- **DRS (Disaster Recovery)**: continuous replication for DR. On-prem remains primary. For EMERGENCY backup.
- MGN and DRS use the same technology (block-level replication) but different purpose: MGN=move, DRS=backup.
- **DataSync**: migrates DATA (files), not VMs. **DMS**: migrates DATABASES. **VM Import/Export**: manual, more downtime.
- **Exam key**: "lift-and-shift" + "minimize downtime" + "VMs" -> MGN

## CloudFront Private Content: OAC + Signed URLs/Cookies

- **S3 Presigned URL**: direct access to S3, does NOT go through CloudFront, no CDN. For uploading/downloading 1 file quickly.
- **CloudFront Signed URL**: access to 1 file via CDN, can restrict by IP/date/path
- **CloudFront Signed Cookie**: access to MULTIPLE files via CDN, does not change URLs (transparent)
- **OAC (Origin Access Control)**: only CloudFront can read S3, blocks direct bucket access
- **Complete pattern**: OAC (blocks direct S3) + Signed URLs/Cookies (controls who accesses via CF)
- Origin Shield = extra CACHE layer, NOT security
- **Exam key**: "serve private content via CloudFront only" -> OAC + Signed URLs/Cookies

## AWS Direct Connect (DX)

- **Dedicated physical** connection between on-prem and AWS (not internet). Takes **weeks/months** to establish.
- Speeds: Dedicated (1/10/100 Gbps, exclusive port), Hosted (50Mbps-10Gbps, shared port)
- **VIFs**: Private VIF (->VPC), Public VIF (->public services S3 etc.), Transit VIF (->Transit Gateway)
- **DX Gateway**: a single DX accesses VPCs in multiple regions
- **Does NOT have native encryption** -- add VPN over DX if encryption is needed
- **HA**: 2 locations x 2 connections, or DX + Site-to-Site VPN as an economical backup
- **Exam key**: "consistent latency" / "high bandwidth" + on-prem -> DX. "Quickly"/"immediately" -> VPN (DX takes months)
- **DX Gateway**: global resource, connects 1 DX with multiple VPCs/TGWs without additional physical connections
- **3 ways to connect DX with VPCs**:
  1. DX + Private VIF -> 1 VPC (simple, does not scale)
  2. DX + DX GW + Private VIFs -> multiple VPCs (limit 10, VPCs do not talk to each other)
  3. DX + DX GW + Transit VIF + TGW -> all VPCs/accounts (scales, transitive) <- best practice
- **Transit Gateway**: central hub, connects VPCs/VPNs/DX, transitive, multi-account with RAM, scales to thousands
- VPC Peering is NOT transitive, is NOT associated with DX Gateway, does not scale (n*(n-1)/2 peerings)
- **Exam key**: "multiple accounts" + "existing DX" + "least overhead" -> DX Gateway + Transit Gateway
- **Multi-region**: 1 TGW per region + peering between TGWs. Traffic over AWS backbone, not internet.
- TGW supports: VPCs, VPN, DX (via DX GW), inter-region peering. Scales to thousands of attachments.
- VPN CloudHub: only connects remote sites via 1 VGW, does not scale for hundreds of VPCs.
- **Exam key**: "hundreds of VPCs" + "multiple regions" + "single gateway" -> Transit Gateway per region + peering

## EC2 Placement Groups

- **Cluster**: same AZ, same rack, ultra-low latency, 10Gbps. For HPC, ML training. If rack fails, all go down.
- **Spread**: each instance on a different rack, multi-AZ, max 7 instances/AZ. For small critical apps. Maximum availability.
- **Partition**: isolated failure groups, multi-AZ, up to 7 partitions/AZ, no instance limit. For Hadoop, Kafka, Cassandra.
- **Exam key**: "HPC" + "low-latency" + "tightly-coupled" -> Cluster placement group (1 AZ only)
- Enhanced Networking + Cluster placement = maximum network performance between instances
- **ENI** (Elastic Network Interface): basic interface, every EC2 has one
- **ENA** (Elastic Network Adapter): enhanced networking, up to 100Gbps, SR-IOV, does NOT have OS-bypass
- **EFA** (Elastic Fabric Adapter): ENA + OS-bypass (apps talk directly to network hardware), Linux only, for HPC/MPI/ML
- **Exam key**: "OS-bypass" / "HPC" + "Linux" -> EFA. "HPC" + "Windows" -> ENA (EFA OS-bypass does not work on Windows).
- **Intel 82599 VF**: legacy (10Gbps), for old instances (C3, R3). ENA is the modern replacement.
- EFA on Windows works only as regular ENA (without OS-bypass), no point in using it.

## SQS Standard vs FIFO

- **Standard**: unlimited throughput, at-least-once (CAN duplicate), best-effort ordering
- **FIFO**: exactly-once processing (NO duplicates), guaranteed order, max 300 msg/s (3000 with batching)
- Standard duplicates because it replicates across multiple servers and sometimes delivers 2 copies
- FIFO prevents with Deduplication ID (discards same message within 5 min)
- Visibility timeout: time a message is invisible after being read. Increasing it reduces duplicates from timeout, but NOT the inherent duplicates of Standard
- **Exam key**: "processed twice" / "duplicate" -> SQS FIFO
- **DLQ (Dead Letter Queue)**: queue where messages go after N failures (maxReceiveCount). Optional, works the same in Standard and FIFO.
- Failure -> message returns to queue (legitimate retry, NOT a duplicate). After N failures -> DLQ.
- FIFO eliminates simultaneous duplicate deliveries, NOT legitimate retries after failure.
- FIFO detects duplicates via: Deduplication ID (you set it) or Content-based (SHA-256 of body, automatic). Window: 5 minutes.

## AWS AppSync

- NOT just GraphQL -- it is a **data aggregation and orchestration** service for multiple data sources
- **Pipeline Resolvers**: chain functions that connect DIRECTLY to DynamoDB (without Lambda), in sequence or parallel
- One request can read/write from multiple DynamoDB tables automatically
- Serverless, no orchestration code, "operationally efficient"
- **Exam key**: "multiple DynamoDB tables" + "retrieve and write" + "operationally efficient" -> AppSync pipeline resolvers

## EKS Scaling

- **HPA (Horizontal Pod Autoscaler)**: more pods/replicas. For: web servers, APIs, microservices. Needs Metrics Server.
- **VPA (Vertical Pod Autoscaler)**: more CPU/RAM to existing pod. Requires pod restart. For: DBs, apps that do not scale horizontally.
- **Cluster Autoscaler**: more/fewer EC2 nodes based on pending pods. Legacy.
- **Karpenter**: like Cluster Autoscaler but better, faster, chooses optimal instance. AWS recommends it.
- Horizontal = more copies. Vertical = more powerful.
- **Exam key**: "more traffic/requests" -> HPA. "more resources for pod" -> VPA. "no room for pods" -> Karpenter/Cluster Autoscaler.

## VPC Endpoints: Gateway vs Interface

- **Gateway Endpoint**: entry in route table, FREE, only **S3 and DynamoDB**
- **Interface Endpoint (PrivateLink)**: creates ENI with private IP, costs ~$7.2/month + data, supports 200+ services
- S3 supports BOTH types. Use Gateway (free) unless you need access from on-prem via VPN/DX
- NAT Gateway also works but is the most expensive (~$32/month + $0.045/GB)
- **Exam key**: S3/DynamoDB + "cost-efficient" + private subnet -> Gateway Endpoint always

## S3 Event Notifications

- **Valid destinations**: SQS, SNS, Lambda, EventBridge. **NOT**: Amazon MQ, Kinesis
- Main events: `s3:ObjectCreated:*`, `s3:ObjectRemoved:*`, `s3:ObjectRestore:*`, `s3:Replication:*`
- **s3:ObjectRemoved:Delete** = permanent deletion of a specific version (with version ID)
- **s3:ObjectRemoved:DeleteMarkerCreated** = only creates delete marker (hides object, does not delete it)
- **Exam key**: "permanently deleted" -> `s3:ObjectRemoved:Delete`, NOT `DeleteMarkerCreated`
- `s3:ObjectAdded:*` does NOT exist -> the correct one is `s3:ObjectCreated:*`
- Amazon MQ (managed RabbitMQ/ActiveMQ) is NOT a destination for S3 events

## CloudFormation Attributes and Helper Scripts

- **CreationPolicy**: waits for signal (cfn-signal) before marking resource as COMPLETE. Use case: "wait until my software is ready"
- **DependsOn**: only guarantees creation order, NOT that the software inside is working
- **UpdatePolicy**: manages rolling updates in ASGs, not initial creation
- **UpdateReplacePolicy**: what to do with old resource when replacing (Delete/Retain/Snapshot)
- **DeletionPolicy**: what to do when deleting stack (Delete/Retain/Snapshot)
- Helper scripts (run inside EC2):
  - **cfn-init**: reads metadata from template, installs packages and configures
  - **cfn-signal**: sends signal to CloudFormation ("I'm ready" / "I failed") -- used with CreationPolicy
  - **cfn-hup**: daemon that detects changes in metadata and re-executes cfn-init
- **Exam key**: "ensure components running before stack proceeds" -> CreationPolicy + cfn-signal

## EC2 Instance Limits (vCPU-based)

- The limit is NO LONGER by number of instances, it is by **total vCPUs per family per region**
- Typical default: 64 vCPUs On-Demand for Standard instances (A, C, D, H, I, M, R, T, Z)
- The limit is per **region**, NOT per AZ
- To increase: Service Quotas -> EC2 -> Request increase
- Typical error: `InstanceLimitExceeded`

## RDS Storage Auto Scaling

- **It exists and is real** -- monitors free space, scales automatically when low (5 min)
- Requires configuring a **Maximum Storage Threshold**
- **Only scales up, never reduces** -- if it scales to 500GB from a spike, you pay 500GB forever
- 6h pause between scaling events, minimum increment of 10%
- **Not default because**: unpredictable cost, masks problems (runaway logs, unpurged data), irreversible storage
- **Exam key**: "LEAST operational overhead" + capacity problem -> auto scaling always

## NACLs vs Security Groups

- **Security Groups = STATEFUL**: if you allow inbound, the outbound response is automatic
- **NACLs = STATELESS**: you need explicit rules for inbound AND outbound
- **Ephemeral ports (32768-65535)**: server responses go out on these ports, NOT on the service port
- To allow incoming HTTPS in a NACL you need:
  - Inbound: TCP 443 from 0.0.0.0/0
  - Outbound: TCP 32768-65535 to 0.0.0.0/0 (for the response)
- NACLs are evaluated in **numerical rule order** (first match wins)
- Security Groups evaluate **all rules together** (ALLOW only, no order)
- SG applies at the ENI level (instance), NACL applies at the subnet level
- **Default NACL**: allows everything (usually not the problem in questions)
- **Non-default / custom NACL**: denies everything by default -> must configure inbound + outbound
- **Default SG**: allows all outbound, denies all inbound -> add inbound rule
- **NACLs in real life**: rarely touched, used to block specific IPs (SGs cannot DENY) or for compliance
- **Exam key**: if they mention "non-default NACL" or "blocks all" -> you always need rules in both directions

## ASG Scaling Policies

- **Target Tracking**: "keep CPU at 50%". AWS manages everything (alarms, adjustments). The simplest.
- **Step Scaling**: YOU define alarms, thresholds and multiple steps (CPU 60%->+1, 80%->+3, 90%->+5). "Set of adjustments".
- **Simple Scaling**: one threshold, one action, cooldown. Legacy.
- **Scheduled**: at specific time/date (predictable patterns).
- **Exam key**: "set of adjustments" + "specify thresholds" + "CloudWatch alarms" -> Step Scaling. "Maintain metric at X" -> Target Tracking.

## ASG Lifecycle Hooks

- Allow pausing launch or terminate to execute actions before completing
- **Launch**: `Pending:Wait`. **Terminate**: `Terminating:Wait` (do NOT confuse)
- Correct event to act during termination: `EC2 Instance-terminate Lifecycle Action` (instance still alive)
- `EC2 Instance Terminate Successful` = already terminated, too late
- Pattern: Lifecycle hook -> EventBridge -> Lambda -> CloudWatch Agent (push logs) -> CompleteLifecycleAction
- Configurable timeout up to 48h

## VPC DNS Settings

- **DNS Resolution** (enableDnsSupport): can the VPC resolve DNS? Default: enabled in all VPCs.
- **DNS Hostnames** (enableDnsHostnames): do EC2s receive a public DNS hostname?
  - Default VPC: enabled. Custom VPC: **disabled by default** <- exam trick
- For EC2 to have a DNS hostname: DNS Resolution ON + DNS Hostnames ON + public IP
- Route 53 does not control whether an EC2 receives a hostname (it is an external DNS service)

## NAT Gateway

- NAT Gateway goes in **public subnet**, EC2s in **private subnet**
- Private subnet route: `0.0.0.0/0 -> NAT Gateway`
- Allows OUTBOUND traffic to internet, blocks INBOUND traffic from internet
- NAT GW needs an EIP and access to the IGW (that is why it goes in public subnet)
- EIP on EC2 = accessible from internet (NOT the same as NAT GW)

## AI/ML Text Services

- **Textract**: extracts text from PDF/images (OCR). Only extracts, does not analyze.
- **Comprehend**: NLP on text -- sentiment, entities, generic PII. NOT medical-specific.
- **Comprehend Medical**: detects medical PHI (Protected Health Information) -- HIPAA compliance.
- **Transcribe**: audio -> text (speech-to-text). Does NOT work for PDFs.
- **Polly**: text -> audio. **Rekognition**: images/video. **Macie**: detects PII in S3.
- "Textract Medical" does NOT exist as a service.
- **Exam key**: PDF + medical PHI -> Textract (extract) + Comprehend Medical (identify PHI)
- **NACL evaluation**: rules in NUMERICAL ORDER, first match wins. An ALLOW in rule 100 wins over DENY in rule 200
- Rule * (asterisk) = default DENY, always last
- Trick: find the rule with the lowest number that matches the traffic -> that one decides

## Route 53: Alias vs CNAME

- **CNAME**: maps DNS name -> another DNS name. **Does NOT work at zone apex** (root domain like `example.com`)
- **Alias**: Route 53 proprietary extension. Maps DNS name -> AWS resource. **DOES work at zone apex**
- Alias is created as type A (IPv4) or AAAA (IPv6) with "Alias" flag enabled
- **Alias is free** (no query charges), CNAME does charge
- Alias supports: ALB, NLB, CloudFront, S3 website, Elastic Beanstalk, API Gateway, Global Accelerator
- Alias does **NOT support**: EC2 DNS name -> use CNAME or direct IP
- **Zone apex** = naked domain = root domain (`example.com` without www)
- ALB does not have a fixed IP -> a regular A record with IP does not work
- **Exam key**: you see "zone apex" or "root domain" -> the answer is always **Alias record (type A)**
- You see an AWS resource as destination -> prefer Alias (free + apex)
- CNAME only when the destination is external (not AWS)

## ALB with On-Premises Targets + Weighted Target Groups

- Target Groups have type **instance** (EC2) or type **ip** (any reachable IP)
- With type **ip** you can register IPs of on-premises servers if there is Direct Connect or VPN
- **ALB supports Weighted Target Groups**: a listener rule can forward to multiple target groups with different weights (e.g., 50/50)
- **NLB does NOT support** weighted forwarding to multiple target groups -> ALB only
- To distribute traffic with weights between on-prem and AWS: ALB Weighted TG or Route 53 Weighted routing
- Route 53 **Failover** = active/passive (backup), does NOT distribute traffic proportionally
- Route 53 **Weighted** = distributes traffic by percentage between endpoints
- **Exam key**: gradual migration on-prem -> AWS with % of traffic -> ALB Weighted TG + Route 53 Weighted

## SSM Run Command vs CodePipeline

- **Run Command** (part of Systems Manager): executes commands/scripts on EC2 **without SSH/RDP**, uses SSM Agent
- **CodePipeline**: CI/CD pipeline (Source -> Build -> Deploy). For deploying applications, not for configuring instances
- **EC2Config**: legacy Windows service, initial configuration only. Not for remote commands
- **AWS Config**: audits compliance of AWS resources. Does not execute anything
- **Exam key**: "without SSH/RDP" + "configure instances" + "Systems Manager" -> **Run Command**

## WAF vs Network Firewall vs NACLs

- **WAF**: layer 7 (HTTP). Block by **country** (geo-match), IPs, SQLi, XSS, rate limiting. Associates with ALB/CloudFront/API Gateway
- **Network Firewall**: layer 3-4. Deep inspection (IDS/IPS), **outbound domain** filtering, stateful/stateless rules. More expensive and complex
- **NACLs**: layer 3-4. Simple IP/port rules per subnet. ~20 rule limit. Does not support country blocking
- NACLs cannot block a country -> thousands of changing IP ranges, insufficient rule limit
- **Exam key**: "block country" -> **WAF geo-match** always
- **Network Firewall is correct when**: egress domain filtering, non-HTTP traffic, IDS/IPS, inter-VPC inspection
- Quick rule: WAF = protect web apps (HTTP ingress). Network Firewall = control network traffic (egress, non-HTTP, IDS/IPS)

## Connectivity Between VPCs and Services

- **VPC Endpoint**: VPC -> AWS service (S3, DynamoDB, SSM). Does NOT connect VPC to VPC
- **VPC Peering**: VPC <-> VPC directly (same or different region). Requires updating **route tables** in both VPCs
- **Transit Gateway**: central hub to connect many VPCs + on-prem (hub-and-spoke)
- **NAT Gateway**: private subnet -> Internet. NOT for connecting VPCs
- **Egress-only IGW**: NAT Gateway but for IPv6. Also does not connect VPCs
- **Exam key**: "transfer data between VPCs without Internet" -> VPC Peering + update route tables

## EBS Snapshots During Use

- Snapshots are **asynchronous**: the volume remains available for read AND write during the snapshot
- You can detach/attach the volume during the snapshot without problems
- The snapshot captures the **point-in-time** state of the moment it is initiated
- First snapshot = full. Subsequent = incremental (only changed blocks)
- Stored in S3 (managed by AWS, not visible in your buckets)

## Trusted Advisor Service Limits

- Monitors current usage vs AWS service quotas
- Requires **Business support plan** minimum (Developer does NOT include full checks)
- Data becomes **stale** -> need to refresh with `RefreshTrustedAdvisorCheck` API (Lambda every 24h)
- `DescribeTrustedAdvisorChecks` only **lists** available checks, does NOT execute them
- For notifications: EventBridge captures TA events -> SNS notifies
- **AWS Config** does NOT monitor service quotas -> Config is for resource configuration compliance

## NAT Gateway vs NAT Instance

- Both give outbound internet access to EC2 in private subnet, without allowing inbound
- **NAT Gateway**: managed, automatic HA, scales on its own, ~$32/month. Recommended by AWS
- **NAT Instance**: regular EC2 doing NAT, you manage everything, but can be cheaper (t3.nano ~$3/month)
- **Exam key**: question says "managed" / "least overhead" -> NAT Gateway. Says "cost-effective" / "cheapest" -> NAT Instance

## Aurora Cloning

- Creates a DB copy in **seconds** using copy-on-write (does not copy data, shares pointers)
- No impact on production, almost no additional storage cost
- Only available in **Aurora**, not in regular RDS
- RDS alternative = snapshot + restore -> takes hours for large DBs
- mysqldump = takes hours + consumes production CPU
- **Exam key**: "copy DB quickly without impact" -> Aurora Cloning
- "Cost-effective" does not always = cheapest service. Sometimes the most efficient saves more overall

## Egress-Only Internet Gateway vs NAT Gateway

- **Egress-Only IGW**: **IPv6** only. Allows outbound, blocks inbound. Free.
- **NAT Gateway**: **IPv4** only. Allows outbound, blocks inbound. ~$32/month.
- **Exam key**: IPv4 -> NAT Gateway. IPv6 -> Egress-Only IGW. Never the reverse.

## EBS Encryption By Default

- Activated at the **region** level, not per individual volume
- Automatically encrypts new volumes and restores from unencrypted snapshots
- EBS always uses **symmetric** keys (AES-256). Asymmetric (RSA, ECC) do NOT work for EBS
- Encrypted snapshots -> restored volumes are always encrypted (cannot be decrypted)
- **Exam key**: "automatically encrypt all new volumes" -> Encryption By Default (region)

## Cluster Placement Group - Insufficient Capacity

- Cluster PG places instances on the **same physical rack** -> limited rack capacity
- "Insufficient capacity error" = the current rack does not have space for more instances
- Solution: **Stop + Start** all instances -> AWS relocates them to a rack with more capacity
- **Stop != Reboot**: Stop+Start can change physical host. Reboot does NOT change host
- Do NOT create another Placement Group -> would separate instances onto different racks, losing low latency

## S3 Storage Classes - Minimum Storage Duration

- **S3 Standard**: no minimum. You pay only for what you use
- **S3 Standard-IA / One Zone-IA**: minimum **30 days**. Delete earlier -> you pay for 30 days anyway
- **Glacier Flexible**: minimum **90 days**
- **Glacier Deep Archive**: minimum **180 days**
- **Exam key**: temporary data (hours, a few days) -> **S3 Standard** is cheaper than IA/Glacier due to the minimum duration charge

## DynamoDB vs Redshift - When to Use Each

- **DynamoDB**: key-value, latency in **milliseconds**, individual operations (get/put). Real-time
- **Redshift**: data warehouse, SQL queries on TB of data, latency in **seconds/minutes**. Analytics
- **Exam key**: "millisecond response" / "real-time" -> DynamoDB. "Analytics" / "reporting" / "historical" -> Redshift
- Kinesis Data Streams = real-time (ms). Firehose = near real-time (minimum 60s buffer)

## Kinesis Shards

- Each shard: 1 MB/s input, 2 MB/s output, 1000 records/s
- More traffic -> **UpdateShardCount** (add shards). Less traffic -> **MergeShards** (reduce)
- PartitionKey determines which shard each record goes to (hash)
- Kinesis does NOT have native auto-scaling like ASG. Scales manually with UpdateShardCount
- **Exam key**: "Kinesis slow" / "performance degraded" -> increase shards

## Global Accelerator

- Provides **2 static AnyCast IPs** that never change, route to resources in any region
- Works with on-premises: traffic goes to the 2 IPs -> AWS global network -> nearest ALB
- Supported endpoints: ALB, NLB, EC2 instances, Elastic IP. NOT private IPs directly
- **Global Accelerator vs CloudFront**: GA = routes traffic layer 4 (network). CloudFront = caches content layer 7 (HTTP)
- **Exam key**: "static IP" + "multiple regions" or "whitelist" + "reduce IPs" -> Global Accelerator

## ECS Scaling - Two Levels

- **ECS Service** (tasks/containers): scales by service CPU, service memory, requests per target
- **ECS Cluster** (EC2 instances): scales by service CPU/memory, Capacity Provider
- They are different layers: more tasks need more EC2s to run on
- ALB does not have a CPU metric (it is managed). "ALB CPU high" is a trap
- "ALB endpoint unreachable" is not a scaling metric, it is a health check

## ACM Certificate Expiration Monitoring

- ACM publishes the **DaysToExpiry** metric in CloudWatch automatically
- ACM emits events in **AWS Health** when certificate is about to expire
- Both are captured with **EventBridge** -> SNS to notify
- ACM certificates on ALB are **automatically renewed** (if DNS validation works)
- ACM Private CA does NOT automatically renew -> more overhead, not recommended as a solution

## EMR Nodes and Spot Instances

- **Primary**: manages cluster. On-Demand ALWAYS. If it dies, everything dies
- **Core**: store data (HDFS) + process. On-Demand if you cannot lose data
- **Task**: process only, no data. **Spot is safe** -> if they die there is no data loss
- **Transient cluster**: created, runs job, destroyed. Cheaper than long-running for periodic jobs
- EMR Serverless does NOT support Apache Ranger (table/column-level permissions)
- **Exam key**: "no data loss" + "cost-effective" -> Primary/Core On-Demand + Task Spot

## NLB Does Support HTTP Health Checks

- NLB operates at layer 4 (TCP) but its health checks can be HTTP/HTTPS
- TCP health check only verifies port is open. HTTP health check verifies status code (200 OK)
- Changing health check from TCP to HTTP = changing one setting, minimal overhead
- Replacing NLB with ALB = changing the entire load balancer, much more overhead
- **Exam key**: "least overhead" -> modify what exists, do not replace components

## AWS Transfer Family + Storage

- Transfer Family supports SFTP, FTPS, FTP. Integrates with **S3 or EFS**
- S3: object storage, no IOPS, not a real filesystem
- EFS: filesystem, high IOPS, serverless, multi-AZ (highly available)
- EBS: single AZ, mounts on one EC2, NOT serverless, does NOT integrate with Transfer Family
- **Public endpoint**: has no Security Group, does not filter IPs
- **VPC endpoint + Elastic IP**: has Security Group -> filters approved IPs
- **Exam key**: "SFTP" + "high IOPS" + "serverless" -> EFS + Transfer Family + VPC endpoint

## FSx Services - Protocols

- **FSx for NetApp ONTAP**: NFS + SMB + iSCSI (all three). Unique multi-protocol
- **FSx for OpenZFS**: NFS only
- **FSx for Windows File Server**: SMB only
- **EFS**: NFS only
- **Exam key**: "multi-protocol" (NFS + SMB + iSCSI) -> always FSx for NetApp ONTAP

## S3 Glacier Retrieval Times

- **Glacier Instant Retrieval**: milliseconds (immediate)
- **Glacier Flexible Retrieval**: 1-5 min (expedited), 3-5h (standard), 5-12h (bulk)
- **Glacier Deep Archive**: 12h (standard), 48h (bulk)
- "Retrieve within minutes" -> discard Deep Archive
- One Zone-IA is NOT good for **backups** (if AZ goes down, you lose data)
- **Lifecycle transition minimums**: Standard -> Standard-IA/One Zone-IA = **minimum 30 days**. Standard -> Glacier = **no minimum**
- Transitioning to Standard-IA at 7 days is **NOT possible** (violates 30-day minimum)
- **Exam key**: if you need to move data before 30 days -> Glacier (no restriction). IA only after 30 days

## AWS Backup Vault Lock - Compliance vs Governance

- **Compliance mode**: NOBODY can delete/modify, not even root user. Total immutability
- **Governance mode**: users with special IAM permissions CAN delete/modify
- **Exam key**: "cannot delete or alter" / "compliance" -> Compliance mode. "Protect but admin override" -> Governance mode

## Lambda Execution Role vs Resource-based Policy

- **Execution Role**: what the Lambda can do (access DynamoDB, S3, etc.) -> OUTBOUND permissions
- **Resource-based Policy**: who can invoke the Lambda -> INBOUND permissions
- Cross-account invoke Lambda -> **Resource-based Policy** with the other account as principal
- "Least privilege" -> specific action (`lambda:InvokeFunction`), never `lambda:*`

## KMS Key Types - Rotation Control

- **AWS owned**: AWS controls, you see nothing. No rotation control
- **AWS managed** (aws/ebs): rotates every year automatically, you CANNOT change the period
- **Customer managed**: you activate rotation and define the period. Control + low overhead
- **External/imported**: manual rotation (import new key). Maximum control but maximum overhead
- **Exam key**: "control rotation" + "least overhead" -> Customer managed key

## ALB Sticky Sessions

- Cookie that makes a user always go to the same instance
- Needed for **stateful** apps (session in instance RAM)
- Unnecessary for **stateless** apps (session in external Redis/DynamoDB)
- Sticky sessions + uneven traffic = one overloaded instance
- **Exam key**: "stateless" + "traffic to one instance" -> disable sticky sessions

## DataSync Preserves Windows File Permissions

- **DataSync** is the only service that preserves NTFS permissions, metadata, timestamps, ownership
- Migrate Windows files to FSx -> DataSync directly (agent on-prem -> FSx)
- **Never go through S3** as intermediary -> S3 is object storage, loses NTFS ACLs
- AWS CLI copy also does not preserve Windows permissions
- Snowcone can run DataSync agent AMI (via OpsHub) for slow connections

## FSx for Lustre - Persistent vs Scratch

- **FSx for Lustre**: parallel filesystem for HPC, ML, rendering. Hundreds of GB/s throughput
- **Persistent**: data replicated, recovers if hardware fails. Highly available
- **Scratch**: data NOT replicated, lost if it fails. For temporary jobs only. Not HA
- **Amazon File Cache**: temporary cache for hybrid data (S3/on-prem). Not persistent storage
- **Exam key**: "HPC" + "parallel" + "highly available" -> FSx for Lustre Persistent

## Lake Formation - Column-level Security

- **Lake Formation**: data lake governance. Supports column-level, row-level, cell-level security
- **Lake Formation blueprints**: ingest data from RDS/Aurora to S3 automatically (incremental)
- **Data filters**: granular control by column (marketing only sees certain columns)
- IAM policies and S3 bucket policies do NOT support column-level access
- **Exam key**: "column-level access" in data lake -> Lake Formation, never IAM
