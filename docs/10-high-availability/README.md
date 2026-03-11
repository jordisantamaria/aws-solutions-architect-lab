# 10 - High Availability and Disaster Recovery

## Table of Contents

- [Fundamental Concepts: HA vs FT vs DR](#fundamental-concepts-ha-vs-ft-vs-dr)
- [RPO and RTO](#rpo-and-rto)
- [Disaster Recovery Strategies](#disaster-recovery-strategies)
- [Multi-AZ Architectures](#multi-az-architectures)
- [Multi-Region Architectures](#multi-region-architectures)
- [ELB Health Checks](#elb-health-checks)
- [Auto Scaling for High Availability](#auto-scaling-for-high-availability)
- [Route 53 Health Checks and Failover](#route-53-health-checks-and-failover)
- [AWS Backup](#aws-backup)
- [AWS Elastic Disaster Recovery (DRS)](#aws-elastic-disaster-recovery-drs)
- [Chaos Engineering - AWS Fault Injection Simulator](#chaos-engineering---aws-fault-injection-simulator)
- [Exam Tips](#exam-tips)

---

## Fundamental Concepts: HA vs FT vs DR

These three concepts are frequently confused on the exam. Understanding their differences is essential.

### Definitions

| Concept | Definition | Objective | Example |
|---|---|---|---|
| **High Availability (HA)** | Ability of a system to remain operational and accessible for a high percentage of time. Accepts brief interruptions during failover. | Minimize downtime | RDS Multi-AZ: if the primary instance fails, failover to standby takes ~60-120 seconds |
| **Fault Tolerance (FT)** | Ability of a system to continue operating **without any interruption** when a component fails. Zero downtime. | Zero interruption | An airplane with multiple engines: if one fails, the others maintain flight without passengers noticing |
| **Disaster Recovery (DR)** | Set of policies, tools, and procedures to recover infrastructure and data after a catastrophic event. | Recover after a disaster | Restore operations in another AWS region after an entire region goes down |

### Relationship Between Concepts

```
Fault Tolerance (FT)
  └── Is the highest level: zero interruption
  └── Example: S3 (11 9s of durability), DynamoDB Global Tables

High Availability (HA)
  └── Accepts brief interruption during failover
  └── Example: RDS Multi-AZ, ELB with ASG in multiple AZs

Disaster Recovery (DR)
  └── Recovery after a major disaster
  └── Example: Restore from backup in another region

Cost: FT > HA > DR (basic)
```

---

## RPO and RTO

Two fundamental metrics for designing DR strategies.

### Recovery Point Objective (RPO)

**RPO** = Maximum amount of data that the organization can afford to lose, measured in time.

```
Last backup             Failure point              Recovery
     │                      │                      │
     ▼                      ▼                      ▼
─────●──────────────────────●──────────────────────●─────
     │◄────── RPO ─────────►│                      │
     │   (data lost)        │                      │
```

**Examples:**
- RPO of 1 hour: You can lose up to 1 hour of data. You need backups at least every hour.
- RPO of 0: You cannot lose any data. You need real-time synchronous replication.

### Recovery Time Objective (RTO)

**RTO** = Maximum acceptable time to restore the system and return to normal operation after a failure.

```
Failure point                              Full recovery
     │                                        │
     ▼                                        ▼
─────●────────────────────────────────────────●─────
     │◄──────────── RTO ─────────────────────►│
     │   (downtime)                           │
```

**Examples:**
- RTO of 4 hours: The system must be operational within 4 hours after a failure.
- RTO of minutes: You need solutions like Multi-AZ with automatic failover.

> **Key point for the exam:**
> - **RPO** answers: "How much data can I lose"
> - **RTO** answers: "How long can I be down"
> - Lower RPO/RTO = Higher cost

---

## Disaster Recovery Strategies

AWS defines 4 DR strategies, ordered from lowest to highest cost and from highest to lowest RTO/RPO.

### Strategy Comparison

| Strategy | RPO | RTO | Cost | Description |
|---|---|---|---|---|
| **Backup & Restore** | Hours | 24+ hours | Low ($) | Create periodic backups and restore when needed |
| **Pilot Light** | Minutes | Tens of minutes | Medium-low ($$) | Keep a minimal version of the environment always on (core services) |
| **Warm Standby** | Seconds-Minutes | Minutes | Medium-high ($$$) | Reduced but functional version of the full environment always running |
| **Multi-Site / Hot Standby** | Near zero | Seconds-Minutes | High ($$$$) | Full active-active environment in multiple regions |

### Detail of Each Strategy

#### 1. Backup & Restore

```
Primary Region (Active)                  DR Region
┌─────────────────────┐        ┌──────────────────────┐
│  EC2, RDS, EBS      │        │                      │
│  (all operational)  │───────►│  S3 (backups)        │
│                     │ backup │  EBS Snapshots        │
│                     │        │  RDS snapshots        │
└─────────────────────┘        └──────────────────────┘

In case of disaster: restore everything from backups (hours)
```

- **How it works:** Regular backups to S3, EBS/RDS snapshots copied to another region.
- **When to use:** Non-critical applications where hours of downtime are acceptable.
- **AWS services:** S3 Cross-Region Replication, EBS Snapshots, RDS Automated Backups, AWS Backup.

#### 2. Pilot Light

```
Primary Region (Active)                  DR Region (Pilot Light)
┌─────────────────────┐        ┌──────────────────────┐
│  Web servers (ASG)  │        │  (no web servers)    │
│  App servers (ASG)  │        │  (no app servers)    │
│  RDS Primary        │───────►│  RDS Read Replica    │
│                     │ replica│  (only DB is on)     │
└─────────────────────┘        └──────────────────────┘

In case of disaster: promote RDS replica, launch EC2s with ASG (minutes)
```

- **How it works:** Only critical components (database) are on. The rest is provisioned when DR is activated.
- **When to use:** Applications with RPO of minutes and acceptable RTO of tens of minutes.
- **AWS services:** RDS Cross-Region Read Replicas, pre-configured AMIs, Launch Templates ready.

#### 3. Warm Standby

```
Primary Region (Active)                  DR Region (Warm Standby)
┌─────────────────────┐        ┌──────────────────────┐
│  Web (ASG: 4 inst.) │        │  Web (ASG: 1 inst.)  │
│  App (ASG: 4 inst.) │        │  App (ASG: 1 inst.)  │
│  RDS Multi-AZ       │───────►│  RDS Read Replica    │
│  (full size)        │ replica│  (reduced size)      │
└─────────────────────┘        └──────────────────────┘

In case of disaster: scale instances, promote RDS (minutes)
```

- **How it works:** A reduced but fully functional version of the environment always running.
- **When to use:** Important applications with RTO of minutes.
- **AWS services:** ASG with minimum capacity, RDS Read Replicas, Route 53 health checks with failover.

#### 4. Multi-Site / Hot Standby

```
Primary Region (Active)                  Secondary Region (Active)
┌─────────────────────┐        ┌──────────────────────┐
│  Web (ASG: 4 inst.) │        │  Web (ASG: 4 inst.)  │
│  App (ASG: 4 inst.) │        │  App (ASG: 4 inst.)  │
│  Aurora Global DB   │◄──────►│  Aurora Global DB     │
│  (write)            │ replica│  (read/write)         │
└─────────────────────┘        └──────────────────────┘
         │                              │
         └──────────┬───────────────────┘
                    │
            Route 53 (Active-Active)
```

- **How it works:** Full active-active environment in both regions. Traffic distributed.
- **When to use:** Critical applications with RPO/RTO close to zero.
- **AWS services:** Route 53 latency-based routing, Aurora Global Database, DynamoDB Global Tables, CloudFront.

---

## Multi-AZ Architectures

High availability patterns using multiple Availability Zones within the same region.

### Patterns by Service

| Service | Multi-AZ Pattern | Failover | Notes |
|---|---|---|---|
| **RDS** | Multi-AZ deployment: synchronous standby instance in another AZ | Automatic (~60-120s). Changes the DNS endpoint. | Standby is NOT readable. Use Read Replicas for reads. |
| **Aurora** | Up to 15 Read Replicas across multiple AZs. Storage replicated 6 times across 3 AZs. | Automatic (~30s). Promotes a Read Replica. | Faster than standard RDS Multi-AZ. |
| **ELB** | ALB/NLB deploys nodes in multiple AZs automatically | N/A (actively distributes traffic across AZs) | Enable Cross-Zone Load Balancing for uniform distribution. |
| **ASG** | Configure subnets in multiple AZs | Launches new instances in healthy AZs | Specify at least 2 AZs. 3 is better for greater resilience. |
| **S3** | Automatic: data replicated across minimum 3 AZs | N/A (transparent) | 99.999999999% (11 9s) durability. |
| **DynamoDB** | Automatic: data replicated across 3 AZs | N/A (transparent) | No additional configuration needed. |
| **EFS** | Automatic: storage replicated across multiple AZs | N/A (transparent) | One Zone mode available for savings (without HA). |
| **ElastiCache** | Multi-AZ with automatic failover (Redis) | Automatic for Redis with replicas | Memcached does not support Multi-AZ with automatic failover. |
| **OpenSearch** | Deployment in 2 or 3 AZs with replicas | Automatic | Requires minimum 2 nodes per AZ for production. |

### Typical Multi-AZ Architecture Pattern

```
                    Route 53
                       │
                ┌──────▼──────┐
                │     ALB     │ (Multi-AZ automatic)
                └──────┬──────┘
                       │
          ┌────────────┼────────────┐
          │            │            │
    ┌─────▼─────┐┌────▼─────┐┌────▼─────┐
    │  EC2 (AZ-a)││ EC2 (AZ-b)││ EC2 (AZ-c)│
    │  (ASG)    ││  (ASG)   ││  (ASG)   │
    └─────┬─────┘└────┬─────┘└────┬─────┘
          │            │            │
          └────────────┼────────────┘
                       │
                ┌──────▼──────┐
                │ RDS Multi-AZ │
                │ Primary (AZ-a)│
                │ Standby (AZ-b)│
                └─────────────┘
```

---

## Multi-Region Architectures

For protection against region-level failures.

### Multi-Region Patterns by Service

#### Route 53 Failover Routing

```
                   Route 53 (Failover Policy)
                       │
          ┌────────────┼────────────┐
          │                         │
    Primary (us-east-1)      Secondary (eu-west-1)
    Health check: HEALTHY     Health check: monitoring
          │                         │
    ┌─────▼─────┐           ┌──────▼──────┐
    │   ALB     │           │    ALB      │
    │   ASG     │           │    ASG      │
    │   RDS     │           │    RDS      │
    └───────────┘           └─────────────┘

If primary fails → Route 53 redirects to secondary automatically
```

#### Aurora Global Database

- **Replication:** One primary cluster (read/write) and up to 5 secondary clusters (read-only) in other regions.
- **Replication latency:** Less than 1 second between regions.
- **Failover:** Promote a secondary cluster to primary in less than 1 minute.
- **RPO:** Typically < 1 second.
- **RTO:** Typically < 1 minute.

#### DynamoDB Global Tables

- **Replication:** Active-Active. Tables replicated across multiple regions.
- **Read/Write:** Can read and write in any region.
- **Conflict resolution:** Last writer wins (timestamp-based).
- **Replication latency:** Typically < 1 second.
- **Requirement:** DynamoDB Streams must be enabled.

#### S3 Cross-Region Replication (CRR)

- **Configuration:** Replication rule between source bucket and destination bucket in another region.
- **Requirements:** Versioning enabled on both buckets.
- **Behavior:** Only replicates new and modified objects (not retroactive; use S3 Batch Replication for existing objects).
- **Options:** Can change the storage class at the destination and/or change ownership.

---

## ELB Health Checks

ELB health checks determine whether instances behind the load balancer are healthy to receive traffic.

### Types of Health Checks

| Type | Protocol | Description | Example |
|---|---|---|---|
| **HTTP/HTTPS** | HTTP(S) GET | Verifies that a specific path returns code 200 | `GET /health` returns 200 OK |
| **TCP** | TCP | Verifies that the port is accepting connections | TCP connection to port 443 successful |
| **SSL** | TLS | Verifies TLS connection | TLS handshake successful |

### Health Check Parameters

| Parameter | Description | Typical Value |
|---|---|---|
| **Interval** | Health check frequency | 30 seconds |
| **Timeout** | Maximum response wait time | 5 seconds |
| **Unhealthy Threshold** | Consecutive failed checks to mark as unhealthy | 2 |
| **Healthy Threshold** | Consecutive successful checks to mark as healthy | 5 (CLB), 3 (ALB/NLB) |
| **Path** | HTTP path for verification | /health or /status |

### Behavior

- If an instance fails the health check, the ELB **stops sending traffic to it**.
- The instance is NOT automatically terminated (the ASG does that if configured with ELB health checks).
- **Important:** The ASG can use EC2 status checks or ELB health checks. For HA, configure the ASG to use **ELB health checks**, as they are more granular.

---

## Auto Scaling for High Availability

### ASG Configuration for HA

| Configuration | Recommended Value | Justification |
|---|---|---|
| **AZs** | Minimum 2, ideally 3 | Resilience against AZ failure |
| **Min capacity** | >= number of AZs | At least 1 instance per AZ |
| **Desired capacity** | Based on current load | Maintain adequate performance |
| **Max capacity** | 2x desired or more | Capacity to handle spikes |
| **Health check type** | ELB | More accurate than EC2 status checks |
| **Health check grace period** | App startup time | Avoid terminating instances that are starting |

### Scaling Policies

| Policy | Description | Use Case for HA |
|---|---|---|
| **Target Tracking** | Maintain a metric at a target value | Keep CPU at 50% to have headroom |
| **Step Scaling** | Scale based on CloudWatch alarm thresholds | Aggressive scaling for sudden changes |
| **Scheduled Scaling** | Scale based on predefined schedule | Pre-scale before known peaks |
| **Predictive Scaling** | ML to predict future demand | Anticipate traffic patterns |

### ASG Pattern for Maximum HA

```
ASG Configuration:
  Min: 3 (one per AZ)
  Desired: 6
  Max: 12

  AZ-a: 2 instances
  AZ-b: 2 instances
  AZ-c: 2 instances

If AZ-a fails:
  ASG automatically redistributes:
  AZ-b: 3 instances
  AZ-c: 3 instances
```

---

## Route 53 Health Checks and Failover

### Types of Health Checks

| Type | Description | Use Case |
|---|---|---|
| **Endpoint** | Monitors a specific endpoint (IP, domain, URL) | Verify that a server or load balancer responds |
| **Calculated** | Combines results from multiple health checks with AND/OR logic | Verify that at least 2 of 3 components are healthy |
| **CloudWatch Alarm** | Based on the state of a CloudWatch alarm | Health check based on custom metrics |

### Endpoint Health Check

- Route 53 sends requests from **multiple global locations** (health checkers).
- If more than **18%** of health checkers report the endpoint as healthy, Route 53 considers it healthy.
- Supports HTTP, HTTPS, and TCP.
- For HTTP/HTTPS, can verify that the response body contains a specific string (search in the first 5120 bytes).

### Failover Routing Policy

```
Client ──► Route 53
              │
              ├── Primary record (us-east-1) ← Health Check
              │     └── If HEALTHY → responds with primary IP
              │
              └── Secondary record (eu-west-1) ← Health Check (optional)
                    └── If primary UNHEALTHY → responds with secondary IP
```

### Failover Types with Route 53

| Routing Policy | Model | Description |
|---|---|---|
| **Failover** | Active-Passive | One primary and one secondary. Traffic to secondary only if primary fails. |
| **Weighted** | Active-Active (with weights) | Distribute traffic between regions with weights (e.g., 70/30). |
| **Latency-based** | Active-Active (by latency) | Routes user to the region with lowest latency. |
| **Geolocation** | Active-Active (by location) | Routes based on the user's geographic location. |

> **Key point for the exam:** For DR Active-Passive use **Failover routing**. For Active-Active use **Weighted**, **Latency**, or **Geolocation**.

---

## AWS Backup

Centralized service for managing and automating backups of multiple AWS services.

### Supported Services

EC2, EBS, RDS, Aurora, DynamoDB, EFS, FSx, Storage Gateway, S3, Neptune, DocumentDB, SAP HANA on EC2, VMware (on-premises).

### Main Components

| Component | Description |
|---|---|
| **Backup Plan** | Defines the policy: frequency, backup window, retention, transition to cold storage |
| **Backup Vault** | Storage container for backups. Can be encrypted with KMS. |
| **Backup Vault Lock** | WORM (Write Once Read Many) protection to prevent deletion or modification of backups. Two modes: **Compliance** (nobody can delete, not even root or AWS) and **Governance** (only admins with special permissions can modify) |
| **Recovery Point** | An individual backup within a vault |
| **Resource Assignment** | Which resources are included in the backup plan (by tags or ARNs) |

### Cross-Region and Cross-Account Backup

```
Account A (Production)                   Account B (Backup)
Region us-east-1                         Region eu-west-1
┌──────────────────┐                ┌──────────────────┐
│  Backup Plan     │                │                  │
│  ┌────────────┐  │   Cross-Region │  Backup Vault    │
│  │ RDS backup │──│───────────────►│  (copy)          │
│  │ EBS backup │──│── Cross-Account│                  │
│  │ DynamoDB   │  │───────────────►│  Vault Lock      │
│  └────────────┘  │                │  (WORM)          │
└──────────────────┘                └──────────────────┘
```

- **Cross-Region:** Automatically copy backups to another region for DR.
- **Cross-Account:** Copy backups to a separate account for protection against account compromise.
- **Vault Lock:** WORM policy. Two modes:

| Mode | Who can delete/modify | Use Case |
|---|---|---|
| **Compliance** | **Nobody** (not root, not AWS Support). Irreversible once applied. | Strict regulatory compliance (HIPAA, SEC Rule 17a-4). "Nobody must be able to delete backups under any circumstances." |
| **Governance** | Only users with specific IAM permissions can override. Reversible. | Protection against accidental deletion but with flexibility for admins. |

> **Key point for the exam:** If the question says "protect backups so nobody can delete them, not even root" → **Vault Lock Compliance mode**. If it says "protect against accidental deletion but allow admin override" → **Vault Lock Governance mode**.

---

## AWS Elastic Disaster Recovery (DRS)

Service that facilitates disaster recovery, formerly known as CloudEndure Disaster Recovery.

### How It Works

```
Source environment                         AWS (DR Region)
(on-prem or cloud)
┌──────────────────┐   continuous       ┌──────────────────┐
│  Servers with    │   replication      │  Staging Area    │
│  DRS agent       │──────────────►     │  (low-cost       │
│                  │  (block-level)     │   instances)     │
└──────────────────┘                    └────────┬─────────┘
                                                 │
                                      Drill/Recovery (launch)
                                                 │
                                       ┌─────────▼─────────┐
                                       │  Recovery Instances│
                                       │  (configured type  │
                                       │   and size)        │
                                       └───────────────────┘
```

### Key Features

- **Continuous replication:** Replicates data at block level from the source server to a staging area in AWS.
- **RPO:** Typically seconds (continuous replication).
- **RTO:** Typically minutes (launch instances from the replica).
- **Drill (simulation):** Allows DR drills without affecting replication or the production environment.
- **Failback:** Once the disaster is resolved, allows returning to the original environment.
- **Cost:** You only pay for the staging area (lightweight instances + storage) until recovery is activated.

### DRS vs MGN

| Feature | DRS (Disaster Recovery) | MGN (Migration) |
|---|---|---|
| **Purpose** | Disaster recovery | Migration to AWS |
| **Replication** | Continuous (always active) | Temporary (until migration is complete) |
| **Post-migration use** | Remains active as a DR solution | Deactivated after migration |
| **Failback** | Yes, supported | Not applicable |

---

## Chaos Engineering - AWS Fault Injection Simulator

### Chaos Engineering Concept

A discipline of experimentation where **faults are intentionally injected** into production or pre-production systems to discover weaknesses before real failures occur.

### AWS Fault Injection Simulator (FIS)

Fully managed service for running chaos engineering experiments on AWS.

### Supported Actions

| Service | Possible Actions |
|---|---|
| **EC2** | Stop/terminate instances, inject CPU stress, inject memory stress, network packet loss |
| **ECS** | Stop tasks, drain container instances |
| **EKS** | Terminate pods, inject node failures |
| **RDS** | Force Multi-AZ instance failover, reboot instances |
| **Network** | Network disruptions (latency, packet loss) between AZs or subnets |
| **Systems Manager** | Execute SSM documents to simulate OS-level failures |

### FIS Experiment Components

| Component | Description |
|---|---|
| **Experiment Template** | Defines actions, targets, stop conditions, and IAM role |
| **Actions** | What faults to inject (e.g., stop EC2 instances) |
| **Targets** | What resources are affected (by tags, ARNs, filters, % of resources) |
| **Stop Conditions** | CloudWatch Alarms that stop the experiment if a safety threshold is exceeded |
| **IAM Role** | Role with permissions to execute actions on targets |

### Experiment Example

```
Experiment Template:
  Action: aws:ec2:stop-instances
  Target: EC2 instances with tag "Environment=Production" (30%)
  Stop Condition: Alarm "ErrorRate > 10%"
  Duration: 10 minutes

Objective: Verify that the ASG detects stopped instances,
          replaces them, and the service remains available through the ALB.
```

> **Key point for the exam:** FIS is used to **test architecture resilience**. Questions usually ask how to verify that an HA architecture actually works under failures.

---

## Exam Tips

### Frequently Asked Questions and Quick Answers

| Exam Scenario | Answer |
|---|---|
| RPO of 0, RTO of minutes | **Multi-Site / Hot Standby** with Aurora Global Database |
| RPO of hours, low budget | **Backup & Restore** |
| Keep only the DB on in the DR region | **Pilot Light** |
| Reduced version of the full environment in DR | **Warm Standby** |
| Protect backups against deletion | **AWS Backup Vault Lock** |
| Verify that the HA architecture works | **AWS Fault Injection Simulator** |
| DR with RPO of seconds and RTO of minutes | **AWS Elastic Disaster Recovery (DRS)** |
| Replicate DynamoDB between regions | **DynamoDB Global Tables** |
| Replicate S3 between regions | **S3 Cross-Region Replication (CRR)** |
| Automatic DNS failover | **Route 53 Failover routing** with health checks |
| Database with failover < 1 min between regions | **Aurora Global Database** |
| Centralized backup of multiple services | **AWS Backup** |
| ASG that detects application errors (not just EC2) | Configure **ELB health checks** in the ASG |
| Ensure minimum instances in each AZ | ASG with **multiple AZs** and adequate min capacity |

### Summary Table: RPO / RTO / Cost

| Strategy | RPO | RTO | Relative Cost |
|---|---|---|---|
| Backup & Restore | Hours | 24+ hours | $ |
| Pilot Light | Minutes | 10-30 minutes | $$ |
| Warm Standby | Seconds-Minutes | Minutes | $$$ |
| Multi-Site | ~0 | Seconds-Minutes | $$$$ |

### Common Mistakes to Avoid

1. **Confusing Pilot Light with Warm Standby:** Pilot Light only has the database on. Warm Standby has the entire stack but at reduced size.
2. **Forgetting that RDS Multi-AZ standby is not readable:** The standby instance is only for failover, not for read queries. Use Read Replicas for reads.
3. **Not considering Multi-Site cost:** If the question mentions limited budget, Multi-Site is probably not the answer.
4. **Confusing HA with DR:** Multi-AZ is HA (same region). Multi-Region is DR (protection against region failure).
5. **Confusing DRS with MGN:** DRS is for continuous DR, MGN is for one-time migration.
6. **Not enabling DynamoDB Streams for Global Tables:** It's a prerequisite that may appear on the exam.
7. **Assuming S3 CRR replicates existing objects:** It only replicates new objects. For existing ones, use S3 Batch Replication.
