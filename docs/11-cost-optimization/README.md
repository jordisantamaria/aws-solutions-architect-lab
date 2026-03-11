# 11 - Cost Optimization in AWS

## Table of Contents

- [EC2 Pricing Deep Dive](#ec2-pricing-deep-dive)
- [When to Use Each Pricing Model](#when-to-use-each-pricing-model)
- [S3 Cost Optimization](#s3-cost-optimization)
- [Data Transfer Costs](#data-transfer-costs)
- [AWS Cost Explorer](#aws-cost-explorer)
- [AWS Budgets](#aws-budgets)
- [AWS Cost and Usage Report (CUR)](#aws-cost-and-usage-report-cur)
- [AWS Compute Optimizer](#aws-compute-optimizer)
- [Rightsizing](#rightsizing)
- [Savings Plans vs Reserved Instances](#savings-plans-vs-reserved-instances)
- [Spot Strategies](#spot-strategies)
- [AWS Organizations: Consolidated Billing](#aws-organizations-consolidated-billing)
- [Tagging Strategy for Cost Allocation](#tagging-strategy-for-cost-allocation)
- [Exam Tips](#exam-tips)

---

## EC2 Pricing Deep Dive

### Pricing Models

#### 1. On-Demand

- **Pay-per-use:** Charged per second (minimum 60 seconds) for Linux, per hour for Windows.
- **No commitment:** Can be started and stopped at any time.
- **Highest price** per hour, but maximum flexibility.
- **Use case:** Unpredictable workloads, development/testing, short-duration applications.

#### 2. Reserved Instances (RI)

| Feature | Standard RI | Convertible RI |
|---|---|---|
| **Discount** | Up to ~72% vs On-Demand | Up to ~66% vs On-Demand |
| **Term** | 1 or 3 years | 1 or 3 years |
| **Change instance type** | No (same family, can change size within the same family with Instance Size Flexibility) | Yes (can change family, OS, tenancy, etc.) |
| **Sell on Marketplace** | Yes | No |
| **Payment** | All Upfront / Partial Upfront / No Upfront | All Upfront / Partial Upfront / No Upfront |
| **Maximum discount** | All Upfront + 3 years | All Upfront + 3 years |

**Payment options and relative discount:**

| Payment Option | Relative Discount |
|---|---|
| **All Upfront** | Highest discount (everything paid upfront) |
| **Partial Upfront** | Intermediate discount (partial upfront + reduced monthly) |
| **No Upfront** | Lowest discount (no initial payment, fixed monthly) |

#### 3. Savings Plans

| Type | Description | Flexibility | Discount |
|---|---|---|---|
| **Compute Savings Plans** | Hourly spend commitment ($/hour) applicable to EC2, Fargate, and Lambda | Maximum: any family, region, OS, tenancy | Up to ~66% |
| **EC2 Instance Savings Plans** | Hourly spend commitment for a specific instance family in a specific region | Medium: family and region fixed, flexible on size, OS, tenancy | Up to ~72% |
| **SageMaker Savings Plans** | Hourly spend commitment for SageMaker | Specific to ML | Up to ~64% |

#### 4. Spot Instances

- **Discount:** Up to ~90% vs On-Demand.
- **Risk:** AWS can reclaim the instance with **2 minutes notice** when it needs the capacity.
- **Variable price:** Spot price fluctuates based on EC2 capacity supply/demand.
- **Use case:** Workloads tolerant to interruptions (batch processing, CI/CD, data analysis, rendering).
- **Do not use for:** Databases, critical stateful applications, workloads that cannot tolerate interruptions.

#### 5. Dedicated

| Type | Description | Use Case |
|---|---|---|
| **Dedicated Instances** | Instances on hardware dedicated to your account, but without placement control | Compliance requirements that prohibit multi-tenancy |
| **Dedicated Hosts** | Complete physical server dedicated to your account with placement control and socket/core visibility | Software licenses tied to hardware (BYOL), strict compliance |

**Key difference:** Dedicated Hosts give visibility and control of the physical server (needed for per-socket/core licenses). Dedicated Instances only guarantee dedicated hardware.

---

## When to Use Each Pricing Model

### Decision Table

| Question | Answer | Recommended Model |
|---|---|---|
| Unpredictable workload, short duration | Yes | **On-Demand** |
| Stable, known workload, 1-3 years | Yes, and I know the instance family | **EC2 Instance Savings Plan** or **Standard RI** |
| Stable workload, may change instance type | Yes | **Compute Savings Plan** or **Convertible RI** |
| Tolerant to interruptions, flexible | Yes | **Spot** |
| Need maximum discount without risk | Yes | **Standard RI 3 years All Upfront** |
| BYOL licenses per socket/core | Yes | **Dedicated Host** |
| Dedicated hardware compliance | Yes | **Dedicated Instance** or **Dedicated Host** |
| Uses EC2 + Fargate + Lambda | Yes | **Compute Savings Plan** |
| Only uses EC2 in a specific family | Yes | **EC2 Instance Savings Plan** |

### Decision Diagram

```
Is the workload predictable long-term?
  │
  ├── YES ──► Do you need instance type flexibility?
  │            ├── YES ──► Compute Savings Plan / Convertible RI
  │            └── NO ──► EC2 Instance Savings Plan / Standard RI
  │
  └── NO ──► Tolerant to interruptions?
               ├── YES ──► Spot Instances
               └── NO ──► On-Demand
```

---

## S3 Cost Optimization

### S3 Storage Classes (from highest to lowest cost per GB)

| Class | Storage Cost | Access Cost | Availability | Minimum Duration | Use Case |
|---|---|---|---|---|---|
| **S3 Standard** | High | Low | 99.99% | None | Frequently accessed data |
| **S3 Intelligent-Tiering** | Variable (auto) | Monitoring per object | 99.9% | 30 days | Unpredictable access patterns |
| **S3 Standard-IA** | Medium-low | Medium | 99.9% | 30 days | Data accessed < 1 time/month |
| **S3 One Zone-IA** | Low | Medium | 99.5% (1 AZ) | 30 days | Recreatable data, infrequent access |
| **S3 Glacier Instant Retrieval** | Very low | High | 99.9% | 90 days | Archives with immediate quarterly access |
| **S3 Glacier Flexible Retrieval** | Very low | High + retrieval cost | 99.99% | 90 days | Archives with access in minutes-hours |
| **S3 Glacier Deep Archive** | Minimum | Very high + retrieval cost | 99.99% | 180 days | Regulatory archives, access in 12-48 hours |

### Lifecycle Policies

Automatic rules to move objects between storage classes or delete them.

```
Lifecycle Policy Example:

Day 0:     S3 Standard (hot data)
     │
Day 30:    S3 Standard-IA (less frequent access)
     │
Day 90:    S3 Glacier Instant Retrieval
     │
Day 180:   S3 Glacier Flexible Retrieval
     │
Day 365:   S3 Glacier Deep Archive
     │
Day 730:   Delete object
```

**Rule types:**
- **Transition actions:** Move objects to another storage class.
- **Expiration actions:** Delete objects or old versions.

### S3 Storage Class Analysis

- Analyzes access patterns of objects in a bucket.
- Provides recommendations on when to move objects to a less costly storage class.
- Analysis data is updated daily.
- Only recommends moves from Standard to Standard-IA (does not analyze other tiers).
- Useful for defining lifecycle policies based on real data.

### S3 Intelligent-Tiering

Automatically moves objects between tiers based on access patterns. No retrieval cost.

| Tier | Access | Activation |
|---|---|---|
| **Frequent Access** | Accessed regularly | Default |
| **Infrequent Access** | Not accessed in 30 days | Automatic |
| **Archive Instant Access** | Not accessed in 90 days | Automatic |
| **Archive Access** | Not accessed in 90+ days | Optional (configure) |
| **Deep Archive Access** | Not accessed in 180+ days | Optional (configure) |

> **Key point for the exam:** If the question says "unpredictable access patterns" and wants to minimize costs, the answer is **S3 Intelligent-Tiering**.

---

## Data Transfer Costs

### Data Transfer Rules

| Transfer Type | Cost |
|---|---|
| **Inbound data (ingress) to AWS** | Free |
| **Data between services in the same AZ** | Free (using private IP) |
| **Data between AZs in the same region** | ~$0.01/GB per direction |
| **Data between regions** | ~$0.02/GB (varies by region) |
| **Data to Internet (egress)** | ~$0.09/GB (first 10 TB), decreases with volume |
| **Data through VPC Peering (same region)** | ~$0.01/GB per direction |
| **Data through VPC Peering (inter-region)** | ~$0.02/GB per direction |
| **Data through NAT Gateway** | ~$0.045/GB processed |
| **Data with CloudFront** | Less than direct egress from EC2/S3 |

### Strategies to Reduce Transfer Costs

```
Strategy 1: VPC Endpoints (eliminate Internet traffic)
  EC2 ──► VPC Gateway Endpoint ──► S3        (free, no NAT cost)
  EC2 ──► VPC Interface Endpoint ──► DynamoDB (endpoint cost < NAT cost)

Strategy 2: Same AZ
  EC2 (AZ-a) ──► RDS (AZ-a)  = free (private IP)
  EC2 (AZ-a) ──► RDS (AZ-b)  = ~$0.01/GB (cross-AZ)

Strategy 3: CloudFront
  Users ──► CloudFront ──► S3/EC2  (CloudFront egress is cheaper than directly from S3/EC2)

Strategy 4: Compression
  Compress data before transferring reduces the billed volume
```

### VPC Endpoints for Savings

| Endpoint Type | Services | Cost |
|---|---|---|
| **Gateway Endpoint** | S3, DynamoDB | Free (no cost for the endpoint or data) |
| **Interface Endpoint** | All other AWS services | ~$0.01/hour per AZ + ~$0.01/GB processed |

> **Key point for the exam:** **Gateway Endpoints for S3 and DynamoDB are free** and eliminate NAT Gateway costs. Always consider as a cost optimization.

---

## AWS Cost Explorer

Visual tool for analyzing and managing AWS costs and usage over time.

### Main Features

| Feature | Description |
|---|---|
| **Visualization** | Cost charts by service, account, region, tag, etc. |
| **Filters** | Filter by service, instance type, region, tag, cost type, etc. |
| **Grouping** | Group costs by multiple dimensions simultaneously |
| **Forecasting** | Future cost prediction (up to 12 months) based on historical trends |
| **Granularity** | Monthly, daily, or hourly data |
| **Historical data** | Up to 12 months of historical data |

### Rightsizing Recommendations

Cost Explorer includes rightsizing recommendations for EC2:

- Identifies **underutilized** instances (CPU < 40% average over 14 days).
- Suggests changing to a smaller instance type or Graviton.
- Shows the **estimated savings** if the recommendation is implemented.
- Based on CloudWatch data (CPU, network).
- Works better with the CloudWatch agent installed (for memory data).

> **Key point for the exam:** Cost Explorer is for **visualizing and analyzing** costs. AWS Budgets is for **alerting** when budgets are approaching or exceeded.

---

## AWS Budgets

Service for setting custom budgets and receiving alerts when costs or usage approach or exceed established limits.

### Budget Types

| Type | What It Monitors | Example |
|---|---|---|
| **Cost Budget** | Total monetary cost | Alert if monthly spend exceeds $10,000 |
| **Usage Budget** | Usage of a specific service | Alert if EC2 hours exceed 1,000 hours |
| **Reservation Budget** | Utilization of RIs or Savings Plans | Alert if RI utilization drops below 80% |
| **Savings Plans Budget** | Utilization and coverage of Savings Plans | Alert if coverage drops below 70% |

### Alerts

- Up to **5 alerts** can be configured per budget.
- Configurable thresholds: percentage of budget or absolute amount.
- Alert on **actual** (real cost) or **forecasted** (projected cost).
- Notifications via **email** and/or **SNS topic**.

### Automatic Actions (Budget Actions)

When a threshold is exceeded, the following can be automatically executed:

| Action | Description |
|---|---|
| **IAM Policy** | Apply an IAM policy that restricts launching new resources |
| **SCP** | Apply a Service Control Policy in AWS Organizations |
| **Target EC2/RDS** | Stop specific EC2 or RDS instances |

```
Budget with actions example:

Budget: $5,000/month
  │
  ├── Alert 1: At 80% ($4,000) → Email to the team
  │
  ├── Alert 2: At 100% ($5,000) → SNS + Email
  │
  └── Alert 3: At 110% ($5,500) → Apply IAM Policy
                                    that denies ec2:RunInstances
```

---

## AWS Cost and Usage Report (CUR)

The **most detailed and comprehensive report** of AWS costs and usage.

### Features

| Feature | Detail |
|---|---|
| **Granularity** | Hourly, daily, or monthly |
| **Detail** | Line by line of each billed resource and operation |
| **Format** | CSV/Parquet stored in an S3 bucket |
| **Integration** | Athena (SQL queries), QuickSight (dashboards), Redshift (analysis) |
| **Size** | Can be very large (GBs for complex accounts) |
| **Columns** | Includes resource IDs, tags, prices, discounts, RI amortization, etc. |

### Typical Workflow

```
CUR (generated automatically)
     │
     ▼
S3 Bucket (stores CSVs/Parquet)
     │
     ├──► Athena (ad-hoc SQL queries)
     │
     ├──► QuickSight (visual dashboards)
     │
     └──► Redshift (complex analysis, joins with business data)
```

> **Key point for the exam:** CUR is the answer when you need **maximum billing detail**, custom SQL analysis, or integration with BI tools.

---

## AWS Compute Optimizer

ML service that analyzes usage metrics and recommends the optimal resource type.

### Resources Analyzed

| Resource | What It Recommends | Data Used |
|---|---|---|
| **EC2** | Optimal instance type, over/under-provisioned | CloudWatch: CPU, memory (with agent), network, disk |
| **ASG** | Optimal group configuration | Instance utilization metrics |
| **EBS** | Optimal volume type and size | IOPS, throughput, latency |
| **Lambda** | Optimal memory size | Invocation duration, memory used |
| **ECS on Fargate** | Optimal CPU and memory for tasks | Container utilization metrics |
| **Licenses** | Software license optimization | vCPU usage for linked licenses |

### How It Works

- Analyzes at least **14 days** of CloudWatch metrics (ideally 30+ days).
- Uses ML models to predict performance with different configurations.
- Classifies each resource as: **Over-provisioned**, **Under-provisioned**, or **Optimized**.
- Provides up to 3 alternative recommendations with estimated savings.

### Compute Optimizer vs Cost Explorer Rightsizing

| Feature | Compute Optimizer | Cost Explorer Rightsizing |
|---|---|---|
| **Scope** | EC2, ASG, EBS, Lambda, ECS Fargate | EC2 only |
| **Analysis** | Advanced ML with multiple metrics | Based on CPU utilization |
| **Recommendations** | Up to 3 alternatives with performance prediction | 1 instance type recommendation |
| **Cost** | Free (Enhanced with cost for 3-month data) | Included in Cost Explorer |

---

## Rightsizing

Process of adjusting the size and type of instances to match the actual workload, eliminating waste.

### How to Identify Over-Provisioned Instances

| Signal | Metric | Typical Threshold |
|---|---|---|
| Underutilized CPU | CloudWatch CPUUtilization | < 40% average over 14 days |
| Underutilized memory | CloudWatch (agent) Memory% | < 40% average |
| Underutilized network | CloudWatch NetworkIn/Out | Well below the instance type limit |
| Underutilized disk | CloudWatch EBSReadOps/WriteOps | IOPS/throughput much lower than provisioned |

### Rightsizing Process

```
1. Collect metrics (CloudWatch, CloudWatch agent for memory)
         │
2. Analyze with Compute Optimizer or Cost Explorer
         │
3. Identify over-provisioned instances
         │
4. Evaluate recommendations (smaller instance type or Graviton)
         │
5. Test in staging/development environment
         │
6. Implement the change (resize the instance)
         │
7. Monitor post-change to ensure adequate performance
```

### Common Change Types

| Change | Example | Typical Savings |
|---|---|---|
| **Reduce size** | m5.xlarge → m5.large | ~50% |
| **Switch to Graviton** | m5.xlarge → m6g.xlarge | ~20% (better price/performance) |
| **Change family** | c5.xlarge → t3.xlarge (if constant compute not needed) | Variable |
| **Eliminate idle instances** | Instance with CPU < 5% permanently | 100% |

> **Key point for the exam:** The first step to optimize EC2 costs is always **rightsizing**. Before buying RIs or Savings Plans, make sure instances are the right size.

---

## Savings Plans vs Reserved Instances

### Complete Comparison Table

| Feature | Standard RI | Convertible RI | EC2 Instance SP | Compute SP |
|---|---|---|---|---|
| **Maximum discount** | ~72% | ~66% | ~72% | ~66% |
| **Commitment** | Instance type + region + OS | Instance type (flexible) | Family + region ($/hour) | Any compute ($/hour) |
| **Term** | 1 or 3 years | 1 or 3 years | 1 or 3 years | 1 or 3 years |
| **Change instance family** | No | Yes | No | Yes |
| **Change region** | No | No | No | Yes |
| **Change OS** | No | Yes | Yes | Yes |
| **Change tenancy** | No | Yes | Yes | Yes |
| **Applies to Fargate/Lambda** | No | No | No | Yes |
| **Sell on Marketplace** | Yes | No | No | No |
| **Instance Size Flexibility** | Yes (Linux, same family) | Yes | Yes | Yes |

### General Recommendation

```
Only use EC2 in a specific family?
  └── EC2 Instance Savings Plan (replaces Standard RI)

Use EC2 + Fargate + Lambda or multiple families/regions?
  └── Compute Savings Plan (replaces Convertible RI)

Need to sell unused capacity?
  └── Standard RI (only one that sells on Marketplace)
```

> **Key point for the exam:** AWS recommends **Savings Plans over Reserved Instances** for most cases. Savings Plans offer the same or greater flexibility with equivalent discounts. The exception is if you need to sell on the Marketplace (Standard RI only).

---

## Spot Strategies

### Spot Fleet

A **Spot Fleet** is a collection of Spot Instances (and optionally On-Demand) that attempts to meet the target capacity at the lowest cost.

#### Spot Fleet Allocation Strategies

| Strategy | Description | Use Case |
|---|---|---|
| **lowestPrice** | Selects instances from the pool with the lowest price | Maximum savings, tolerant workloads |
| **diversified** | Distributes instances across multiple pools | Better availability (reduces risk of mass interruption) |
| **capacityOptimized** | Selects pools with highest available capacity | Lowest probability of interruption |
| **priceCapacityOptimized** | Combines price and available capacity (recommended) | Optimal balance between cost and availability |

### Handling Spot Interruptions

When AWS needs to reclaim a Spot instance, it sends a **2-minute notice**:

```
Interruption behavior options:
  │
  ├── Terminate (default): the instance is terminated
  │
  ├── Stop: the instance is stopped (can be restarted later)
  │
  └── Hibernate: the instance hibernates (RAM state is saved)

Notice detection:
  ├── EC2 Metadata Service: http://169.254.169.254/latest/meta-data/spot/instance-action
  ├── CloudWatch Events / EventBridge
  └── Rebalance Recommendation (prior notice before the 2-minute one, not guaranteed)
```

### ASG with Mixed Instances (Mixed Instances Policy)

```
Auto Scaling Group:
  ├── Base capacity: 2 On-Demand instances (always available)
  │
  └── Additional capacity: Spot Instances
       ├── On-Demand percentage above base: 20%
       ├── Spot percentage above base: 80%
       │
       └── Instance types (diversified):
            ├── m5.large
            ├── m5a.large
            ├── m4.large
            └── c5.large

Result: Stable On-Demand base + cheap scaling with Spot
```

### Best Practices for Spot

1. **Diversify instance types and AZs:** Reduces the probability of simultaneous interruption.
2. **Use capacity-optimized allocation:** AWS selects pools with the most capacity.
3. **Implement checkpointing:** Save progress regularly to resume work.
4. **Use Spot Fleet instead of individual Spot:** Greater resilience and flexibility.
5. **Combine with On-Demand:** Stable On-Demand base + Spot for scaling.

---

## AWS Organizations: Consolidated Billing

### Benefits of Consolidated Billing

| Benefit | Description |
|---|---|
| **Single invoice** | One invoice for all accounts in the organization |
| **Volume discounts** | Usage from all accounts is aggregated to obtain volume discounts (S3, EC2, etc.) |
| **Share RIs/Savings Plans** | RIs and Savings Plans from one account are automatically applied to eligible instances in other accounts |
| **Shared credits** | AWS credits from any account benefit the entire organization |
| **Aggregated S3 pricing** | S3 storage from all accounts is summed to reach lower pricing tiers |

### Volume Discounts - Example

```
Without Organizations:
  Account A: 100 TB S3 → 100 TB tier price
  Account B: 100 TB S3 → 100 TB tier price

With Organizations (consolidated):
  Total: 200 TB S3 → 200 TB tier price (cheaper per GB)
  Both accounts benefit from the better price
```

### Sharing Reserved Instances

```
Account A (Management): Purchases 10 RIs m5.large
Account B (Development): Launches 3 m5.large instances

Result: Account B's 3 instances automatically use Account A's RI discount.

To disable: In the management account, disable "RI sharing" for specific accounts.
```

> **Key point for the exam:** Consolidated billing in Organizations enables **aggregated volume discounts** and **reservation sharing**. It's a way to optimize costs without technical changes.

---

## Tagging Strategy for Cost Allocation

### Cost Allocation Tags

Tags allow categorizing and tracking AWS costs by project, team, environment, etc.

#### Cost Allocation Tag Types

| Type | Description | Example |
|---|---|---|
| **AWS-generated** | Tags automatically created by AWS | `aws:createdBy` (who created the resource) |
| **User-defined** | Tags created by the user | `Project`, `Environment`, `Team`, `CostCenter` |

### Activation

Tags **must be activated** in the Billing console for them to appear in cost reports:

```
1. Create tags on resources (Billing → Cost Allocation Tags)
2. Activate tags as "Cost Allocation Tags" in the Billing console
3. Wait ~24 hours for them to appear in reports
4. Use in Cost Explorer and CUR to filter/group costs
```

### Recommended Tagging Strategy

| Tag | Purpose | Example Values |
|---|---|---|
| `Environment` | Separate costs by environment | production, staging, development |
| `Project` | Assign costs to specific projects | project-alpha, project-beta |
| `Team` | Assign costs by team | backend, frontend, data, devops |
| `CostCenter` | Link with accounting cost centers | CC-001, CC-002 |
| `Owner` | Identify the responsible person | owner's email |
| `Application` | Group by application | web-app, api, batch-processor |
| `ManagedBy` | Tool managing the resource | terraform, cloudformation, manual |

### Tag Enforcement

| Method | Description |
|---|---|
| **AWS Config Rules** | `required-tags` rule that marks resources without mandatory tags as non-compliant |
| **SCP (Organizations)** | Deny resource creation without specific tags using `aws:RequestTag` conditions |
| **Tag Policies** | Policies in Organizations that standardize allowed values for each tag |
| **AWS Service Catalog** | Pre-configured products with mandatory tags |

SCP example to enforce tags:
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "RequireProjectTag",
    "Effect": "Deny",
    "Action": "ec2:RunInstances",
    "Resource": "arn:aws:ec2:*:*:instance/*",
    "Condition": {
      "Null": {
        "aws:RequestTag/Project": "true"
      }
    }
  }]
}
```

---

## Exam Tips

### Frequently Asked Questions and Quick Answers

| Exam Scenario | Answer |
|---|---|
| Stable 24/7 workload for 3 years | **Standard RI All Upfront 3 years** or **EC2 Instance Savings Plan** |
| Batch workload tolerant to interruptions | **Spot Instances** |
| Unpredictable S3 access patterns | **S3 Intelligent-Tiering** |
| Access S3 from VPC without NAT cost | **VPC Gateway Endpoint for S3** (free) |
| Detailed billing analysis with SQL | **Cost and Usage Report (CUR) + Athena** |
| Alert when spend exceeds a threshold | **AWS Budgets** |
| Recommend optimal EC2 instance type | **AWS Compute Optimizer** |
| Visualize costs by service/month | **AWS Cost Explorer** |
| Reduce cost of EC2 + Fargate + Lambda | **Compute Savings Plan** |
| BYOL licenses per socket | **Dedicated Host** |
| Maximize EC2 discount without risk | **Standard RI 3y All Upfront** (~72%) |
| S3 volume discount across accounts | **AWS Organizations consolidated billing** |
| Assign costs by project | **Cost Allocation Tags** (activated in Billing) |
| Automatically stop spending if budget exceeded | **AWS Budgets Actions** (apply IAM policy) |
| Automatically move S3 data to cheaper classes | **S3 Lifecycle Policies** |
| Reduce internet transfer costs | **CloudFront** (cheaper egress) |
| First step to optimize EC2 costs | **Rightsizing** (before buying RIs) |

### Priority Order for EC2 Cost Optimization

```
1. Rightsizing  → Ensure the size is correct
2. Savings Plans / RIs  → Commitment for stable workloads
3. Spot  → For workloads tolerant to interruptions
4. Graviton  → Better price/performance (~20% cheaper)
5. Auto Scaling  → Scale down when there's no demand
6. Scheduled scaling  → Turn off during unused hours
```

### Common Mistakes to Avoid

1. **Buying RIs before rightsizing:** First optimize the size, then buy reservations.
2. **Using Gateway Endpoint for services that don't support it:** Only S3 and DynamoDB have Gateway Endpoints. The rest uses Interface Endpoints (with cost).
3. **Forgetting to activate Cost Allocation Tags:** Creating tags is not enough; they must be activated in Billing to appear in reports.
4. **Confusing Cost Explorer with Budgets:** Explorer is for analyzing, Budgets is for alerting and acting.
5. **Not diversifying Spot instance types:** Using only one Spot instance type increases interruption risk.
6. **Ignoring data transfer costs between AZs:** Although small (~$0.01/GB), they can accumulate with high volume. Consider data locality.
7. **Assuming Savings Plans apply to all services:** Compute Savings Plans apply to EC2, Fargate, and Lambda. They do not apply to RDS or other managed services.
8. **Not considering Convertible RI or Compute SP when technology changes fast:** If in 3 years you might change instance type, the flexibility of Convertible RI or Compute SP is worth it.
