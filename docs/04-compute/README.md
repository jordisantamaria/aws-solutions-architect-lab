# Compute in AWS

## Table of Contents

- [EC2 Instance Types](#ec2-instance-types)
- [EC2 Purchasing Options](#ec2-purchasing-options)
- [EC2 Placement Groups](#ec2-placement-groups)
- [EC2 Networking](#ec2-networking)
- [AMIs](#amis)
- [User Data and Instance Metadata](#user-data-and-instance-metadata)
- [Auto Scaling Groups](#auto-scaling-groups)
- [AWS Lambda](#aws-lambda)
- [ECS vs EKS vs Fargate](#ecs-vs-eks-vs-fargate)
- [Elastic Beanstalk](#elastic-beanstalk)
- [AWS Batch](#aws-batch)
- [AWS Outposts, Wavelength and Local Zones](#aws-outposts-wavelength-and-local-zones)
- [Compute Exam Tips](#compute-exam-tips)

---

## EC2 Instance Types

### Naming Convention

The name of an instance type follows the format: `m5a.xlarge`

| Part | Meaning | Example |
|-------|-------------|---------|
| **m** | Instance family | m = general purpose |
| **5** | Generation | 5th generation |
| **a** | Additional attribute (optional) | a = AMD, g = Graviton (ARM), n = networking optimized, d = NVMe local storage |
| **xlarge** | Size | nano, micro, small, medium, large, xlarge, 2xlarge... metal |

### Instance Families

#### General Purpose - Families: M, T, A

| Family | Processor | Use Case |
|---------|-----------|-------------|
| **M7g, M7i, M6i, M5** | Intel/AMD/Graviton | Balanced applications (web servers, code repositories, development environments) |
| **T3, T3a, T2** | Intel/AMD | Burstable workloads. Accumulate CPU credits |
| **A1** | Graviton (ARM) | Lightweight ARM-compatible workloads |

> **T instances (burstable):** They have a baseline CPU performance level. When the load is low, they accumulate credits. When they need more CPU, they spend credits. If credits are exhausted and the instance is in `standard` mode, performance degrades. In `unlimited` mode, extra charges apply for additional credits.

#### Compute Optimized - Family: C

| Family | Use Case |
|---------|-------------|
| **C7g, C7i, C6i, C5** | Batch processing, HPC, machine learning inference, gaming servers, media transcoding, scientific models, ad servers |

- Higher vCPU to memory ratio.
- Ideal when the bottleneck is the CPU.

#### Memory Optimized - Families: R, X, z

| Family | Use Case |
|---------|-------------|
| **R7g, R7i, R6i, R5** | In-memory databases, distributed caches (ElastiCache), real-time analytics |
| **X2idn, X2iedn, X1** | SAP HANA, Apache Spark, large-scale in-memory databases |
| **z1d** | EDA (Electronic Design Automation) applications, databases with high CPU frequency |

- Large amount of RAM.
- **R** = RAM (mnemonic to remember).

#### Storage Optimized - Families: I, D, H

| Family | Use Case |
|---------|-------------|
| **I4i, I3, I3en** | NoSQL databases (Cassandra, MongoDB), data warehousing, distributed file systems. Very high IOPS (local NVMe SSD) |
| **D3, D3en** | MapReduce, HDFS, distributed file systems. High-density HDD |
| **H1** | MapReduce, HDFS. HDD with high sequential throughput |

- Ideal when you need high local IOPS or large disk capacity.

#### Accelerated Computing - Families: P, G, Inf, Trn, F, VT

| Family | Accelerator | Use Case |
|---------|-----------|-------------|
| **P5, P4d, P3** | NVIDIA GPU (training) | Machine learning training, HPC, computational analysis |
| **G5, G4dn, G4ad** | NVIDIA/AMD GPU (graphics) | Machine learning inference, 3D graphics, gaming streaming, video transcoding |
| **Inf2, Inf1** | AWS Inferentia | High-performance machine learning inference |
| **Trn1** | AWS Trainium | Optimized machine learning training |
| **F1** | FPGA | Genomics, financial analysis, video encoding |
| **VT1** | Xilinx | Real-time video transcoding |

---

## EC2 Purchasing Options

| Option | Description | Discount | Commitment | Interruption | Ideal For |
|--------|-------------|-----------|------------|-------------|------------|
| **On-Demand** | Pay per second (Linux) or per hour (Windows) | 0% (base) | None | No | Dev/test, unpredictable workloads, first-time use |
| **Reserved Instances (Standard)** | Reservation of a specific type in a region | Up to ~72% | 1 or 3 years | No | Databases, stable 24/7 workloads |
| **Reserved Instances (Convertible)** | RI that allows changing type, family, OS, tenancy | Up to ~54% | 1 or 3 years | No | Stable workloads with possible changing requirements |
| **Savings Plans (Compute)** | Commitment of $/hour. Flexible in family, region, OS, tenancy | Up to ~66% | 1 or 3 years | No | Flexible usage across EC2, Lambda, Fargate |
| **Savings Plans (EC2 Instance)** | Commitment of $/hour. Fixed to family + region | Up to ~72% | 1 or 3 years | No | EC2 with known family and region |
| **Spot Instances** | AWS surplus capacity | Up to ~90% | None | **Yes** (2 min notice) | Batch, CI/CD, data analysis, fault-tolerant workloads |
| **Dedicated Hosts** | Complete dedicated physical server | On-Demand or Reserved | None or 1-3 years | No | BYOL licensing (per socket/core), strict compliance |
| **Dedicated Instances** | Instance on hardware dedicated to your account | Less than Dedicated Host | None | No | Hardware-level isolation without needing server control |
| **Capacity Reservations** | Reserve capacity in a specific AZ | 0% (pay On-Demand) | None | No | Guarantee availability in AZ for events or DR |

### Spot Instances - Detail

- **Spot Price**: Variable price based on supply/demand. You define a **max price**.
- **Spot Request**: One-time (launches and terminates) or Persistent (automatically relaunches if interrupted).
- **Spot Fleet**: Collection of Spot Instances (and optionally On-Demand) that meets a target capacity.
  - Strategies: `lowestPrice`, `diversified`, `capacityOptimized`, `priceCapacityOptimized` (recommended).
- **Interruption**: AWS gives a **2-minute** notice before reclaiming the instance.
  - Possible actions: `terminate`, `stop`, `hibernate`.
- **Spot Block** (deprecated in many regions): Reserve Spot for 1-6 hours without interruption.

### Spot Instances in ETL and Processing with SLA

Spot is up to 90% cheaper, but the 2-minute interruption prevents giving an exact-time SLA with pure Spot. Strategies to mitigate this:

- **Spot with fallback to On-Demand**: AWS Batch allows mixing both in the Compute Environment. Tries Spot first, if it fails uses On-Demand. Most days: cheap. Unlucky days: you still meet the SLA.
- **Time margin**: If the ETL must be ready at 08:00, launch at 04:00 with Spot. Even if interrupted 2-3 times, there is plenty of time.
- **Checkpointing + batch transactions**: The job processes data in chunks (e.g., 10K records) within DB transactions. Each completed chunk is marked in a control table. If Spot interrupts, the in-progress transaction rolls back (no partial data) and the relaunched job resumes from the last completed chunk.
- **SIGTERM handler**: When Spot is about to interrupt, it sends a SIGTERM signal to the container. Your code catches the signal and finishes the current chunk cleanly within the 2-minute grace period (then AWS sends SIGKILL).
- **Staging table pattern**: The ETL writes to a temporary table (staging). Only when EVERYTHING is processed, an atomic operation (INSERT INTO final SELECT FROM staging) moves the data to the real table. If it dies during staging, the final table remains intact.
- **Instance type diversification**: Configure multiple types (c5.xlarge, c5a.xlarge, c6i.xlarge). If one type is reclaimed, Batch uses another. Reduces the actual interruption rate.

When to use each option:
- Critical ETL with exact time (billing, compliance) -> **On-Demand** or Spot+fallback.
- ETL with wide window (entire night) -> **Spot** with retries.
- Backfill ETL without deadline -> **Pure Spot** (maximum savings).

When does the Spot engineering effort pay off?
- Spot requires designing for interruption (checkpointing, idempotency, SIGTERM handling). That effort only pays off at **large scale** (hundreds/thousands of $/month of compute).
- For a daily 30-min ETL, Spot savings are ~$1.8/month. Not worth the extra complexity. Better to use **On-Demand** or **Savings Plans** (~66% discount without interruptions, 1-3 year commitment).
- For clusters of dozens of instances, massive pipelines, ML training or CI/CD at scale -> Spot with resilience patterns more than pays off (savings of thousands of $/month).

> **Exam tip:** If the question says "fault-tolerant" or "can be interrupted" -> Spot. If it says "must complete at an exact time" -> On-Demand or Spot with fallback to On-Demand. If it says "reduce costs without interruption and with commitment" -> Savings Plans or Reserved Instances.

### Dedicated Hosts vs Dedicated Instances

| Feature | Dedicated Host | Dedicated Instance |
|---------------|---------------|-------------------|
| **Server control** | Yes (visibility of sockets, cores, host ID) | No |
| **BYOL licensing** | Yes (per socket/core/VM) | No |
| **Server affinity** | Yes (you can choose the host) | No |
| **Placement control** | Yes | No |
| **Cost** | More expensive | Less expensive than Dedicated Host |

> **Exam tip:** If the question mentions "existing licenses per socket/core" or "BYOL", the answer is **Dedicated Hosts**.

---

## EC2 Placement Groups

Placement Groups control how EC2 instances are placed on the underlying hardware.

| Strategy | Description | Pros | Cons | Use Case |
|-----------|-------------|------|---------|-------------|
| **Cluster** | Groups instances in the **same AZ, same rack** | Low network latency (10 Gbps between instances), high throughput | If the rack fails, all instances fail | HPC, Big Data jobs, applications with intensive inter-node communication |
| **Spread** | Distributes instances on **different hardware** (different racks) | Maximum hardware failure isolation | **Maximum 7 instances per AZ** per placement group | Critical applications that need high availability |
| **Partition** | Distributes instances in **logical partitions** (each partition on a different rack) | Failure isolation per partition. Up to 7 partitions per AZ | Instances in the same partition share hardware | HDFS, HBase, Cassandra, Kafka (distributed big data systems) |

### Key Differences

```
Cluster:     [Rack 1: i1, i2, i3, i4, i5]         -> All together, fast but risky

Spread:      [Rack 1: i1] [Rack 2: i2] [Rack 3: i3]  -> Separated, safe but limited to 7/AZ

Partition:   [Rack 1: i1,i2,i3] [Rack 2: i4,i5,i6] [Rack 3: i7,i8,i9]  -> Groups in separate racks
```

> **Exam tip:** If they ask about "low latency between instances" -> Cluster. If they ask "maximum hardware isolation" -> Spread. If they ask "Kafka, HDFS, Cassandra with isolation" -> Partition.

---

## EC2 Networking

### ENI (Elastic Network Interface)

- Logical network component in a VPC that represents a **virtual network card**.
- Attributes: Primary private IP, secondary private IPs, Elastic IP, public IP, MAC address, Security Groups.
- Can be **moved between instances** (in the same AZ) for failover.
- Each instance has a primary ENI (`eth0`) that cannot be detached.
- You can attach additional ENIs for multi-homing or network management scenarios.

### ENA (Elastic Network Adapter)

- Provides **Enhanced Networking** using SR-IOV (Single Root I/O Virtualization).
- Up to **100 Gbps** throughput.
- Higher PPS (packets per second) and lower latency than the standard interface.
- Supported on most modern instances.
- **No additional cost** (comes enabled on supported instance types).

### EFA (Elastic Fabric Adapter)

- Network interface for **HPC (High Performance Computing)** and **machine learning** on EC2.
- Provides low-latency, high-throughput inter-node communication.
- Supports **OS-bypass** which allows the application to communicate directly with the network hardware (Linux only).
- Used with **MPI (Message Passing Interface)** for HPC applications.

### Networking Summary

| Interface | Speed | Use Case |
|----------|-----------|-------------|
| **ENI** | Standard | General use, network failover, logging |
| **ENA** | Up to 100 Gbps (enhanced networking) | Applications that need high throughput/low latency |
| **EFA** | Maximum performance + OS-bypass | HPC, distributed machine learning |

---

## AMIs

### What is an AMI

An **Amazon Machine Image (AMI)** is a template that contains the software configuration (OS, applications, configurations) needed to launch an instance.

### AMI Types

| Type | Description |
|------|-------------|
| **AWS-provided** | Official AMIs maintained by AWS (Amazon Linux, Ubuntu, Windows Server) |
| **Marketplace** | Third-party AMIs (with or without license cost) |
| **Community** | AMIs shared by the community (verify security) |
| **Custom (own)** | AMIs created by you from a configured instance |

### Creating a Custom AMI

1. Launch an instance and configure it (install software, apply patches).
2. Stop the instance (recommended for data consistency).
3. Create the AMI (AWS creates snapshots of the EBS volumes).
4. The AMI is available to launch new identical instances.

### Cross-Region Copy

- AMIs are **regional** (only available in the region where they are created).
- You can **copy** an AMI to another region to use it there.
- The copy includes the underlying EBS snapshots.
- Encrypted AMIs can be copied across regions (with re-encryption using a KMS key from the destination region).

### AMI Sharing

- You can share an AMI with specific AWS accounts or make it public.
- If the AMI uses EBS encrypted with CMK, you must share the KMS key with the destination account.
- Sharing an AMI **does not copy** the AMI to the other account; it is referenced from the original account.
- The other account can copy the shared AMI to its own account (and re-encrypt it with its own key).

---

## User Data and Instance Metadata

### EC2 User Data

- Script that runs **only once** at the first boot of the instance.
- Runs as **root** (with administrator privileges).
- Used for:
  - Installing software and updates.
  - Downloading configuration files.
  - Starting services.
  - Registering the instance in a discovery service.
- Maximum **16 KB** in size.
- Accessible from `http://169.254.169.254/latest/user-data`.

**User Data Example:**

```bash
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "Hello from $(hostname -f)" > /var/www/html/index.html
```

### EC2 Instance Metadata (IMDS)

- Data about the instance accessible from the instance itself.
- URL: `http://169.254.169.254/latest/meta-data/`
- Available information: instance-id, instance-type, AMI-id, hostname, local IP, public IP, IAM role credentials, placement (AZ), security-groups, etc.

#### IMDSv1 vs IMDSv2

| Feature | IMDSv1 | IMDSv2 |
|---------------|--------|--------|
| **Method** | Simple GET request | Requires session token (PUT + GET) |
| **Security** | Vulnerable to SSRF (Server-Side Request Forgery) | Protected against SSRF |
| **Recommendation** | Not recommended | **Recommended** (can be configured as mandatory) |

**IMDSv2 - Flow:**

```bash
# Step 1: Get token (PUT)
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

# Step 2: Use token to query metadata (GET)
curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id
```

> **Exam tip:** If the question mentions protection against SSRF or metadata service security, the answer is **IMDSv2**. You can make IMDSv2 mandatory at the instance level or at the account level.

---

## Auto Scaling Groups

An Auto Scaling Group (ASG) allows automatically scaling the number of EC2 instances based on demand.

### Main Components

| Component | Description |
|-----------|-------------|
| **Launch Template** (recommended) | Defines the instance configuration (AMI, type, SGs, User Data, IAM role, etc.) |
| **Launch Configuration** (legacy) | Similar to Launch Template but without versioning or advanced features |
| **Min/Max/Desired capacity** | Minimum, maximum and desired number of instances |
| **Scaling Policies** | Rules that define when to scale |
| **Health Checks** | EC2 (default) or ELB health checks |
| **Cooldown Period** | Wait time after a scaling action before evaluating more actions (default: 300s) |

### Launch Template vs Launch Configuration

| Feature | Launch Template | Launch Configuration |
|---------------|----------------|---------------------|
| **Versioning** | Yes | No |
| **Multiple instance types** | Yes (mixed instances) | No |
| **Spot + On-Demand mix** | Yes | No |
| **Placement groups** | Yes | Limited |
| **T2/T3 unlimited** | Yes | No |
| **Capacity Reservations** | Yes | No |
| **Recommendation** | **Always use** | Legacy, do not use |

### Scaling Policies

#### 1. Target Tracking Scaling

- The simplest and recommended.
- Define a **target value** for a metric and the ASG adjusts capacity to maintain that value.
- Example: "Keep average CPU at 50%".
- Predefined metrics: `ASGAverageCPUUtilization`, `ASGAverageNetworkIn`, `ASGAverageNetworkOut`, `ALBRequestCountPerTarget`.
- Also supports custom CloudWatch metrics.

#### 2. Step Scaling

- Defines scaling actions based on **CloudWatch alarm thresholds**.
- Allows defining multiple steps with different actions based on severity.
- Example:
  - CPU > 70%: add 1 instance.
  - CPU > 85%: add 3 instances.
  - CPU < 30%: remove 1 instance.
- More control than Target Tracking but more complex to configure.

#### 3. Scheduled Scaling

- Scales at predefined times (schedule).
- Based on **cron expressions** or specific date/time.
- Example: "Increase to 10 instances every Friday at 17:00" (for known traffic peaks).
- Ideal for predictable and recurring traffic patterns.

#### 4. Predictive Scaling

- Uses **machine learning** to predict future traffic based on historical patterns.
- Analyzes the last 14 days of CloudWatch data.
- Provisions capacity **proactively** before the traffic peak arrives.
- Combines well with Target Tracking for real-time adjustments.
- Ideal for workloads with cyclical patterns (e.g., daily, weekly traffic).

### Lifecycle Hooks

- Allow executing custom actions when an instance enters or leaves the ASG.
- States:
  - `Pending:Wait` -> Instance launching (before entering service).
  - `Terminating:Wait` -> Instance terminating (before being removed).
- Use case: Install additional software, register with external service, save logs before terminating.
- Default timeout: 1 hour (configurable up to 48 hours or heartbeat).

### Warm Pools

- Maintains a pool of pre-initialized instances in **Stopped** or **Running** state (but out of service).
- When the ASG needs to scale, it uses instances from the warm pool instead of launching new ones from scratch.
- Significantly reduces **boot time**.
- Cost: instances in Stopped state do not incur compute cost (only EBS).

### Instance Refresh

- Allows updating all instances in the ASG with a new configuration (new AMI, new launch template).
- Defines a **minimum healthy percentage** (e.g., 90%) to maintain availability during the update.
- The ASG replaces instances gradually respecting the minimum percentage.

---

## AWS Lambda

AWS Lambda is a **serverless** compute service that runs code in response to events without provisioning or managing servers.

### Main Features

| Feature | Detail |
|---------------|---------|
| **Languages** | Node.js, Python, Java, Go, C#/.NET, Ruby, PowerShell, Custom Runtime (via Lambda Layers or container images) |
| **Memory** | 128 MB to 10,240 MB (10 GB), in 1 MB increments |
| **CPU** | Proportional to configured memory (more memory, more CPU) |
| **Timeout** | Maximum **15 minutes** (900 seconds) |
| **Ephemeral storage** | `/tmp` up to **10 GB** |
| **Package size** | 50 MB (compressed zip) or 250 MB (uncompressed). Up to **10 GB** with container images |
| **Environment variables** | Maximum 4 KB total |
| **Concurrency** | 1,000 simultaneous executions per region (soft limit, increasable) |
| **Pricing model** | Per number of invocations + duration (GB-second). Free tier: 1M requests + 400,000 GB-s/month |

### Concurrency

| Type | Description |
|------|-------------|
| **Unreserved Concurrency** | Shared concurrency pool for all functions in the account |
| **Reserved Concurrency** | Reserves a fixed number of concurrent executions for a function (no extra cost). Limits the maximum concurrency for that function |
| **Provisioned Concurrency** | Pre-initializes a number of execution environments to **eliminate cold starts**. Has additional cost |

- **Cold Start**: When Lambda must initialize a new execution environment (downloads code, starts runtime). Can add latency (ms to seconds, depending on runtime and package size).
- **Warm Start**: Reuses an existing execution environment. Much faster.

### Lambda Layers

- Packages of additional code or data mounted at `/opt` in the execution environment.
- Allow sharing libraries, SDKs, or dependencies between functions without including them in each package.
- Maximum **5 layers** per function.
- Total size (function + layers) cannot exceed 250 MB (uncompressed).

### Lambda SnapStart vs Provisioned Concurrency

Two solutions for the **cold start** problem, but with very different approaches:

| Feature | Lambda SnapStart | Provisioned Concurrency |
|---------------|-----------------|------------------------|
| **Mechanism** | Takes a snapshot of the initialized environment (after init) and reuses it | Keeps pre-initialized execution environments 24/7 |
| **Runtimes** | Only **Java** (Corretto) | All runtimes |
| **Cost** | **Free** (no additional cost) | Cost per hour for each provisioned environment |
| **Cold start reduction** | From ~5-10s to ~200ms (Java) | Eliminates cold start completely |
| **Use case** | Java functions with unacceptable cold start | Functions in any runtime that need consistent latency |

> **Exam tip:** If the question says "reduce cold start of Java function at no additional cost" -> **SnapStart**. If it says "eliminate cold start in any runtime" or "consistent latency for critical function" -> **Provisioned Concurrency** (with cost). If the function will be invoked constantly 24/7, consider whether **EC2/Fargate** is more economical than Provisioned Concurrency.

### Lambda Function URL

- Dedicated HTTP(S) endpoint for a Lambda function, **without needing API Gateway or ALB**.
- URL format: `https://<url-id>.lambda-url.<region>.on.aws`.
- Supports IAM authentication (`AWS_IAM`) or public access (`NONE`).
- Supports configurable CORS.
- Synchronous invocation only.
- **Use case**: Simple APIs, webhooks, forms, where API Gateway would be overkill.

> **Exam tip:** If the question says "expose Lambda as HTTP endpoint with minimum overhead" or "without API Gateway" -> **Lambda Function URL**.

### Lambda and VPC

- By default, Lambda runs **outside your VPC** (in the AWS VPC).
- To access resources in your VPC (RDS, ElastiCache, EC2): configure Lambda with a VPC, subnets and SGs.
- Lambda creates ENIs (Hyperplane ENIs) in the specified subnets.
- To access the Internet from Lambda in VPC: you need a **NAT Gateway** in a public subnet.
- To access AWS services from Lambda in VPC without Internet: use **VPC Endpoints**.

### Lambda + EFS: Overcoming the 10 GB Library Limit

- Lambda can mount an **EFS (Elastic File System)** as a filesystem.
- Use case: Python libraries weighing more than 10 GB (container image limit). You install the libraries on EFS once, Lambda imports them from there with `PYTHONPATH=/mnt/libs`.
- EFS has no practical size limit (petabytes).
- **Requirement**: Lambda must be in a VPC (to access EFS).
- **Tradeoff**: Slower cold start (mounting EFS + loading large libs). On warm start, EFS is already mounted and is fast.
- If invoked frequently (warm starts) -> good option. If sporadic and a 30-60s cold start is not acceptable -> better to use a Fargate Task with a large Docker image (no size limit).

### Lambda Permissions: Execution Role vs Resource Policy

Lambda has **two types of permissions** that are frequently confused on the exam:

| | Execution Role | Resource Policy |
|---|---|---|
| **What it defines** | What **Lambda** can do (what services it can call) | Who can **invoke** Lambda |
| **Direction** | Lambda -> other services | Other services -> Lambda |
| **Policy type** | Identity-based (IAM Role attached to Lambda) | Resource-based (attached to the Lambda function) |
| **Example** | Lambda needs to read from S3 and write to DynamoDB | S3 needs to invoke Lambda when an object is uploaded |

```
Execution Role (what Lambda CAN DO):
  Lambda --> S3 (GetObject)        <- needs execution role with s3:GetObject
  Lambda --> DynamoDB (PutItem)    <- needs execution role with dynamodb:PutItem

Resource Policy (who CAN INVOKE Lambda):
  S3 event --> Lambda              <- needs resource policy allowing S3 to invoke
  SNS --> Lambda                   <- needs resource policy allowing SNS to invoke
  Another AWS account --> Lambda   <- needs resource policy with cross-account principal
```

> **Exam tip:** If the question says "Lambda needs to access S3/DynamoDB/SQS" -> **Execution Role**. If it says "S3/SNS/another account needs to invoke Lambda" -> **Resource Policy**. For cross-account invocation, it is always **resource policy**.

### Lambda Destinations

- Configure where to send the result of an invocation (successful or failed).
- Supported destinations: SQS, SNS, Lambda, EventBridge.
- Recommended alternative to DLQ (Dead Letter Queue) for asynchronous invocations.
- **On Success**: Sends the result of a successful execution to a destination.
- **On Failure**: Sends error information to a destination (similar to DLQ but more flexible).

### Event Source Mappings

Lambda can consume events from services like SQS, Kinesis, DynamoDB Streams and others without intermediaries.

| Source | Read Type | Specifics |
|--------|----------------|------------------|
| **SQS / SQS FIFO** | Polling (long polling) | Configurable batch size. For FIFO: respects order |
| **Kinesis Data Streams** | Shard polling | Reads per shard. Supports parallelization per shard |
| **DynamoDB Streams** | Shard polling | Reads table changes. Supports parallelization |
| **Amazon MQ / MSK** | Polling | Consumes messages from the broker |

### Invocation Types

| Type | Description | Retries | Example |
|------|-------------|-----------|---------|
| **Synchronous** | Waits for the response | No (the caller handles) | API Gateway, ALB, CloudFront |
| **Asynchronous** | Does not wait for the response | 2 automatic retries | S3 events, SNS, EventBridge, CloudWatch Events |
| **Event Source Mapping** | Lambda does polling | Depends on the source | SQS, Kinesis, DynamoDB Streams |

---

## ECS vs EKS vs Fargate

### Amazon ECS (Elastic Container Service)

- **AWS-native** container orchestration service.
- Runs Docker containers in a **cluster**.
- Launch types:
  - **EC2 Launch Type**: You manage the EC2 instances of the cluster.
  - **Fargate Launch Type**: AWS manages the infrastructure (serverless).
- Concepts:
  - **Task Definition**: JSON template that describes the containers (image, CPU, memory, ports, volumes).
  - **Task**: Running instance of a Task Definition.
  - **Service**: Maintains a desired number of Tasks running and registers them with a Load Balancer.
  - **Cluster**: Logical grouping of tasks or services.

### Amazon EKS (Elastic Kubernetes Service)

- Managed **Kubernetes** service on AWS.
- Compatible with the Kubernetes ecosystem (existing tools, plugins, operators).
- Node types:
  - **Managed Node Groups**: AWS manages the EC2 nodes.
  - **Self-managed nodes**: You manage the EC2 nodes.
  - **Fargate**: Serverless (no nodes to manage).
- The **control plane** (API server, etcd) is managed by AWS and distributed across multiple AZs.

### AWS Fargate

- **Serverless** compute engine for containers.
- Works with **ECS** and **EKS**.
- No need to provision or manage servers.
- You pay for the resources (vCPU + memory) your containers consume.

### Comparison Table

| Feature | ECS (EC2) | ECS (Fargate) | EKS (EC2) | EKS (Fargate) |
|---------------|-----------|---------------|-----------|---------------|
| **Orchestrator** | ECS (AWS native) | ECS (AWS native) | Kubernetes | Kubernetes |
| **Infrastructure** | You manage EC2 | Serverless | You manage EC2 | Serverless |
| **Portability** | AWS lock-in | AWS lock-in | Multi-cloud/on-prem | AWS + K8s compatible |
| **Cost** | EC2 instances | Per vCPU + task memory | EC2 + EKS fee ($0.10/h) | vCPU + memory + EKS fee |
| **Complexity** | Low | Very low | High (Kubernetes) | Medium |
| **Scaling** | Service Auto Scaling + EC2 ASG | Service Auto Scaling | HPA/VPA + Cluster Autoscaler | HPA/VPA |
| **OS access** | Yes | No | Yes | No |
| **GPUs** | Yes | No | Yes | No |
| **Persistent volumes** | EBS, EFS, FSx | EFS | EBS, EFS, FSx | EFS |
| **Ideal for** | AWS-first, simple apps | Serverless containers without K8s | Teams with K8s experience | Serverless K8s |

> **Exam tip:** If the question says "Kubernetes" or "multi-cloud portability" or "team with Kubernetes experience" -> EKS. If it says "containers without managing servers" -> Fargate. If it says "simple containers on AWS" -> ECS.

### ECS - Two-Level Scaling

ECS with EC2 Launch Type has a **two-level** scaling model similar to EKS:

```
Level 1 - TASKS (application scaling):
  "I need more copies of my container"
  -> ECS Service Auto Scaling (Target Tracking, Step, Scheduled)
  -> Metrics: Service CPU/Memory, ALBRequestCountPerTarget, SQS queue depth

Level 2 - EC2 INSTANCES (infrastructure scaling):
  "I need more servers to run the tasks on"
  -> EC2 Auto Scaling Group
  -> Metrics: ECS Cluster CapacityProviderReservation
  -> ECS Capacity Providers (recommended, manages the ASG automatically)
```

**With Fargate**: You only need Level 1 (Task scaling). AWS manages the infrastructure automatically.

**For the exam:**
```
"ECS with EC2 scaling"            -> Service Auto Scaling (tasks) + Capacity Provider (EC2s)
"ECS scaling without managing EC2" -> Fargate + Service Auto Scaling
"ECS + SQS scaling"               -> Service Auto Scaling based on ApproximateNumberOfMessages
```

### Basic Kubernetes Concepts (EKS)

```
Concept      What it is                              Analogy
-------------------------------------------------------------
Container    Packaged app (Docker image)              An executable app
Pod          Minimum K8s unit (1+ containers)         An apartment
Node         Server (EC2) where pods run              A building
Cluster      Set of nodes                             The neighborhood
```

```
EKS Cluster
  |-- Node 1 (EC2)
  |   |-- Pod (web-app)
  |   |-- Pod (api)
  |   +-- Pod (worker)
  +-- Node 2 (EC2)
      |-- Pod (web-app)     <- replica
      +-- Pod (api)         <- replica
```

### Scaling in EKS: Two Levels

```
Level 1 - PODS (application scaling):
  "I need more copies of my app"

Level 2 - NODES (infrastructure scaling):
  "I need more servers to run the pods on"
```

**Pod Scaling:**

```
Horizontal Pod Autoscaler (HPA):
  - Creates MORE pods when there is demand (more copies of the app)
  - Based on metrics (CPU, memory, custom)
  - Requires: Kubernetes Metrics Server installed
  - For: variable traffic, stateless apps
  -> Equivalent to Auto Scaling in EC2

Vertical Pod Autoscaler (VPA):
  - Makes the pod BIGGER (more CPU/RAM for the same pod)
  - Requires restarting the pod -> disruptive
  - For: apps that cannot scale horizontally
  -> Less common on the exam
```

**Node Scaling:**

```
Karpenter (recommended):
  - Designed by AWS for EKS
  - Provisions nodes in seconds (direct with EC2, without ASG)
  - Automatically chooses optimal instance type
  - Less configuration = less operational overhead
  - Preferred on the exam when it says "least operational overhead"

Cluster Autoscaler (legacy):
  - Original Kubernetes tool
  - Works via Auto Scaling Groups (ASG)
  - Slower (minutes vs seconds)
  - More manual configuration (node groups, instance types)
```

**Complete Scaling Flow:**

```
Traffic increases
  -> HPA detects high CPU -> creates more pods
  -> Pods don't fit on current nodes -> pending pods
  -> Karpenter detects pending pods -> launches new nodes (EC2)
  -> Pods are scheduled on the new nodes

Traffic decreases
  -> HPA reduces pods
  -> Karpenter detects underutilized nodes -> terminates them
```

**For the exam:**
```
"Scale pods based on demand"              -> HPA + Metrics Server
"Scale nodes automatically"               -> Karpenter (least overhead)
"EKS scaling with least overhead"         -> Karpenter + HPA
"Kubernetes autoscaling"                  -> HPA (pods) + Karpenter (nodes)
"Resize pods without adding replicas"     -> VPA (less common)
```

---

## Elastic Beanstalk

AWS Elastic Beanstalk is a **PaaS** service that facilitates the deployment and management of web applications, abstracting the underlying infrastructure.

### Concepts

| Concept | Description |
|----------|-------------|
| **Application** | Logical collection of components (environments, versions, configurations) |
| **Application Version** | Specific iteration of your app's code (stored in S3) |
| **Environment** | Collection of AWS resources that run a version of the app |
| **Environment Tier** | Web Server (HTTP requests) or Worker (processes SQS tasks) |

### Supported Platforms

- Go, Java, .NET, Node.js, PHP, Python, Ruby, Packer Builder, Docker (single/multi-container), Preconfigured Docker.

### Deployment Strategies

| Strategy | Description | Downtime | Deploy Time | Rollback | Cost |
|-----------|-------------|----------|---------------|----------|-------|
| **All at Once** | Deploys to all instances simultaneously | **Yes** | Fast | Manual re-deploy | No extra cost |
| **Rolling** | Deploys in batches. Each batch is updated and returns to service | No (but reduced capacity) | Medium | Manual re-deploy | No extra cost |
| **Rolling with Additional Batch** | Like Rolling, but launches an extra batch first to maintain full capacity | No | Medium-long | Manual re-deploy | Cost of extra batch (temporary) |
| **Immutable** | Launches new instances in a new ASG, verifies health, then moves to the original ASG | No | Long | Fast (terminate new instances) | Double cost (temporary) |
| **Traffic Splitting** | Like Immutable but sends a % of traffic to new instances (canary) | No | Long | Fast | Double cost (temporary) |
| **Blue/Green** | Creates a complete new environment and switches DNS (swap URL) | No | Long | Swap URL back | Cost of extra environment |

### Key Differences Between Strategies

```
All at Once:      [v1,v1,v1,v1] -> [v2,v2,v2,v2]   (momentary downtime)

Rolling:          [v1,v1,v1,v1] -> [v2,v1,v1,v1] -> [v2,v2,v1,v1] -> [v2,v2,v2,v2]

Rolling+Batch:    [v1,v1,v1,v1] + [v2] -> [v2,v1,v1,v1,v2] -> ... -> [v2,v2,v2,v2]

Immutable:        [v1,v1,v1,v1] + new ASG[v2,v2,v2,v2] -> merge -> [v2,v2,v2,v2]

Blue/Green:       env-blue[v1] | env-green[v2] -> swap URL -> env-green[v2] active
```

### Beanstalk with Docker

- **Single Docker**: A single instance with one Docker container. Does not need ECS.
- **Multi-Docker**: Multiple containers per instance. Uses **ECS** under the hood. Requires a `Dockerrun.aws.json` (v2).

> **Exam tip:** If they ask about "fastest deployment" -> All at Once (but has downtime). If they ask "no downtime and fast rollback" -> Immutable or Blue/Green. Rolling with Additional Batch if you want to maintain full capacity without prolonged double cost.

---

## AWS Batch

AWS Batch allows running **batch processing jobs** at any scale efficiently.

### Why AWS Batch Exists: Lambda's 15-Minute Limit

AWS Lambda has a **maximum timeout of 15 minutes**. For any processing that exceeds that limit, you need another solution. AWS Batch is the natural answer when you have **long-running, resource-intensive, batch-oriented jobs** (not HTTP requests, but background processing).

Typical examples:
- Massive ETL processing millions of records (hours).
- Video rendering or 3D animation (minutes to hours per frame).
- Scientific and financial simulations (Monte Carlo, CFD, genomics).
- ML model training that doesn't justify SageMaker.
- Large-scale image/satellite data processing.

### Concepts

| Concept | Description |
|----------|-------------|
| **Job** | Unit of work submitted to AWS Batch (shell script, Docker container) |
| **Job Definition** | Template that defines how to run a job (Docker image, vCPU, memory, environment variables, IAM role) |
| **Job Queue** | Queue where jobs are submitted. Associated with one or more Compute Environments with priorities |
| **Compute Environment** | Compute resources that execute the jobs. Managed (AWS manages EC2/Spot) or Unmanaged (you manage) |
| **Array Jobs** | A single job that splits into multiple child jobs (e.g., process 1000 files in parallel) |
| **Job Dependencies** | A job can depend on other(s) completing before executing |

### How the Flow Works

```
[Your code submits job] -> Job Queue -> Scheduler -> Compute Environment -> Container executes the job
                            ^                          ^
                     Priorities between          EC2 On-Demand/Spot
                     multiple queues               or Fargate
```

1. You define a **Job Definition** (Docker image, required resources).
2. You submit a **Job** to a **Job Queue**.
3. The AWS Batch **scheduler** evaluates queues by priority and available resources.
4. AWS Batch provisions/scales the **Compute Environment** automatically (if Managed).
5. The job runs in a container. When it finishes, resources are released.
6. If there are no more jobs, the Compute Environment can scale to **0 instances** (zero cost).

### Batch vs Lambda

| Feature | AWS Batch | AWS Lambda |
|---------------|-----------|------------|
| **Duration** | **No limit** | Maximum 15 minutes |
| **Runtime** | Any (Docker container) | Supported runtimes |
| **Storage** | Mounted EBS volumes (no practical limit) | 10 GB in /tmp |
| **Server** | EC2 (managed by Batch) or Fargate | Serverless |
| **Startup** | Slow (can take minutes to provision EC2) | Fast (cold start: ms to seconds) |
| **GPUs** | Yes (P/G instances) | No |
| **Minimum cost** | 0 (scales to 0 when no jobs) | 0 (pay per invocation) |
| **Use case** | Long, resource-intensive, batch processing | Short, event-driven, real-time processing |

> **Exam tip:** If processing lasts more than 15 minutes or needs more than 10 GB of disk or GPUs, it cannot be Lambda. Use **AWS Batch**. Batch is ideal for massive ETL, video rendering, scientific simulations.

### Batch vs Fargate (standalone): When to Use Each

This is a key distinction: **Fargate can also run long processes** (it has no 15-minute limit). So, when to use Batch and when to use Fargate directly?

| Feature | AWS Batch | ECS/EKS with Fargate (standalone) |
|---------------|-----------|----------------------------------|
| **Mental model** | "I have 10,000 jobs to process" | "I have a service or task to run" |
| **Job orchestration** | Yes: queues, priorities, dependencies between jobs, array jobs | Not native. You program the orchestration (Step Functions, EventBridge, etc.) |
| **Scale to 0** | Yes, automatic when no jobs in queue | Yes (if using one-off Fargate Tasks, not Services) |
| **Job scheduling** | Integrated (EventBridge + Job Queue) | You build it (EventBridge -> ECS RunTask) |
| **Spot Instances** | Yes (Managed CE with Spot). Batch manages interruptions and retries | Only with EC2 launch type (Fargate doesn't support Spot directly in tasks) |
| **GPUs** | Yes (with EC2 Compute Environment) | No (Fargate doesn't support GPUs) |
| **Compute** | EC2 (On-Demand/Spot) **or** Fargate | Only Fargate |
| **Inter-task dependencies** | Native (job A depends on job B) | Via Step Functions or custom code |
| **Automatic retries** | Yes (configurable in Job Definition: attempts, timeout) | Not native. You handle it |
| **Cost** | EC2/Spot: cheaper for large workloads. Fargate: same price as standalone Fargate | Fargate: pay per vCPU+memory per second |
| **Setup complexity** | More concepts (Job Def, Job Queue, CE) but more automated | Fewer concepts but more manual orchestration work |
| **Ideal for** | **Large-scale batch processing**: thousands of independent or dependent jobs | **Long-running tasks or services**: an API, a worker, a one-off cron job |

### When to Choose Each (Decision Tree)

```
Does your process last more than 15 minutes?
|-- No -> Lambda (if it fits within its limits)
+-- Yes -> Is it batch processing (many jobs)?
    |-- Yes -> Do you need GPUs or Spot Instances?
    |   |-- Yes -> AWS Batch with EC2 Compute Environment
    |   +-- No -> Do you need queues, priorities, dependencies between jobs?
    |       |-- Yes -> AWS Batch (with EC2 or Fargate CE)
    |       +-- No -> Fargate Task (simpler if it's a one-off job)
    +-- No -> Is it a long-running service (API, permanent worker)?
        +-- Yes -> ECS/EKS with Fargate (Service)
```

### Practical Example: Process 10,000 Images

**With AWS Batch:**
- You create a Job Definition with your container that processes one image.
- You submit 10,000 jobs (or an Array Job of size 10,000).
- Batch provisions Spot instances automatically, runs jobs in parallel, manages failures and retries.
- When they finish, it scales to 0. Minimum cost thanks to Spot.

**With standalone Fargate:**
- You create a Task Definition with your container.
- You need an orchestrator (Step Functions, Lambda, or your own app) to launch 10,000 ECS RunTask.
- You manage the parallelism, retries, and progress tracking.
- You can't use Spot, you pay full Fargate price.

**Conclusion:** For large batches, Batch enormously simplifies the orchestration.

### Practical Example: A Worker That Continuously Processes SQS Messages

**With Fargate (better option):**
- ECS Service with Fargate, a Task that does long-polling to SQS.
- The Service keeps the Task running 24/7.
- You scale with Application Auto Scaling based on SQS queue depth.

**With AWS Batch (not ideal):**
- Batch is designed for jobs that terminate. Not for permanent services.
- You would have to relaunch jobs periodically, which complicates the architecture.

**Conclusion:** For long-running services, Fargate with ECS/EKS is better.

### Practical Example: Web App Where the User Uploads an Excel and Simulations Are Processed (30 min)

The web server (EC2) should not run the heavy processing: it would block requests from other users. The work must be **delegated** to another service.

**General architecture (regardless of the chosen solution):**

```
User uploads Excel
  -> API (EC2/ALB) receives the file
  -> Saves the Excel in S3
  -> Triggers the processing (Fargate Task or Batch Job)
  -> Responds to the user: "Your file is being processed"
  -> [30 min later] The container finishes, writes result to S3/RDS
  -> Notifies the user (WebSocket, SNS+email, or the user polls)
```

**If there are few uploads per day -> Fargate Task (ECS RunTask):**
- Your API calls `ecs:RunTask` with the reference to the file in S3.
- Fargate launches a container, runs the calculations, dies when finished.
- Simple, direct, no permanent infrastructure. Cost only for the 30 min of vCPU+memory.

**If there are dozens/hundreds of concurrent uploads -> AWS Batch:**
- Your API submits a Job to a Job Queue with the reference to the S3 key.
- Batch queues, prioritizes (e.g., premium users first), provisions capacity, executes.
- Automatic retries if a job fails. Spot Instances to reduce cost.
- Scales to 0 when there are no pending jobs.

**If calculations are mathematical/parallelizable and you need GPU -> AWS Batch with EC2 CE (GPU):**
- Fargate **does not support GPU**. You need Batch with EC2 Compute Environment and GPU instances (g4dn, g5, p3...).
- GPU is worth it if the workload is massively parallel at the mathematical level: matrix operations, ML inference, Monte Carlo simulations. The GPU has thousands of CUDA cores that execute the **same operation on many data points** (SIMD).
- GPU is **not** worth it if the calculation is business logic (if/else, lookups, validations). Branches and conditional logic are the worst for GPU.
- GPU instances are ~3-18x more expensive per hour, but if they reduce time from 30 min to 2 min, the total cost per job is lower.
- Example: CPU c5.xlarge 30 min = ~$0.085/job vs GPU g4dn.xlarge 2 min = ~$0.018/job. But if GPU only reduces to 25 min = ~$0.22/job (more expensive).
- Using **Spot Instances with GPU** (up to ~70% discount) makes it even cheaper. Batch manages the interruptions.

**If rows are independent but calculations are NOT GPU-friendly -> Batch Array Jobs (CPU):**
- Split the file into N chunks and process each one in a separate CPU container.
- Example: 1000 rows / 10 containers = 100 rows/container. Calculation: ~3 min per container.
- **Watch out for provisioning:** each container needs startup time (EC2: ~3-5 min, Fargate: ~1-2 min). The real time is calculation + provisioning.
- The total cost is **higher** than 1 single container (you pay for each one's provisioning), but the user waits much less. It's a money vs wait time tradeoff.
- Realistic example: 1 CPU 30 min = ~$0.085. 5 Fargate Tasks ~8 min = ~$0.10. You pay a bit more to reduce waiting from 30 min to 8 min.
- Mitigation: use fewer larger containers (3 instead of 10) to reduce provisioning overhead.
- Does not require rewriting code for CUDA.

**What you would NOT use:**
- **Lambda**: 15 min limit. A 30-min process doesn't fit.
- **Dedicated EC2 for processing**: You pay 24/7 even if nobody uploads excels.
- **Fargate Service (24/7)**: A Service is always running. You want one-off Tasks that die when done.

> **Exam tip:** AWS Batch = many batch jobs, queues with priorities, dependencies, Spot. Fargate Task = one-off task without managing infrastructure. If the question mentions "batch processing", "job scheduling", "massive processing" -> **AWS Batch**. If it mentions "run a containerized task without managing servers" -> **Fargate Task (ECS RunTask)**.

---

## AWS Outposts, Wavelength and Local Zones

### AWS Outposts

- Racks of AWS hardware installed in your **on-premises data center**.
- Run the same AWS services with the same APIs, tools and the same control plane.
- **Available services**: EC2, EBS, S3 (Outposts), ECS, EKS, RDS, EMR.
- Data can reside **locally** on the Outpost.
- The **control plane** still operates from the AWS Region (requires connectivity).
- Use case: Local data residency, low latency to on-premises systems, local processing.

### AWS Wavelength

- AWS infrastructure embedded in the **5G networks of telecom operators**.
- **Wavelength Zones** are within the telecom operator's data center.
- Provides **single-digit millisecond** latency from 5G devices.
- Available services: EC2, EBS, VPC, ECS, EKS, Lambda.
- Use case: Augmented reality applications, gaming, real-time streaming, IoT from 5G devices.
- Instances in Wavelength Zones connect to the parent Region through the carrier's network.

### AWS Local Zones

- Extensions of an AWS Region placed **near large cities**.
- Provide compute, storage and other services with low latency.
- Connect to the parent Region through AWS's dedicated network.
- Available services: EC2, EBS, Amazon FSx, ELB, Amazon ECS, etc.
- Use case: Latency-sensitive applications (gaming, media/entertainment, live streaming) in cities where there is no nearby AWS Region.

### Comparison

| Feature | Outposts | Wavelength | Local Zones |
|---------------|----------|------------|-------------|
| **Location** | Your data center | 5G operator's network | Near large cities |
| **Latency** | Minimal to your on-prem infra | Ultra low from 5G | Low from the city |
| **Hardware** | AWS racks in your facilities | AWS infrastructure at the operator | AWS data centers |
| **Management** | AWS maintains the hardware | AWS maintains everything | AWS maintains everything |
| **Connectivity** | Via network to the AWS Region data center | Via carrier's network to the Region | Via AWS network to the Region |
| **Use case** | Data residency, legacy on-prem | Real-time 5G apps | Latency-sensitive apps in cities |

---

## Compute Exam Tips

### EC2

- Know the families: **C** (Compute), **R** (RAM/Memory), **I/D/H** (Storage), **P/G** (GPU/Accelerated), **M/T** (General).
- **T instances** are burstable. If they exhaust credits in `standard` mode, performance degrades. In `unlimited`, extra charges apply.
- Naming: `m5a.xlarge` -> m=family, 5=generation, a=AMD, xlarge=size.

### Purchasing

- **On-Demand**: No commitment. For unpredictable workloads.
- **Reserved**: 1-3 years. Up to 72% discount. For stable workloads.
- **Savings Plans**: More flexible than RI. Commitment in $/hour.
- **Spot**: Up to 90% discount. Can be interrupted. For fault-tolerant workloads.
- **Dedicated Hosts**: For BYOL licensing (per socket/core).
- **Capacity Reservations**: Guarantee capacity in AZ. No discount.

### Placement Groups

- **Cluster**: Same rack, low latency (HPC). Cannot span AZs.
- **Spread**: Different hardware, max 7 instances/AZ. High availability.
- **Partition**: Separate racks per partition. Distributed big data (Kafka, HDFS).

### Networking

- **ENI**: Basic network interface. Movable between instances for failover.
- **ENA**: Enhanced Networking (100 Gbps). No extra cost.
- **EFA**: For HPC and distributed ML. OS-bypass (Linux only).

### AMIs and Bootstrap

- AMIs are regional. Can be copied cross-region.
- **User Data** runs only once at first boot. Runs as root.
- **IMDSv2** is more secure (against SSRF). Accessed with token.

### Auto Scaling

- Use **Launch Templates** (not Launch Configurations).
- **Target Tracking**: The simplest ("keep CPU at 50%").
- **Predictive Scaling**: ML to anticipate patterns.
- **Cooldown**: Prevents premature scaling (default 300s).
- **Warm Pools**: Pre-initialized instances for fast startup.

### Lambda

- **15 minutes** maximum timeout. If you need more, use Batch, ECS or Step Functions.
- **10 GB** of ephemeral storage in /tmp.
- **Provisioned Concurrency** eliminates cold starts (with cost).
- In VPC: needs NAT Gateway to access the Internet, or VPC Endpoints for AWS services.
- **Destinations**: Modern replacement for DLQ for asynchronous invocations.
- Pay per number of invocations + duration in GB-s.

### Containers

- **ECS**: AWS-native orchestrator. Simple. For AWS-first teams.
- **EKS**: Managed Kubernetes. For teams with K8s experience or portability requirements.
- **Fargate**: Serverless for containers. No infrastructure management. Works with ECS and EKS.
- If the question says "without managing servers" for containers -> **Fargate**.
- If it says "Kubernetes" -> **EKS**.

### Beanstalk

- **All at Once**: Fast but with downtime.
- **Rolling**: No downtime but reduced capacity.
- **Rolling with Additional Batch**: Full capacity during deploy.
- **Immutable**: Fast rollback, new instances.
- **Blue/Green**: Separate environments, swap URL.
- Beanstalk creates and manages the resources (EC2, ALB, ASG, RDS, etc.) but you have full control over them.

### Batch vs Fargate for Long Processes

- **Lambda limit = 15 min**. If you need more -> Batch or Fargate.
- **AWS Batch**: For **massive batches** (thousands of jobs). Offers queues, priorities, dependencies, array jobs, retries and **Spot Instances**.
- **Fargate (standalone)**: For **services or one-off long-running tasks**. Simpler but without native job orchestration.
- Batch can use **Fargate as Compute Environment** (not necessarily EC2).
- Batch can use **Spot Instances** (with EC2 CE) to reduce costs by up to 90%.
- If the question says "batch processing", "job queue", "thousands of jobs" -> **AWS Batch**.
- If it says "containerized service without managing servers" -> **Fargate with ECS/EKS**.

### Edge Computing

- **Outposts** = AWS in your data center (data residency, latency to on-prem).
- **Wavelength** = AWS in 5G networks (ultra low latency from 5G devices).
- **Local Zones** = AWS near cities (low latency for applications in cities without a nearby Region).
