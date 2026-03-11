# Monitoring and Management in AWS

## Table of Contents

- [Amazon CloudWatch](#amazon-cloudwatch)
- [CloudWatch Logs](#cloudwatch-logs)
- [CloudWatch Agent](#cloudwatch-agent)
- [CloudWatch Container Insights](#cloudwatch-container-insights)
- [AWS CloudTrail](#aws-cloudtrail)
- [AWS Config](#aws-config)
- [AWS X-Ray](#aws-x-ray)
- [Amazon EventBridge as a Monitoring Tool](#amazon-eventbridge-as-a-monitoring-tool)
- [AWS Trusted Advisor](#aws-trusted-advisor)
- [AWS Health Dashboard](#aws-health-dashboard)
- [VPC Flow Logs](#vpc-flow-logs)
- [AWS Systems Manager](#aws-systems-manager)
- [Exam Tips](#exam-tips)

---

## Amazon CloudWatch

AWS monitoring and observability service. Collects metrics, logs, and events from resources and applications.

### Metrics

- Every AWS service sends metrics to CloudWatch automatically.
- A **metric** belongs to a **namespace** (e.g., `AWS/EC2`, `AWS/RDS`).
- Each metric has up to **30 dimensions** (attributes like InstanceId, InstanceType).
- **Resolution**:
  - Standard: data every **5 minutes** (free).
  - Detailed monitoring: data every **1 minute** (additional cost).
  - High-resolution custom metrics: up to every **1 second**.
- Data retention:
  - 1-second data → available for 3 hours.
  - 60-second data → available for 15 days.
  - 5-minute data → available for 63 days.
  - 1-hour data → available for 455 days (15 months).

### Common Metrics by Service

| Service | Key Metrics | Note |
|---|---|---|
| **EC2** | CPUUtilization, NetworkIn/Out, StatusCheckFailed | **Does NOT include RAM or disk** (requires agent) |
| **EBS** | VolumeReadOps, VolumeWriteOps, BurstBalance | BurstBalance for gp2 |
| **RDS** | DatabaseConnections, FreeableMemory, ReadIOPS | FreeableMemory IS available |
| **ALB** | RequestCount, TargetResponseTime, HTTPCode_Target_5XX | HealthyHostCount is important |
| **Lambda** | Invocations, Duration, Errors, Throttles, ConcurrentExecutions | Automatic metrics |
| **S3** | BucketSizeBytes, NumberOfObjects | Daily bucket metrics |
| **SQS** | ApproximateNumberOfMessagesVisible, ApproximateAgeOfOldestMessage | Key for auto scaling |

> **Key for the exam**: EC2 does NOT send RAM or disk usage metrics to CloudWatch by default. The CloudWatch Agent is needed for this.

### Custom Metrics

- Published with the `PutMetricData` API.
- Resolution can be defined: **Standard** (60 seconds) or **High Resolution** (1 second).
- Past data (up to 2 weeks) and future data (up to 2 hours) can be sent.
- Dimensions can be used for segmentation (e.g., `Environment=prod`, `InstanceId=i-xxx`).

### CloudWatch Alarms

Evaluate metrics and execute actions when thresholds are crossed.

**Alarm states:**
- `OK`: The metric is within the threshold.
- `ALARM`: The metric has crossed the threshold.
- `INSUFFICIENT_DATA`: Not enough data to evaluate.

**Available actions:**

| Action | Description |
|---|---|
| **EC2 Actions** | Stop, Terminate, Reboot, Recover the instance |
| **Auto Scaling** | Scale out/in |
| **SNS** | Send notification to an SNS topic |
| **Systems Manager** | Execute an OpsItem or Incident |
| **Lambda** | Invoke function (through SNS) |

**Alarm configuration:**
- **Period**: Evaluation period (e.g., 300 seconds = 5 min).
- **Evaluation Periods**: Number of consecutive periods that must be in alarm.
- **Datapoints to Alarm**: Minimum number of datapoints in alarm within the evaluation periods.

> **Example**: Period=60s, Evaluation Periods=5, Datapoints to Alarm=3 → The alarm triggers if 3 of the last 5 minutes are above the threshold.

### Composite Alarms

- Combine multiple alarms with **AND** and **OR** logical operators.
- Reduce "alarm noise" by requiring multiple conditions to be met.
- Use case: Only alert if CPU is high **AND** memory is high (not just one of the two).

### CloudWatch Dashboards

- Visualization of metrics in custom panels.
- **Global**: Can include metrics from different regions and accounts.
- Widgets: Line, Stacked area, Number, Bar, Text, Log, Alarm status.
- Can be shared externally (with Cognito).
- Free up to 3 dashboards (50 metrics each). After that, $3/dashboard/month.

---

## CloudWatch Logs

Centralized service for collecting, monitoring, and analyzing logs.

### Key Concepts

```
    ┌─────────────────────────────────────┐
    │          CloudWatch Logs            │
    │                                     │
    │  Log Group: /aws/lambda/my-function │
    │  ├── Log Stream: 2024/01/15/[$LATEST]abc123  │
    │  │   ├── Log Event (timestamp + message)     │
    │  │   ├── Log Event                           │
    │  │   └── Log Event                           │
    │  ├── Log Stream: 2024/01/15/[$LATEST]def456  │
    │  └── ...                                     │
    │                                     │
    │  Retention: 1 day → 10 years → Never│
    └─────────────────────────────────────┘
```

| Concept | Description |
|---|---|
| **Log Group** | Logical grouping of logs (e.g., by application or service). Retention and encryption configuration. |
| **Log Stream** | Sequence of events from the same source (e.g., a specific EC2 instance). |
| **Log Event** | An individual record with timestamp and message. |
| **Retention** | Configurable: from 1 day to 10 years, or no expiration. |

### Log Sources

| Source | Typical Log Group |
|---|---|
| **Lambda** | `/aws/lambda/<function-name>` (automatic) |
| **API Gateway** | `/aws/apigateway/<api-name>` |
| **ECS** | `/ecs/<service-name>` |
| **CloudTrail** | Configurable |
| **Route 53** | DNS query logs |
| **VPC Flow Logs** | Configurable |
| **EC2 / on-premises** | Requires CloudWatch Agent |
| **Elastic Beanstalk** | Automatic |

### Metric Filters

- Extract data from logs and convert them into **CloudWatch metrics**.
- Use filter patterns to search through log events.
- Alarms can be created on these metrics.

**Example use case**: Count the number of "ERROR" entries in logs and create an alarm if it exceeds a threshold.

```
    Logs ──► Metric Filter ("ERROR") ──► Custom Metric ──► Alarm ──► SNS
```

> **Note**: Metric filters are NOT retroactive. They only process events that arrive AFTER the filter is created.

### CloudWatch Logs Insights

- Interactive query engine for analyzing logs.
- Proprietary query language (similar to SQL).
- Can query multiple log groups.
- Results visualization in tables and charts.

**Example query:**

```
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 20
```

### Exporting Logs

| Destination | Method | Latency |
|---|---|---|
| **S3** | Export task (API: `CreateExportTask`) | Up to **12 hours** (not real-time) |
| **Kinesis Data Streams** | Subscription filter (real-time) | Real-time |
| **Kinesis Data Firehose** | Subscription filter (near real-time) | Near real-time (~60s) |
| **Lambda** | Subscription filter (real-time) | Real-time |
| **OpenSearch** | Subscription filter (real-time) | Real-time |

> **Key**: To export logs to S3 in real-time, do NOT use `CreateExportTask` (takes hours). Use a **Subscription Filter** → Kinesis Data Firehose → S3.

### Cross-Account Logs

- Logs from multiple accounts can be sent to a centralized account using **Subscription Filters** + Kinesis Data Streams or Firehose.

---

## CloudWatch Agent

### CloudWatch Unified Agent

Agent installed on EC2 instances or on-premises servers to send additional metrics and logs to CloudWatch.

**Metrics it collects (not available by default):**

| Metric | Description |
|---|---|
| **Memory** | RAM utilization (mem_used_percent) |
| **Disk** | Disk usage, I/O (disk_used_percent) |
| **Swap** | Swap memory usage |
| **Netstat** | TCP, UDP connections |
| **Processes** | Number of processes |
| **CPU** | Granular per-core metrics |

**Configuration:**
- Configured via a JSON file or with **SSM Parameter Store** (centralized).
- The `amazon-cloudwatch-agent-config-wizard` can be used to generate the configuration.
- Requires an **IAM Role** with permissions for CloudWatch Logs and Metrics.

**Difference between agents:**
- **CloudWatch Logs Agent** (legacy): Only sends logs. No custom metrics.
- **CloudWatch Unified Agent** (recommended): Sends logs AND custom metrics. More configurable.

> **Key**: If the question mentions "monitor EC2 RAM" or "disk usage", the answer always includes installing the **CloudWatch Unified Agent**.

---

## CloudWatch Container Insights

Monitoring solution for containers that collects, aggregates, and summarizes metrics and logs from **ECS**, **EKS**, **Kubernetes on EC2**, and **Fargate**.

### Metrics Provided

| Level | Metrics |
|---|---|
| **Cluster** | CPU/Memory utilization of the entire cluster, number of tasks/pods |
| **Service/Deployment** | CPU/Memory per ECS service or EKS deployment |
| **Task/Pod** | CPU/Memory per individual task or pod |
| **Container** | CPU/Memory per container within a task/pod |

### Configuration

- **ECS**: Enabled at the cluster level (`containerInsights` setting) or per account.
- **EKS**: Requires installing the **CloudWatch Agent** as a DaemonSet in the cluster.
- **Fargate**: Enabled at the ECS cluster level.

### Container Insights vs Basic ECS Metrics

| | Basic ECS Metrics | Container Insights |
|---|---|---|
| **Granularity** | Service and cluster level only | Cluster, service, task, container |
| **Metrics** | Service CPU/Memory | CPU, Memory, Network, Disk I/O per container |
| **Performance Logs** | No | Yes (structured performance events) |
| **Cost** | Free | Additional cost (CloudWatch custom metrics) |

> **Exam tip:** If the question says "monitor CPU/Memory at container level in ECS" or "granular pod metrics in EKS" → **CloudWatch Container Insights**. Do not confuse with basic ECS metrics that only provide service-level visibility.

---

## AWS CloudTrail

Auditing service that records all API calls made in the AWS account.

### Event Types

| Type | Description | Enabled by Default | Example |
|---|---|---|---|
| **Management Events** | Operations on AWS resources (create, configure, delete) | Yes (90 days free) | CreateBucket, TerminateInstances, AttachRolePolicy |
| **Data Events** | Operations on data within resources | No (high volume, additional cost) | GetObject on S3, Invoke on Lambda |
| **Insights Events** | Detection of unusual activity | No (must be enabled) | Abnormal spikes in API calls |

### Management Events - Detail

- **Read Events**: Read operations that do not modify resources (e.g., `DescribeInstances`, `ListBuckets`).
- **Write Events**: Operations that modify resources (e.g., `CreateBucket`, `DeleteTable`).
- Can be separated to optimize costs (only log write events).

### CloudTrail Insights

- Analyzes management events to detect **unusual activity**.
- Establishes a baseline of normal activity.
- Detects: spikes in resource creation, unusual API usage, gaps in activity.
- Insights can be sent to S3, EventBridge, or the CloudTrail console.

### Multi-Region and Organization Configuration

| Configuration | Description |
|---|---|
| **Multi-region trail** | A single trail that captures events from ALL regions. Always recommended. |
| **Organization trail** | A trail for ALL accounts in the organization. Stored in a centralized S3 bucket. |
| **Log file integrity** | Log integrity validation using SHA-256 hash. Detects if logs have been modified or deleted. |

### Storage and Analysis

- Events are stored in **S3** (compressed JSON logs).
- Retention in the CloudTrail console: **90 days** (free).
- For longer retention: create a Trail that sends to S3.
- Can be sent to **CloudWatch Logs** to create metric filters and alarms.
- Can be analyzed with **Athena** (SQL queries directly on logs in S3).

```
    API Call ──► CloudTrail ──► S3 Bucket (long-term storage)
                           ──► CloudWatch Logs (real-time alarms)
                           ──► EventBridge (react to events)
```

> **Key for the exam**: CloudTrail = "who did what and when" (API call auditing). CloudWatch = "how is the resource performing" (operational metrics and logs). They are complementary.

---

## AWS Config

Service that evaluates, audits, and records the **configuration** of AWS resources. Enables continuous compliance verification.

### Key Concepts

| Concept | Description |
|---|---|
| **Config Rules** | Rules that evaluate whether resources comply with the desired configuration |
| **Configuration Items** | Snapshot of a resource's configuration at a point in time |
| **Configuration Recorder** | Records configuration changes |
| **Compliance** | Compliance status of rules (COMPLIANT / NON_COMPLIANT) |

### Config Rules

- **AWS Managed Rules**: More than 75 predefined rules (e.g., `s3-bucket-versioning-enabled`, `ec2-instance-no-public-ip`, `rds-instance-public-access-check`).
- **Custom Rules**: Defined with Lambda or AWS CloudFormation Guard.
- Evaluated:
  - On each configuration change (change trigger).
  - Periodically (every 1, 3, 6, 12, or 24 hours).
- **Do not prevent** actions; they only evaluate and notify.

### Remediation

- Automatic actions to correct non-compliant resources.
- Uses **SSM Automation Documents** to execute the correction.
- Automatic remediation with retries can be configured.

**Example flow:**

```
    Resource changes ──► Config Rule evaluates ──► NON_COMPLIANT
                                                      │
                                                      ▼
                                              Remediation Action
                                              (SSM Automation)
                                                      │
                                                      ▼
                                              Resource corrected
```

### Conformance Packs

- Collection of Config Rules and remediation actions packaged as a single unit.
- Can be deployed to an account or across the entire organization.
- Example: Compliance pack for PCI-DSS, HIPAA, etc.

### Config Aggregator

- Centralized view of compliance status across **multiple accounts and regions**.
- Collects Config data from all accounts in the organization.
- Does not require individual permissions when using AWS Organizations.

> **Key**: Config = "how are my resources configured and do they comply with rules". CloudTrail = "who changed the configuration". They are complementary.

---

## AWS X-Ray

Distributed tracing service for analyzing and debugging applications in production, especially microservices architectures.

### Key Concepts

| Concept | Description |
|---|---|
| **Trace** | End-to-end trail of a request across multiple services |
| **Segment** | Block of work performed by an individual service |
| **Subsegment** | Granular detail within a segment (e.g., DynamoDB call from Lambda) |
| **Service Map** | Graphical visualization of architecture and latencies between services |
| **Annotations** | Indexed key-value pairs for filtering traces |
| **Metadata** | Non-indexed key-value pairs for additional information |
| **Sampling** | Controls the percentage of requests that are traced (to reduce cost) |

### X-Ray Architecture

```
    User request
         │
    ┌────▼────┐    ┌──────────┐    ┌──────────┐
    │   API   │───►│  Lambda  │───►│ DynamoDB │
    │ Gateway │    │          │    │          │
    └────┬────┘    └────┬─────┘    └────┬─────┘
         │              │               │
    Segment 1      Segment 2      Subsegment
         │              │               │
         └──────────────┴───────────────┘
                        │
                  ┌─────▼─────┐
                  │  X-Ray    │
                  │  Service  │
                  │   Map     │
                  └───────────┘
```

### Integration with AWS Services

| Service | Integration |
|---|---|
| **Lambda** | Direct enablement in the function configuration |
| **API Gateway** | Enabled at the stage level |
| **EC2** | Requires installing the X-Ray Daemon |
| **ECS/EKS** | X-Ray Daemon as sidecar container |
| **Elastic Beanstalk** | Configuration in `.ebextensions` |
| **App Runner** | Direct enablement |

### Sampling Rules

- **Default**: 1 request/second + 5% of additional requests.
- Custom rules can be defined (e.g., trace 100% of errors, 1% of successful requests).
- Reservoir rules (guaranteed minimum) + fixed rate (additional percentage).

> **Key**: X-Ray helps identify bottlenecks and errors in distributed architectures. If the question mentions "tracing", "latency between microservices", "service map", the answer is X-Ray.

---

## Amazon EventBridge as a Monitoring Tool

In addition to its use as an event bus, EventBridge is useful for monitoring:

### Monitoring Use Cases

| Event | Source | Action |
|---|---|---|
| EC2 state change (running → stopped) | EC2 | SNS → notify the team |
| Console sign-in | CloudTrail | Lambda → verify IP and alert |
| Unusual API call | CloudTrail + EventBridge | Step Functions → investigation workflow |
| CI/CD pipeline failed | CodePipeline | SNS → notify devs |
| Scheduled health check | EventBridge Scheduler | Lambda → verify endpoints |
| Config rule non-compliant | AWS Config | SNS → compliance alert |
| GuardDuty finding | GuardDuty | Lambda → automatic remediation |

### EventBridge + CloudTrail

- All management events from CloudTrail generate events on the **default event bus**.
- Rules can be created to react to specific API calls.

**Example**: Detect when someone deletes a DynamoDB table:

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

> **Key**: EventBridge is the glue between monitoring services. It enables creating reactive flows for any infrastructure change.

---

## AWS Trusted Advisor

Service that inspects the AWS environment and provides real-time recommendations based on best practices.

### Check Categories

| Category | Example Checks |
|---|---|
| **Cost Optimization** | Underutilized EC2 instances, unattached EBS volumes, unused Elastic IPs, Reserved Instance optimization |
| **Performance** | EC2 with high CPU usage, CloudFront with suboptimal distributions, insufficient provisioning |
| **Security** | Security Groups with ports open to the world, IAM without MFA, public S3 buckets, unrotated access keys |
| **Fault Tolerance** | Non-recent EBS snapshots, RDS without Multi-AZ, ASG without multi-AZ, Route 53 without health checks |
| **Service Limits** | Service quota usage percentage (80%+ generates warning) |
| **Operational Excellence** | (Advanced plans only) CloudFormation stack notifications, etc. |

### Checks by Support Plan Level

| Check | Basic / Developer | Business | Enterprise |
|---|---|---|---|
| **S3 Bucket Permissions** (public) | Available | Available | Available |
| **Security Groups - Unrestricted Ports** | Available | Available | Available |
| **IAM Use** | Available | Available | Available |
| **MFA on Root Account** | Available | Available | Available |
| **EBS Public Snapshots** | Available | Available | Available |
| **RDS Public Snapshots** | Available | Available | Available |
| **Service Limits** | Available | Available | Available |
| **All other checks (~115+)** | NOT available | Available | Available |
| **API access** (`aws support describe-trusted-advisor-checks`) | NO | Available | Available |
| **CloudWatch integration** | NO | Available | Available |

> **Key for the exam**: With the **Basic/Developer** plan you only get the 7 core checks (primarily security and service limits). For the full set you need **Business or Enterprise**.

### Trusted Advisor + EventBridge

- Trusted Advisor check state changes generate events in EventBridge.
- Alarms and automatic remediation flows can be created.

---

## AWS Health Dashboard

Provides visibility into the status of AWS services and how they affect your account.

### Service Health Dashboard vs Personal Health Dashboard

| Feature | Service Health Dashboard | AWS Health Dashboard (Personal) |
|---|---|---|
| **URL** | `health.aws.amazon.com` | Within the AWS console |
| **Scope** | Global status of all AWS services | Only events affecting YOUR account |
| **Information** | General service outages and issues | Impact on your specific resources |
| **Notifications** | RSS feed | EventBridge, proactive notifications |
| **History** | Yes (past incidents) | Yes (events from the last 90 days) |
| **API** | No | Yes (`aws health` API, requires Business/Enterprise) |

### AWS Health Dashboard (Personal) - Details

- **Scheduled events**: Planned maintenance that will affect your resources.
- **Operational events**: Current service issues affecting your resources.
- **Proactive notifications**: Alerts about changes that could affect you.
- **EventBridge integration**: Automate responses to health events.

```
    AWS Health ──► EventBridge Rule ──► Lambda ──► Migrate affected instance
                                   ──► SNS ──► Notify the team
```

> **Key**: If the question mentions "know if an AWS issue affects my specific resources", the answer is **AWS Health Dashboard** (Personal). For the general status of services, it's the **Service Health Dashboard**.

---

## VPC Flow Logs

Capture information about IP traffic entering and leaving network interfaces in the VPC.

### Capture Levels

| Level | Description |
|---|---|
| **VPC** | Captures all traffic from all ENIs in the VPC |
| **Subnet** | Captures traffic from all ENIs in the subnet |
| **ENI (Network Interface)** | Captures traffic from a specific network interface |

### Log Format

```
version account-id interface-id srcaddr dstaddr srcport dstport protocol packets bytes start end action log-status
```

**Key fields:**

| Field | Description |
|---|---|
| `srcaddr` / `dstaddr` | Source and destination IP |
| `srcport` / `dstport` | Source and destination port |
| `protocol` | Protocol (6=TCP, 17=UDP, 1=ICMP) |
| `action` | **ACCEPT** or **REJECT** |
| `log-status` | OK, NODATA, SKIPDATA |

### Storage Destinations

| Destination | Use Case |
|---|---|
| **CloudWatch Logs** | Analysis with Logs Insights, metric filters, alarms |
| **S3** | Long-term storage, analysis with Athena |
| **Kinesis Data Firehose** | Real-time analysis, delivery to OpenSearch |

### Traffic NOT Captured by Flow Logs

- DNS traffic to Amazon DNS server (captured if you use your own DNS).
- Instance metadata traffic (`169.254.169.254`).
- DHCP traffic.
- Traffic to the VPC router.
- Traffic to the VPC reserved address (Network+1 address).

### VPC Flow Logs Analysis

**With Athena (S3):**

```sql
SELECT srcaddr, dstaddr, dstport, protocol, action, COUNT(*) as count
FROM vpc_flow_logs
WHERE action = 'REJECT'
GROUP BY srcaddr, dstaddr, dstport, protocol, action
ORDER BY count DESC
LIMIT 10;
```

**With CloudWatch Logs Insights:**

```
fields @timestamp, srcAddr, dstAddr, dstPort, action
| filter action = "REJECT"
| stats count(*) as rejectCount by srcAddr
| sort rejectCount desc
| limit 10
```

> **Key**: If the question asks to "analyze rejected traffic" or "troubleshoot network connectivity", think **VPC Flow Logs**. If it needs SQL analysis, think Athena on logs in S3.

---

## AWS Systems Manager

Unified service for managing AWS and on-premises infrastructure at scale.

### Prerequisites

- EC2 instances and on-premises servers need the **SSM Agent** installed.
- The SSM Agent comes pre-installed on Amazon Linux 2, Amazon Linux 2023, and some Ubuntu AMIs.
- Instances need an **IAM Instance Profile** with SSM permissions (`AmazonSSMManagedInstanceCore`).

### Parameter Store

Centralized and secure store for configuration data and secrets.

| Feature | Standard | Advanced |
|---|---|---|
| **Number of parameters** | 10,000 | 100,000+ |
| **Maximum size** | 4 KB | 8 KB |
| **Parameter policies** | No | Yes (TTL, notifications) |
| **Cost** | Free | Paid |

**Parameter types:**
- **String**: Plain text.
- **StringList**: Comma-separated list of values.
- **SecureString**: Encrypted with KMS.

**Hierarchical organization:**

```
/my-app/
    /dev/
        /db-url         → "dev-db.example.com"
        /db-password    → (SecureString) "xxx"
    /prod/
        /db-url         → "prod-db.example.com"
        /db-password    → (SecureString) "yyy"
```

**Parameter Store vs Secrets Manager:**

| Feature | Parameter Store | Secrets Manager |
|---|---|---|
| **Automatic rotation** | Not native (can be done with Lambda) | Yes, built-in (RDS, Redshift, DocumentDB) |
| **Cost** | Free (Standard) | $0.40/secret/month |
| **Cross-account** | Not native | Yes |
| **Encryption** | Optional (SecureString with KMS) | Always encrypted |
| **Use case** | General configurations and simple secrets | Secrets with rotation, DB credentials |

> **Key**: If the question requires **automatic rotation of database credentials**, the answer is **Secrets Manager**. For general configurations, **Parameter Store**.

### Session Manager

- Secure shell access to EC2 and on-premises instances **without SSH, without bastion host, without opening port 22**.
- All traffic goes through SSM (port 443 HTTPS).
- **Complete auditing**: Entire sessions can be logged to S3 and CloudWatch Logs.
- IAM integration for access control.
- Compatible with Linux, Windows, and macOS.

```
    User ──► IAM Auth ──► SSM Session Manager ──► SSM Agent ──► Instance
                                     │
                              (Port 443, HTTPS)
                                     │
                              No need for:
                              - SSH key pairs
                              - Bastion hosts
                              - Port 22 open
                              - Public IP on the instance
```

> **Key for the exam**: If the question asks for "secure EC2 access without SSH" or "without bastion host" or "audit executed commands", the answer is **Session Manager**.

### Patch Manager

- Automates the patching process for managed instances.
- Supports OS (Linux, Windows) and applications.
- **Patch Baseline**: Defines which patches to automatically approve (by classification, severity).
  - Predefined by AWS for each OS.
  - Custom baselines can be created.
- **Patch Group**: Groups instances by tag to apply specific baselines.
- **Maintenance Window**: Time window for executing patching.
- **Compliance reporting**: Patching status of all instances.

### Run Command

- Executes commands or scripts on managed instances (EC2 and on-premises) **without SSH**.
- Uses **SSM Documents** (JSON/YAML) that define the actions to execute.
- Can be run on individual instances, by tags, or by resource groups.
- Integration with IAM, CloudTrail, and EventBridge.
- Results can be sent to S3 or CloudWatch Logs.
- Rate control (maximum concurrency and error percentage).

**Common documents:**
- `AWS-RunShellScript`: Execute shell commands on Linux.
- `AWS-RunPowerShellScript`: Execute PowerShell on Windows.
- `AWS-ConfigureAWSPackage`: Install/uninstall packages.

### Automation

- Automates common maintenance and deployment tasks.
- Uses **Automation Runbooks** (SSM Documents of Automation type).
- Can be triggered manually, by EventBridge, by Config remediation, or by scheduled maintenance.

**Example runbooks:**
- `AWS-RestartEC2Instance`: Restart an instance.
- `AWS-CreateImage`: Create an AMI from an instance.
- `AWS-StopEC2InstancesWithApproval`: Stop instances with manual approval.

**Integration with Config:**

```
    Config Rule (NON_COMPLIANT) ──► Remediation Action ──► SSM Automation Runbook
                                                              │
                                                         Corrects the resource
```

### Other Systems Manager Components

| Component | Description |
|---|---|
| **Inventory** | Collects instance metadata (installed software, network configuration, etc.) |
| **State Manager** | Maintains instances in a desired state (e.g., antivirus installed) |
| **Compliance** | Centralized view of patching and configuration status |
| **OpsCenter** | Centralizes operational items (OpsItems) for investigation |
| **Explorer** | Operational dashboard with account metrics and data |
| **Fleet Manager** | Fleet management of instances from the console |

---

## Exam Tips

### CloudWatch

1. **"Monitor EC2 CPU"** → CloudWatch (default metric).
2. **"Monitor EC2 RAM or disk"** → CloudWatch Agent (NOT available by default).
3. **"Alarm when CPU > 80% for 5 minutes"** → CloudWatch Alarm.
4. **"Alarm combining multiple conditions"** → Composite Alarm.
5. **"1-second metric resolution"** → High-Resolution Custom Metrics.
6. **"Dashboard with metrics from multiple regions"** → CloudWatch Dashboard (global).

### CloudWatch Logs

7. **"Centralize logs from multiple services"** → CloudWatch Logs.
8. **"Send logs to S3 in real-time"** → Subscription Filter → Kinesis Firehose → S3 (NOT CreateExportTask).
9. **"Create alarm based on log patterns"** → Metric Filter → CloudWatch Alarm.
10. **"Analyze logs with SQL-like queries"** → CloudWatch Logs Insights.
11. **"Send EC2 logs"** → CloudWatch Unified Agent.

### CloudTrail

12. **"Who deleted the resource"** → CloudTrail (management events).
13. **"Who accessed the S3 object"** → CloudTrail (data events, NOT enabled by default).
14. **"Audit all accounts in the organization"** → Organization Trail.
15. **"Detect unusual API activity"** → CloudTrail Insights.
16. **"Verify log integrity"** → CloudTrail Log File Integrity Validation.
17. **"Analyze CloudTrail logs with SQL"** → Athena (on logs in S3).

### Config

18. **"Verify all buckets have encryption"** → AWS Config Rule.
19. **"Automatically remediate non-compliant resources"** → Config + SSM Automation.
20. **"Centralized multi-account compliance view"** → Config Aggregator.
21. **"History of configuration changes"** → AWS Config (configuration timeline).
22. **"Config vs CloudTrail"** → Config = "WHAT configuration does the resource have". CloudTrail = "WHO changed the resource".

### X-Ray

23. **"Identify bottlenecks in microservices"** → X-Ray.
24. **"Visual map of architecture and latencies"** → X-Ray Service Map.
25. **"Distributed tracing"** → X-Ray.

### Trusted Advisor

26. **"AWS best practice recommendations"** → Trusted Advisor.
27. **"Only 7 checks available"** → Basic/Developer plan.
28. **"All checks available"** → Business or Enterprise plan.
29. **"Verify service limits/quotas"** → Trusted Advisor (available on all plans).

### Health Dashboard

30. **"An AWS service is having issues, does it affect my resources?"** → AWS Health Dashboard (Personal).
31. **"Automate response to AWS maintenance events"** → Health Dashboard + EventBridge.

### VPC Flow Logs

32. **"Analyze rejected traffic in the VPC"** → VPC Flow Logs.
33. **"Troubleshoot why an instance can't connect"** → VPC Flow Logs (verify ACCEPT/REJECT).
34. **"SQL analysis of Flow Logs"** → Athena on logs in S3.

### Systems Manager

35. **"EC2 access without SSH or bastion"** → Session Manager.
36. **"Store configurations and secrets"** → Parameter Store.
37. **"Automatic DB credential rotation"** → Secrets Manager (NOT Parameter Store).
38. **"Execute commands on multiple instances"** → Run Command.
39. **"Automate instance patching"** → Patch Manager.
40. **"Automatic Config rule remediation"** → SSM Automation.
