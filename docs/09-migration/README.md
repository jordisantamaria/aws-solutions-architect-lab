# 09 - Migration to AWS

## Table of Contents

- [AWS Cloud Adoption Framework (CAF)](#aws-cloud-adoption-framework-caf)
- [Migration Strategies: The 7 Rs](#migration-strategies-the-7-rs)
- [AWS Migration Hub](#aws-migration-hub)
- [AWS Application Discovery Service](#aws-application-discovery-service)
- [AWS Application Migration Service (MGN)](#aws-application-migration-service-mgn)
- [AWS Database Migration Service (DMS)](#aws-database-migration-service-dms)
- [AWS Snow Family](#aws-snow-family)
- [AWS Transfer Family](#aws-transfer-family)
- [AWS DataSync](#aws-datasync)
- [VMware Cloud on AWS](#vmware-cloud-on-aws)
- [Exam Tips](#exam-tips)

---

## AWS Cloud Adoption Framework (CAF)

The AWS Cloud Adoption Framework provides a structured guide for planning cloud migration. It is organized into **6 perspectives** grouped into two categories.

### Business Perspectives (Business Capabilities)

| Perspective | Focus | Key Stakeholders |
|---|---|---|
| **Business** | Align cloud investments with business objectives. Ensure the cloud generates measurable value. | CEO, CFO, COO, CIO |
| **People** | Organizational change management, training, roles, and team structure for cloud adoption. | HR, CIO, training directors |
| **Governance** | Risk management, regulatory compliance, budget management, and project portfolio in the cloud. | CIO, CTO, CFO, CDO |

### Technical Perspectives (Technical Capabilities)

| Perspective | Focus | Key Stakeholders |
|---|---|---|
| **Platform** | Cloud architecture design, service selection, definition of infrastructure patterns and standards. | CTO, architects, engineers |
| **Security** | Identity management, data protection, threat detection, and incident response in the cloud. | CISO, security team |
| **Operations** | Defining how cloud services will be operated: monitoring, incident management, automation. | IT Operations, Site Reliability Engineers |

> **Key point for the exam:** When a question mentions "planning the migration" or "evaluating organizational readiness for the cloud", think CAF. The Business and People perspectives are the most relevant for managing organizational change.

---

## Migration Strategies: The 7 Rs

The 7 Rs represent the available strategies for migrating each application or workload to the cloud.

```
Lower effort <──────────────────────────────────────► Higher effort
  Retire → Retain → Relocate → Rehost → Replatform → Repurchase → Refactor
```

### Detail of Each Strategy

| Strategy | Description | Example | Effort | Cloud Benefit |
|---|---|---|---|---|
| **Retire** | Eliminate applications that are no longer needed. | Legacy system nobody uses | Minimal | N/A (savings through elimination) |
| **Retain** | Keep on-premises (don't migrate now). Revisit later. | App with complex dependencies, strict compliance | None | None (for now) |
| **Relocate** | Move to AWS without changes, using VMware Cloud on AWS or similar. | Move the entire VMware hypervisor to AWS | Low | Low-Medium |
| **Rehost** | "Lift and shift". Move as-is to the cloud (EC2). No code changes. | Move a web server to EC2 using MGN | Low | Low |
| **Replatform** | "Lift, tinker and shift". Small optimizations without changing the core architecture. | Migrate on-prem MySQL to RDS MySQL, Elastic Beanstalk | Medium | Medium |
| **Repurchase** | Switch to a different SaaS product. "Drop and shop". | Move custom CRM to Salesforce, email to Office 365 | Medium | Medium-High |
| **Refactor** | Re-architect the application to leverage cloud-native services. | Decompose monolith into microservices with Lambda, ECS, DynamoDB | High | High |

### When to Use Each Strategy

```
Is the application needed? ──NO──► Retire
         │
        YES
         │
Can it be migrated now? ──NO──► Retain
         │
        YES
         │
Is it a complete VMware environment? ──YES──► Relocate
         │
        NO
         │
Are minimal changes needed? ──YES──► Rehost (MGN)
         │
        NO
         │
Can it be slightly optimized? ──YES──► Replatform (RDS, Beanstalk)
         │
        NO
         │
Is there an equivalent SaaS? ──YES──► Repurchase
         │
        NO
         │
        Refactor (cloud-native)
```

---

## AWS Migration Hub

**AWS Migration Hub** is a centralized service that provides a **single dashboard** for tracking migration progress across multiple AWS tools and partners.

### Key Features

- **Unified view:** Shows the status of all migrations in one place.
- **Integration:** Connects with AWS MGN, AWS DMS, and partner tools (CloudEndure, etc.).
- **Application tracking:** Allows grouping servers and databases by application to track the complete migration of each app.
- **No additional cost:** You only pay for the underlying migration services.

### Workflow

```
Application Discovery Service    AWS MGN
         │                          │
         └──────────┬───────────────┘
                    │
            Migration Hub (central dashboard)
                    │
         ┌──────────┴───────────────┐
         │                          │
    AWS DMS              Partner tools
```

---

## AWS Application Discovery Service

A service that helps **discover and collect information** about on-premises servers and applications to plan migration.

### Discovery Modes

| Feature | Agentless Discovery (Connector) | Agent-Based Discovery |
|---|---|---|
| **Deployment** | Virtual appliance (OVA) in VMware vCenter | Agent installed on each server (Windows/Linux) |
| **Data collected** | CPU, memory, disk, VM information, network configuration | All of the above + running processes, network connections, detailed performance |
| **Level of detail** | Basic (hardware and configuration) | Detailed (dependencies between applications, traffic patterns) |
| **Use case** | Quick initial VM inventory | Deep dependency analysis for planning migration groupings |
| **Requirements** | VMware vCenter only | Root/admin access on each server |
| **Dependencies** | Does not map dependencies | Yes, maps dependencies between servers |

### Integration with Athena and S3

- Discovered data can be exported to **S3** and analyzed with **Amazon Athena** to create SQL queries on the server inventory.
- Can be visualized with **Amazon QuickSight** to generate dashboards of the on-premises environment.

> **Key point for the exam:** If the question asks to "map dependencies between applications" or "understand which servers communicate with each other", the answer is **Agent-Based Discovery**.

---

## AWS Application Migration Service (MGN)

AWS MGN (formerly CloudEndure Migration) is the recommended service for the **Rehost (Lift and Shift)** strategy.

### How It Works

```
On-Premises                         AWS
┌──────────────┐    continuous     ┌──────────────────────┐
│  Source       │    replication   │  Staging Area        │
│  server with │ ──────────────►  │  (low-cost instances  │
│  MGN agent   │    (block-level) │   for replication)    │
│              │                  │                      │
└──────────────┘                  └──────────┬───────────┘
                                             │
                                   Cutover (launch)
                                             │
                                  ┌──────────▼───────────┐
                                  │  Target Instances     │
                                  │  (final instances     │
                                  │   with correct type)  │
                                  └──────────────────────┘
```

### Key Features

- **Continuous replication:** Replicates data at block level without affecting the source server.
- **Staging Area:** Uses lightweight instances and inexpensive EBS storage to maintain the replica.
- **Testing:** Allows launching test instances to validate before cutover.
- **Minimal cutover:** When cutting over, simply launches the final instances with the latest replicated data.
- **Supported platforms:** Physical servers, VMware, Hyper-V, Azure, GCP, and other clouds.
- **Supported OS:** Windows and Linux.

> **Key point for the exam:** MGN = Rehost = Lift and Shift. This is the answer when asked about migrating servers to AWS with minimal downtime and no application changes.

---

## AWS Database Migration Service (DMS)

DMS allows migrating databases to AWS securely with **minimal downtime**. The source database remains operational during the migration.

### Homogeneous vs Heterogeneous Migrations

| Type | Description | Tools | Example |
|---|---|---|---|
| **Homogeneous** | Same database engine for source and destination | DMS only | Oracle → RDS Oracle, MySQL → Aurora MySQL |
| **Heterogeneous** | Different database engine for source and destination | SCT + DMS | Oracle → Aurora PostgreSQL, SQL Server → RDS MySQL |

### AWS Schema Conversion Tool (SCT)

SCT is used **only in heterogeneous migrations** to convert the source database schema to the destination engine format.

```
Homogeneous Migration:
  Oracle on-prem ──── DMS ────► RDS Oracle

Heterogeneous Migration:
  Oracle on-prem ──── SCT (converts schema) ──── DMS (migrates data) ────► Aurora PostgreSQL
```

### DMS Components

- **Replication Instance:** EC2 instance running the replication software.
- **Source Endpoint:** Connection to the source database.
- **Target Endpoint:** Connection to the destination database.
- **Replication Task:** Defines the migration task (full load, CDC, or both).

### Migration Types

| Type | Description | Use Case |
|---|---|---|
| **Full Load** | Migrates all existing data at once | Migrations with a maintenance window |
| **CDC (Change Data Capture)** | Only replicates incremental changes | Continuous replication |
| **Full Load + CDC** | Migrates existing data and then captures changes | Migration with minimal downtime (most common) |

### Supported Sources and Destinations

- **Sources:** Oracle, SQL Server, MySQL, MariaDB, PostgreSQL, MongoDB, SAP ASE, S3, IBM Db2
- **Destinations:** RDS (all engines), Aurora, Redshift, DynamoDB, S3, Elasticsearch, Kinesis Data Streams, DocumentDB, Neptune, Redis

> **Key point for the exam:**
> - If the question says database migration with a different engine → **SCT + DMS**
> - If the question says database migration with the same engine → **DMS only**
> - DMS can be used for continuous replication (CDC), not just one-time migrations

---

## AWS Snow Family

The Snow family is used for **offline data migration** when network transfer is not viable (limited bandwidth, massive volumes, remote locations).

### Device Comparison

| Feature | Snowcone | Snowcone SSD | Snowball Edge Storage Optimized | Snowball Edge Compute Optimized | Snowmobile |
|---|---|---|---|---|---|
| **Usable storage** | 8 TB HDD | 14 TB SSD | 80 TB | 42 TB | 100 PB |
| **Compute** | 2 vCPUs, 4 GB RAM | 2 vCPUs, 4 GB RAM | 40 vCPUs, 80 GB RAM | 104 vCPUs, 416 GB RAM, optional GPU | N/A |
| **Use case** | Lightweight edge computing, small migration | Edge with higher SSD storage | Large data migrations, edge computing | ML processing at edge, video | Exabyte-scale migrations |
| **Weight** | 2.1 kg (4.5 lbs) | 2.1 kg (4.5 lbs) | ~23 kg (50 lbs) | ~23 kg (50 lbs) | Truck with container |
| **DataSync** | Pre-installed agent | Pre-installed agent | No (uses Snow client) | No (uses Snow client) | N/A |
| **Clustering** | No | No | Up to 5-10 devices | Up to 5-10 devices | N/A |

### Estimated Transfer Times: Network vs Snow

| Data Volume | 100 Mbps | 1 Gbps | 10 Gbps | Recommended Snow Solution |
|---|---|---|---|---|
| 10 TB | ~12 days | ~30 hours | ~3 hours | Snowcone / network (depends on urgency) |
| 100 TB | ~120 days | ~12 days | ~30 hours | Snowball Edge |
| 1 PB | ~3 years | ~120 days | ~12 days | Snowball Edge (multiple devices) |
| 10 PB+ | Decades | Years | ~120 days | Snowmobile |

### General Rule for the Exam

> If network transfer takes **more than one week**, consider using Snow Family.

### Snow Workflow

```
1. Request a Snow device from the AWS console
2. AWS ships the physical device
3. Connect the device and load data (Snow client or DataSync)
4. Return the device to AWS
5. AWS loads the data into S3
6. AWS securely erases the device (NIST 800-88)
```

### Snowball Edge - Types

- **Storage Optimized:** Maximum storage (80 TB). Ideal for large data migrations and local storage.
- **Compute Optimized:** Maximum compute (104 vCPUs). Ideal for ML processing, video analysis at edge. Optional NVIDIA Tesla V100 GPU.

---

## AWS Transfer Family

A **fully managed** service for transferring files to and from Amazon S3 or Amazon EFS using standard protocols.

### Supported Protocols

| Protocol | Port | Encryption | Use Case |
|---|---|---|---|
| **SFTP** (SSH File Transfer Protocol) | 22 | Yes (SSH) | Most common, secure transfers |
| **FTPS** (FTP over SSL/TLS) | 21/990 | Yes (TLS) | Legacy systems requiring FTP with encryption |
| **FTP** (File Transfer Protocol) | 21 | No | Within VPC only (not public). Legacy systems |
| **AS2** (Applicability Statement 2) | 443 | Yes | B2B exchange (EDI, supply chain) |

### Key Features

- **Public or VPC endpoint:** Can be exposed to the internet or kept private within a VPC.
- **Route 53 integration:** Custom DNS (sftp.mycompany.com).
- **Authentication:** AWS Directory Service, custom IdP (Lambda), SSH keys.
- **Backend storage:** S3 or EFS.
- **No server management:** AWS manages the infrastructure.

> **Key point for the exam:** When the question mentions "transfer files using SFTP/FTP to S3" or "replace existing FTP server", the answer is **AWS Transfer Family**.

---

## AWS DataSync

A service for **fast and automated data transfer** between on-premises storage and AWS services, or between AWS services.

### Transfer Scenarios

```
On-Premises → AWS:
  NFS/SMB Server ──► DataSync Agent ──► (Internet or Direct Connect) ──► S3, EFS, FSx

AWS → AWS:
  S3 ──► DataSync ──► EFS
  EFS ──► DataSync ──► FSx for Windows
  (No agent needed for transfers between AWS services)
```

### Key Features

| Feature | Detail |
|---|---|
| **Speed** | Up to 10 Gbps per task, uses optimized transfer protocols |
| **Automation** | Scheduled tasks (hourly, daily, weekly) |
| **Compression** | Compresses data in transit to optimize bandwidth |
| **Encryption** | TLS in transit, KMS integration for encryption at rest |
| **Verification** | Automatically verifies data integrity |
| **Metadata preservation** | Preserves permissions, timestamps, and filesystem attributes |
| **Filtering** | Can include/exclude files based on patterns |
| **Bandwidth** | Configurable limit to avoid saturating the network |

### DataSync vs Other Services

| Service | Best For | Transfer |
|---|---|---|
| **DataSync** | Data migration and recurring synchronization, NFS/SMB to AWS | Online, automated |
| **Snow Family** | Large volumes (>10 TB) when the network is slow | Offline, physical |
| **Transfer Family** | File exchange using SFTP/FTP with external clients | Online, standard protocol |
| **Storage Gateway** | Continuous hybrid access (local cache + storage in S3) | Online, continuous hybrid |

> **Key point for the exam:** DataSync is for **moving data** (migration or synchronization). Storage Gateway is for **continuous hybrid access**. Don't confuse them.

---

## VMware Cloud on AWS

Allows running **VMware vSphere** directly on AWS infrastructure with native access to AWS services.

### Use Cases

- **VMware data center migration** to AWS without re-architecting (Relocate strategy).
- **Capacity extension:** Expand the on-premises VMware environment to AWS to handle demand spikes.
- **Disaster Recovery:** Use AWS as a DR site for VMware workloads.
- **Gradual modernization:** Maintain VMware while progressively migrating applications to native AWS services.

### Features

- Runs VMware vSphere, vSAN, and NSX directly on dedicated AWS hardware.
- Access to native AWS services (S3, RDS, Lambda, etc.) from VMware VMs.
- Jointly managed by VMware and AWS.
- VMs can reside in the same AZ as AWS services for low latency.

---

## Exam Tips

### Frequently Asked Questions and Quick Answers

| Exam Scenario | Service / Strategy |
|---|---|
| Migrate servers as-is (lift and shift) | **MGN** (Rehost) |
| Migrate database with same engine | **DMS** (without SCT) |
| Migrate database with different engine | **SCT + DMS** (heterogeneous) |
| Transfer 50 TB, slow network (1 week+) | **Snowball Edge** |
| Transfer 100 PB | **Snowmobile** |
| Move NFS/SMB files to S3/EFS | **DataSync** |
| SFTP server for sharing files with S3 | **Transfer Family** |
| Map dependencies between on-prem servers | **Application Discovery Service (Agent-Based)** |
| Quick VMware VM inventory | **Application Discovery Service (Agentless)** |
| Centralized migration progress dashboard | **Migration Hub** |
| Migrate entire VMware environment | **VMware Cloud on AWS** (Relocate) |
| Plan organizational cloud adoption | **Cloud Adoption Framework (CAF)** |
| Small data migration at remote edge | **Snowcone** |
| Continuous database replication | **DMS with CDC** |

### Common Mistakes to Avoid

1. **Confusing DataSync with Storage Gateway:** DataSync moves data, Storage Gateway provides continuous hybrid access.
2. **Forgetting SCT in heterogeneous migrations:** If the engines are different, SCT is always needed before DMS.
3. **Choosing Snowball for few TBs:** If the network is reasonable and volume is low (<10 TB), DataSync or direct transfer may be faster.
4. **Confusing MGN with DMS:** MGN migrates servers (complete applications), DMS migrates only databases.
5. **Not considering Relocate:** If the environment is VMware, Relocate (VMware Cloud on AWS) is valid and requires less effort than Rehost.

### Formula to Remember the 7 Rs

> **R**etire, **R**etain, **R**elocate, **R**ehost, **R**eplatform, **R**epurchase, **R**efactor
> From lowest to highest effort and from lowest to highest cloud benefit.
