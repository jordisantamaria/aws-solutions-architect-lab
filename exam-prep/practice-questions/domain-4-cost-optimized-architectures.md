# Domain 4: Design Cost-Optimized Architectures

## Question 1

A company runs a cluster of EC2 instances for batch data processing that runs every night between 2:00 and 6:00 AM. The processing can be restarted without issues if interrupted. What is the most cost-effective configuration?

A) On-Demand instances running 24/7
B) 1-year Reserved Instances
C) Spot Instances with an Auto Scaling Group scheduled from 2:00 to 6:00 AM
D) On-Demand instances with an Auto Scaling Group scheduled from 2:00 to 6:00 AM

<details>
<summary>Show answer</summary>

**Answer: C**

**Spot Instances** offer up to 90% discount over On-Demand and are ideal for interrupt-tolerant workloads like batch processing. Combined with **Scheduled Scaling** that only runs instances during the needed timeframe (4 hours/night), cost is minimized to the maximum. If a Spot instance is interrupted, the batch can be restarted per the scenario. Option A pays for 24 hours when only 4 are needed. Option B pays all day for an entire year. Option D is correct in scheduling but more expensive than Spot.

**Key service/concept:** Spot Instances, Scheduled Scaling, batch processing
</details>

---

## Question 2

A company stores 50 TB of logs in S3 Standard. The logs are analyzed intensively during the first 30 days, accessed occasionally during the following 90 days, and must be retained for 7 years for compliance. What is the most cost-effective configuration?

A) Keep everything in S3 Standard for the full 7 years
B) S3 Intelligent-Tiering for the full 7 years
C) S3 Lifecycle Policy: Standard (30 days) → Standard-IA (90 days) → Glacier Deep Archive (7 years)
D) S3 Lifecycle Policy: Standard (30 days) → Glacier Flexible Retrieval (7 years)

<details>
<summary>Show answer</summary>

**Answer: C**

The **Lifecycle Policy** with three tiers optimizes cost for each usage phase: S3 Standard for the 30 days of intensive access, Standard-IA (cheaper) for the 90 days of occasional access, and Glacier Deep Archive (the cheapest of all, ~$0.00099/GB/month) for long-term 7-year retention. Option A is the most expensive. Option B charges a monitoring fee per object. Option D skips the IA tier, putting data in Glacier from day 31 when it is still accessed occasionally (hour-long retrieval).

**Key service/concept:** S3 Lifecycle Policy, tiered storage, Glacier Deep Archive
</details>

---

## Question 3

An application has an RDS MySQL db.r5.2xlarge database that operates 24/7 in production. Data shows that average CPU is 75% during business hours (8AM-8PM) and 10% outside business hours. The team wants to reduce costs without affecting performance during peak hours. What is the best solution?

A) Purchase a 1-year Reserved Instance for the current instance
B) Migrate to Aurora Serverless v2 that scales automatically based on demand
C) Downgrade to db.r5.xlarge and accept degraded peak performance
D) Stop the database outside business hours

<details>
<summary>Show answer</summary>

**Answer: B**

**Aurora Serverless v2** automatically scales compute capacity (ACUs) based on actual demand. During peak hours it uses more ACUs (equivalent to current capacity) and during off-peak hours it scales to the minimum, paying only for what is used. It is compatible with MySQL, so the migration is feasible. Option A reduces cost but still pays for idle capacity outside business hours. Option C degrades performance. Option D: you cannot stop a production database that could receive requests 24/7.

**Key service/concept:** Aurora Serverless v2, auto-scaling, pay-per-use
</details>

---

## Question 4

A company transfers 500 GB daily of data from its application in eu-west-1 to an S3 bucket in the same region. It also transfers 100 GB daily of processed data to another AWS account in the same region. The team wants to minimize data transfer costs. What is CORRECT about the costs?

A) Both transfers have data transfer costs
B) The transfer to S3 in the same region is free, and the cross-account transfer in the same region is also free
C) The transfer to S3 is free, but the cross-account transfer has a cost
D) Both transfers are free because they are in the same region

<details>
<summary>Show answer</summary>

**Answer: B**

In AWS, data transfer **within the same region** is generally free: from EC2 to S3 in the same region is free, and transfer between accounts using S3 in the same region is also free (the cost is in data transfer IN which is always free, and S3 requests). However, cross-AZ transfer has a minimal cost. Cross-account transfer within the same region via S3 bucket policies or cross-account access does not have an additional data transfer charge. The main costs are S3 API requests (PUT, GET), not the transfer.

**Key service/concept:** Data transfer pricing, same-region transfers, cross-account
</details>

---

## Question 5

A startup has highly variable web traffic: peaks of 100,000 requests/minute during product launches (a few times per month) and base traffic of 1,000 requests/minute the rest of the time. They currently use EC2 On-Demand with Auto Scaling. What is the most cost-effective configuration?

A) Reserved Instances for base traffic + Spot Instances for peaks
B) Reserved Instances for maximum capacity
C) Savings Plans for base traffic + On-Demand Auto Scaling for peaks
D) Migrate entirely to Lambda + API Gateway with DynamoDB

<details>
<summary>Show answer</summary>

**Answer: D**

For workloads with high variability (100x between base and peak), a **serverless** architecture is the most cost-effective. Lambda + API Gateway scales from 0 to millions of requests without provisioning capacity, and you pay exactly for what you use. DynamoDB On-Demand scales automatically. During base periods, cost is minimal. During peaks, it scales instantly. Option A is good but Spot is not suitable for web (can be interrupted). Option B pays for idle capacity 95% of the time. Option C is better than B but still has management overhead.

**Key service/concept:** Serverless architecture, pay-per-use, Lambda + API Gateway + DynamoDB
</details>

---

## Question 6

A company has 200 EC2 instances distributed across several accounts and regions. They suspect many instances are oversized. What AWS service helps them identify instances with idle resources and recommend the right size?

A) AWS Trusted Advisor
B) AWS Cost Explorer with Right Sizing Recommendations
C) AWS Compute Optimizer
D) Amazon CloudWatch dashboards

<details>
<summary>Show answer</summary>

**Answer: C**

**AWS Compute Optimizer** analyzes usage metrics (CPU, memory, network, disk) of EC2 instances using machine learning and recommends the optimal instance type and size. It works at the organization level, covering multiple accounts. It provides concrete savings estimates. Option A gives general recommendations but less detailed for rightsizing. Option B offers rightsizing recommendations but less sophisticated than Compute Optimizer. Option D only shows metrics without recommendations.

**Key service/concept:** AWS Compute Optimizer, rightsizing, ML-based recommendations
</details>

---

## Question 7

A development team runs development and test environments on EC2 that are only used during business hours (8AM-6PM, Monday to Friday). Currently the instances are running 24/7. What is the most efficient way to reduce costs?

A) Use Spot instances for all development environments
B) Use AWS Instance Scheduler to automatically start/stop instances according to schedule
C) Purchase Reserved Instances for the development environments
D) Migrate the development environments to Lambda

<details>
<summary>Show answer</summary>

**Answer: B**

**AWS Instance Scheduler** (an AWS solution) or scripts with EventBridge + Lambda allow automatically starting and stopping EC2 instances according to a defined schedule. Running only 10 hours per day, 5 days per week (50 hours) vs 168 weekly hours, saves ~70% of cost. Stopped instances do not charge for compute (only EBS storage). Option A can cause unwanted interruptions in development. Option C pays 24/7 for a reserved instance. Option D requires rewriting the application.

**Key service/concept:** Instance Scheduler, start/stop automation, development environments
</details>

---

## Question 8

A company pays $50,000/month in EC2 On-Demand instances. The instances include a variety of types (m5, c5, r5) across several regions. They have a stable commitment of at least $30,000/month of predictable usage. What is the most flexible savings option?

A) Purchase Reserved Instances for $30,000/month in specific types
B) Purchase a Compute Savings Plan of $30,000/month with a 1-year commitment
C) Purchase an EC2 Instance Savings Plan of $30,000/month
D) Use only Spot Instances to reduce the bill

<details>
<summary>Show answer</summary>

**Answer: B**

A **Compute Savings Plan** offers maximum flexibility: it automatically applies the discount to any EC2 usage (any family, size, OS, tenancy, region), Lambda, and Fargate. With a $30/hr commitment, the company gets discounts of up to 66% on that amount and pays On-Demand for the rest. Unlike Reserved Instances (option A) or EC2 Instance Savings Plan (option C), they do not need to choose a specific instance family or region. Option D is not applicable for all workloads.

**Key service/concept:** Compute Savings Plans, flexibility, cost commitment
</details>

---

## Question 9

An application stores millions of objects in S3 Standard. Analysis shows that 60% of objects are not accessed after the first 7 days, but they cannot predict which ones will be accessed. The team wants to reduce storage costs without affecting access performance. What is the best solution?

A) Move everything to S3 Standard-IA after 7 days with Lifecycle Policy
B) Enable S3 Intelligent-Tiering on the bucket
C) Move everything to S3 One Zone-IA after 7 days
D) Compress objects before storing them

<details>
<summary>Show answer</summary>

**Answer: B**

**S3 Intelligent-Tiering** monitors the access pattern of each object individually and moves it automatically between tiers (Frequent → Infrequent → Archive Instant → Archive → Deep Archive) without retrieval costs. Since they cannot predict which objects will be accessed, Intelligent-Tiering is ideal. Option A would move EVERYTHING to IA, including the 40% that is accessed (charging retrieval fees). Option C puts data in 1 AZ (lower durability) and also charges retrieval. Option D helps but does not optimize tiers.

**Key service/concept:** S3 Intelligent-Tiering, automatic tiering, unpredictable access patterns
</details>

---

## Question 10

A company has an architecture with ALB → EC2 → RDS. Each month they receive a $15,000 bill in data transfer. After analyzing the bill, they discover that most of the cost is data transfer OUT to the internet. What are two ways to reduce this cost? (Select TWO)

A) Use CloudFront in front of the ALB to cache content and reduce data transfer from the origin
B) Compress responses with gzip on the EC2 instances
C) Move the application to a cheaper region
D) Use VPC Peering for communication between EC2 and RDS
E) Enable S3 Transfer Acceleration

<details>
<summary>Show answer</summary>

**Answer: A and B**

**A)** CloudFront caches content at edge locations. Data served from cache does not generate data transfer OUT from the origin. Additionally, CloudFront-to-internet transfer is cheaper than from EC2 directly. **B)** Gzip compression reduces response sizes (typically 60-80% for text/JSON/HTML), which directly reduces the amount of GB of data transfer OUT. Option C does not necessarily reduce the cost of transfer OUT. Option D: EC2 and RDS in the same AZ already have economical transfer. Option E is for uploads to S3.

**Key service/concept:** Data transfer optimization, CloudFront caching, gzip compression
</details>

---

## Question 11

A company runs a 24/7 web application with the following EC2 instances: 4 m5.xlarge instances as a constant base load and up to 8 additional instances during peaks (several hours per day). What is the most cost-effective purchasing strategy?

A) 12 Reserved Instances to cover the maximum
B) 4 Reserved Instances (base) + 8 On-Demand (peaks)
C) 4 Reserved Instances (base) + Auto Scaling with a mix of On-Demand and Spot for peaks
D) 12 Spot Instances for everything

<details>
<summary>Show answer</summary>

**Answer: C**

The optimal strategy is **Reserved Instances** (or Savings Plans) for the 4-instance base load (discount up to 72%) and an **ASG with mixed instances policy** that combines On-Demand and Spot for peaks. The mixed instances policy can be configured, for example, with 20% On-Demand (guarantees minimum capacity) and 80% Spot (maximum savings). Option A pays reserved 24/7 for peak capacity. Option B is good but does not leverage Spot. Option D is risky for the entire application (Spot can be interrupted).

**Key service/concept:** Mixed instances policy, Reserved + Spot strategy, ASG
</details>

---

## Question 12

A team needs to track and distribute AWS costs among 10 departments that share the same AWS account. What is the most effective way to allocate costs per department?

A) Create separate AWS accounts for each department
B) Use Cost Allocation Tags and activate them in the Billing console, assigning a "Department" tag to each resource
C) Use AWS Budgets to set limits per department
D) Review the bill manually and divide by service

<details>
<summary>Show answer</summary>

**Answer: B**

**Cost Allocation Tags** allow tagging resources with metadata like "Department:Marketing" and then viewing costs broken down by tag in Cost Explorer and Cost & Usage Reports. They must be activated as "cost allocation tags" in the Billing console to appear in reports. **Tag Policies** from Organizations can also be used to enforce consistent tagging. Option A works but is a drastic measure. Option C sets alerts but does not allocate costs. Option D does not scale.

**Key service/concept:** Cost Allocation Tags, Cost Explorer, cost attribution
</details>

---

## Question 13

A company has an S3 bucket with 100 TB of data. Each month they add 5 TB more. They need to maintain the data indefinitely but only actively access the last month. The storage budget is limited. Currently everything is in S3 Standard ($0.023/GB/month). How much could they save approximately with an optimized Lifecycle Policy?

A) ~10% savings
B) ~30% savings
C) ~60% savings
D) ~80% savings

<details>
<summary>Show answer</summary>

**Answer: D**

Approximate calculation: With 100 TB in Standard at $0.023/GB/month = ~$2,300/month. With Lifecycle Policy: 5 TB (last month) in Standard = ~$115/month. 95 TB in Glacier Deep Archive at $0.00099/GB/month = ~$94/month. Optimized total: ~$209/month vs $2,300/month = **~91% savings**. Even with an intermediate tier (IA for the last 3 months), savings exceed 80%. The key is that Glacier Deep Archive is ~23x cheaper than Standard. For 100 TB where 95% is not accessed, the savings are massive.

**Key service/concept:** S3 Lifecycle Policy, Glacier Deep Archive pricing, storage optimization
</details>

---

## Question 14

A company has an Oracle Database license contract that requires running on specific dedicated hardware. They need the database to run on AWS with the lowest possible cost while maintaining license compliance. What is the best option?

A) RDS for Oracle with License Included
B) EC2 Dedicated Hosts with Oracle installed manually (BYOL)
C) EC2 On-Demand with Oracle installed
D) RDS for Oracle in Multi-AZ

<details>
<summary>Show answer</summary>

**Answer: B**

**EC2 Dedicated Hosts** provide dedicated physical servers where the customer has visibility into the underlying hardware (sockets, cores). This allows complying with Oracle licensing requirements that require running on specific hardware (BYOL - Bring Your Own License). Dedicated Hosts are also eligible for **Reserved Pricing**, which significantly reduces cost. Option A includes license cost (more expensive). Option C is not dedicated hardware. Option D does not meet per-hardware license requirements.

**Key service/concept:** EC2 Dedicated Hosts, BYOL, Oracle licensing compliance
</details>

---

## Question 15

A team wants to implement proactive alerts when AWS spending approaches predefined limits. They need notifications when 50%, 80%, and 100% of the $10,000 monthly budget is reached. They also want an automatic action to stop non-critical EC2 instances when 90% is reached. What is the correct solution?

A) Configure CloudWatch alarms based on billing metrics with SNS actions
B) Configure AWS Budgets with threshold alerts (50%, 80%, 100%) linked to SNS, and a Budget Action at 90% that executes a policy to stop instances
C) Use AWS Cost Explorer to review spending daily
D) Create a Lambda that checks the bill daily via the Cost Explorer API

<details>
<summary>Show answer</summary>

**Answer: B**

**AWS Budgets** allows creating budgets with multiple alert thresholds and automatic actions. Alerts are configured at 50%, 80%, and 100% to send notifications via SNS (email, SMS). At 90%, a **Budget Action** can automatically execute an IAM policy that restricts instance launches or execute a Systems Manager action to stop non-critical instances. Option A only allows simple alarms without complex automated actions. Options C and D are manual/reactive, not proactive.

**Key service/concept:** AWS Budgets, Budget Actions, cost alerts, automated cost control
</details>
