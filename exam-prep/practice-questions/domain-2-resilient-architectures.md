# Domain 2: Design Resilient Architectures

## Question 1

A company has a web application with an ALB, EC2 instances in an Auto Scaling Group, and an RDS MySQL database. The application experiences outages when AZ eu-west-1a has issues. What is the correct configuration for high availability?

A) Deploy EC2 instances in multiple AZs with the ASG, and enable Multi-AZ on RDS
B) Deploy larger EC2 instances in a single AZ and create RDS read replicas
C) Use Route 53 failover routing to a static site on S3
D) Deploy the application in a second region as standby

<details>
<summary>Show answer</summary>

**Answer: A**

For high availability within a region, the standard pattern is to distribute EC2 instances across multiple AZs via the Auto Scaling Group (which the ALB already balances) and enable Multi-AZ on RDS for automatic database failover. This ensures that if one AZ fails, instances in other AZs continue serving traffic and RDS fails over to the standby in another AZ. Option B does not solve the single-AZ problem. Option C is for DR, not HA. Option D is excessive for a single-AZ problem.

**Key service/concept:** Multi-AZ deployment, Auto Scaling Group, RDS Multi-AZ
</details>

---

## Question 2

An e-commerce application processes orders by sending messages to an SQS queue. During high-traffic events (Black Friday), some orders are processed more than once, causing duplicate charges. What is the best solution?

A) Increase the visibility timeout of the SQS Standard queue
B) Replace the SQS Standard queue with an SQS FIFO queue with deduplication enabled
C) Add more processing instances to reduce time in queue
D) Use Amazon MQ instead of SQS to guarantee exact delivery

<details>
<summary>Show answer</summary>

**Answer: B**

SQS FIFO offers **exactly-once** processing with automatic deduplication (based on deduplication ID or content-based deduplication). This prevents the same message from being processed more than once. SQS Standard offers **at-least-once delivery**, which can result in duplicates. Option A reduces duplicates but does not eliminate them. Option C does not address the root cause. Option D is for legacy protocols, not for deduplication.

**Key service/concept:** SQS FIFO, exactly-once processing, deduplication
</details>

---

## Question 3

A company needs a disaster recovery strategy with an RTO of 1 hour and RPO of 15 minutes for their critical application that uses Aurora MySQL. The solution must be as cost-effective as possible within these requirements. What strategy should they use?

A) Backup and Restore — restore from Aurora snapshots
B) Pilot Light — Aurora Global Database with a minimal instance in the DR region
C) Warm Standby — Aurora Global Database with reduced Auto Scaling in the DR region
D) Multi-Site Active/Active — Aurora Global Database with full capacity in both regions

<details>
<summary>Show answer</summary>

**Answer: B**

With an RTO of 1 hour and RPO of 15 minutes, the **Pilot Light** strategy is sufficient and the most cost-effective that meets the requirements. Aurora Global Database replicates data to the DR region with a typical RPO of ~1 second. Pilot Light maintains a minimal instance in DR that can be scaled when needed (within the 1-hour RTO). Option A has RTO/RPO that are too long. Option C meets requirements but is more expensive. Option D is the most expensive and exceeds the requirements.

**Key service/concept:** DR strategies, Pilot Light, Aurora Global Database, RTO/RPO
</details>

---

## Question 4

An architect must design an image processing system where users upload photos to S3 and a thumbnail is generated. The system must tolerate failures without losing any image and process them eventually even during load spikes. What is the most resilient architecture?

A) S3 Event Notification → Lambda directly
B) S3 Event Notification → SQS Queue → Lambda (processing from SQS)
C) S3 Event Notification → SNS → Email to team for manual processing
D) CloudWatch Events → EC2 that monitors S3 periodically

<details>
<summary>Show answer</summary>

**Answer: B**

The S3 → SQS → Lambda combination provides maximum resilience. SQS acts as a buffer: if Lambda fails or reaches the concurrency limit, messages remain in the queue (up to 14 days) and are automatically retried. With a Dead Letter Queue, messages that fail repeatedly are preserved for analysis. Option A (direct Lambda) can lose events if Lambda fails or hits throttling. Option C is manual. Option D has high latency and is fragile.

**Key service/concept:** SQS as buffer, decoupling, Dead Letter Queue, resilience
</details>

---

## Question 5

A company has an application with an Auto Scaling Group configured with a Target Tracking scaling policy at 60% CPU. The ASG has min=2, max=10, desired=4. During a deployment, new instances cause CloudWatch to detect briefly high CPU, triggering the ASG to launch unnecessary instances. How to resolve this?

A) Switch to Simple Scaling policy
B) Configure a warmup period for new instances in the scaling policy
C) Increase the target CPU to 90%
D) Disable Auto Scaling during deployments

<details>
<summary>Show answer</summary>

**Answer: B**

The **warmup period** (instance warmup) tells the Auto Scaling Group not to include metrics from new instances in scaling calculations until they have finished initializing. This prevents transient CPU spikes during startup from triggering unnecessary scaling. Option A would worsen the problem. Option C would mask real capacity issues. Option D is operationally risky and not scalable.

**Key service/concept:** Auto Scaling warmup period, Target Tracking scaling
</details>

---

## Question 6

An application uses Aurora PostgreSQL as its primary database. The analytics team needs to run heavy reporting queries that should not affect production application performance. What is the best solution?

A) Create an Aurora snapshot every night and restore it as a separate instance for analytics
B) Create Aurora Read Replicas with a dedicated Custom Endpoint for analytics queries
C) Migrate data to Redshift every night for analytics
D) Vertically scale the primary Aurora instance

<details>
<summary>Show answer</summary>

**Answer: B**

Aurora allows creating up to 15 Read Replicas and configuring **Custom Endpoints** that direct traffic to specific replicas. You can designate replicas with larger instances for analytics and create a custom endpoint that only points to those replicas. This way, analytics traffic does not affect the writer or the replicas used by production. Option A has stale data and is costly. Option C adds unnecessary complexity if only SQL queries are needed. Option D does not isolate the workload.

**Key service/concept:** Aurora Read Replicas, Custom Endpoints
</details>

---

## Question 7

A company has an architecture with an ALB in front of EC2 instances that process requests and store them in RDS. After an application update, 5% of requests fail. They need the ability to quickly roll back to the previous version with minimal impact. What deployment strategy should they have used?

A) All at once deployment
B) Rolling deployment
C) Blue/Green deployment
D) In-place deployment with manual rollback

<details>
<summary>Show answer</summary>

**Answer: C**

**Blue/Green** deployment keeps the previous environment (Blue) fully functional while the new environment (Green) receives traffic. If problems are detected, rollback is instantaneous: simply redirect traffic back to the Blue environment (DNS swap or ALB target group swap). There is no downtime and rollback takes seconds. Options A, B, and D require re-deploying the previous version, which is slower and riskier.

**Key service/concept:** Blue/Green deployment, instant rollback, ALB target groups
</details>

---

## Question 8

An application processes financial transactions and uses a microservices architecture with multiple Lambda functions. If any step fails, all previous steps must be reversed (compensating transactions). The total process can take up to 30 minutes. What is the most appropriate service to orchestrate this flow?

A) SQS with Dead Letter Queue for retries
B) AWS Step Functions with error handling and compensation states
C) SNS with multiple Lambda subscribers
D) EventBridge with rules for each step

<details>
<summary>Show answer</summary>

**Answer: B**

AWS Step Functions is the service specifically designed to orchestrate workflows with multiple steps, including error handling, retries, and compensation states (saga pattern). It allows defining catch blocks that execute reversal steps when something fails. Standard Workflows support up to 1 year in duration. Option A decouples but does not orchestrate compensations. Options C and D are for event routing, not for complex transactional workflows.

**Key service/concept:** AWS Step Functions, saga pattern, compensating transactions
</details>

---

## Question 9

A company has a static website hosted on S3 with CloudFront. They need to configure a custom error page that is displayed when the main site is unavailable, and the failover must be automatic. What is the best solution?

A) Configure S3 website hosting error document
B) Configure CloudFront with an Origin Group that has a primary origin and a failover origin (another S3 bucket in another region)
C) Configure Route 53 failover routing to two CloudFront distributions
D) Use Lambda@Edge to detect errors and serve alternative content

<details>
<summary>Show answer</summary>

**Answer: B**

CloudFront Origin Groups allow configuring automatic failover at the CDN level. If the primary origin returns errors (4xx, 5xx), CloudFront automatically redirects the request to the secondary origin. Configuring a second S3 bucket in another region as the failover origin provides automatic resilience. Option A only displays a static error page, not an alternative site. Option C requires additional health checks and is more complex. Option D adds unnecessary complexity.

**Key service/concept:** CloudFront Origin Groups, origin failover
</details>

---

## Question 10

A mobile application uses API Gateway + Lambda + DynamoDB. During usage spikes, the application experiences DynamoDB throttling. Most operations are reads of the same popular data. What is the most effective way to reduce load on DynamoDB and improve resilience?

A) Switch DynamoDB to On-Demand mode
B) Add DynamoDB Accelerator (DAX) as a cache layer
C) Create a DynamoDB read replica
D) Significantly increase provisioned RCUs

<details>
<summary>Show answer</summary>

**Answer: B**

DynamoDB Accelerator (DAX) is a fully managed in-memory cache for DynamoDB that reduces latency from milliseconds to microseconds. For read-intensive patterns with repeated data (hot keys), DAX absorbs the read load and dramatically reduces requests to DynamoDB. Option A helps with scaling but is more expensive for repetitive reads. Option C does not exist in DynamoDB (it does not have read replicas like RDS). Option D only adds raw capacity without solving the hot keys problem.

**Key service/concept:** DynamoDB Accelerator (DAX), caching, hot partition mitigation
</details>

---

## Question 11

An architect needs to design an architecture for an application that must be available even if an entire AWS region fails. The application uses Aurora MySQL. What is the correct architecture?

A) Aurora Multi-AZ within a region with automatic backups
B) Aurora Global Database with a primary region and a secondary region, plus Route 53 failover routing
C) RDS MySQL with cross-region read replica
D) DynamoDB Global Tables as a replacement for Aurora

<details>
<summary>Show answer</summary>

**Answer: B**

Aurora Global Database replicates data to secondary regions with a typical RPO of ~1 second. Combined with Route 53 failover routing (with health checks), if the primary region fails, Route 53 redirects traffic to the secondary region where the secondary Aurora cluster can be promoted to primary. Option A only protects against AZ failures, not region failures. Option C works but with worse RPO and manual failover. Option D completely changes the database type.

**Key service/concept:** Aurora Global Database, Route 53 failover, multi-region DR
</details>

---

## Question 12

A company has an application that processes messages from an SQS queue. Occasionally, a malformed message causes the consumer to fail repeatedly, blocking the processing of other messages. How to solve this problem?

A) Increase the visibility timeout to 24 hours
B) Configure a Dead Letter Queue (DLQ) with a low maxReceiveCount (e.g., 3) to move problematic messages out of the main queue
C) Configure the queue to delete messages after the first failed attempt
D) Use multiple consumers to process faster

<details>
<summary>Show answer</summary>

**Answer: B**

A **Dead Letter Queue (DLQ)** captures messages that cannot be processed after a maximum number of attempts (maxReceiveCount). Setting maxReceiveCount to 3, after 3 failed attempts the message is moved to the DLQ, allowing other messages to be processed normally. The DLQ allows analyzing problematic messages separately. Option A only delays the problem. Option C loses data. Option D does not solve the blocking message issue.

**Key service/concept:** SQS Dead Letter Queue (DLQ), maxReceiveCount, poison messages
</details>

---

## Question 13

An application needs to store user sessions that must be available to all EC2 instances behind an ALB. Sessions must survive instance recycling and be accessible with sub-millisecond latency. What is the best solution?

A) Use ALB sticky sessions (session affinity)
B) Store sessions in Amazon ElastiCache for Redis
C) Store sessions on shared EBS volumes
D) Store sessions on each instance's local file system

<details>
<summary>Show answer</summary>

**Answer: B**

ElastiCache for Redis is the standard solution for distributed session storage. It is accessible from all instances, has sub-millisecond latency, supports Multi-AZ replication for high availability, and sessions survive individual instance recycling. Option A ties users to specific instances (if the instance fails, the session is lost). Option C is not possible (EBS is not shared that way). Option D loses sessions when recycling.

**Key service/concept:** ElastiCache Redis, session store, stateless architecture
</details>

---

## Question 14

A company needs a centralized backup plan for their resources across multiple AWS accounts (EC2, EBS, RDS, DynamoDB, EFS). Backups must follow consistent policies and be retained for 90 days. What is the most appropriate service?

A) Create Lambda scripts in each account for scheduled snapshots
B) Use AWS Backup with Backup Plans and AWS Organizations Backup Policies
C) Configure each service individually with its native backups
D) Use S3 Cross-Region Replication for all data

<details>
<summary>Show answer</summary>

**Answer: B**

**AWS Backup** provides a centralized solution for managing backups of multiple AWS services. With **Backup Plans** you define policies (frequency, retention, destination region) and with **AWS Organizations Backup Policies** you apply them consistently across all accounts. It supports EC2, EBS, RDS, Aurora, DynamoDB, EFS, FSx, and more. Option A requires custom development and maintenance. Option C is not centralized. Option D is not a general backup solution.

**Key service/concept:** AWS Backup, Backup Plans, Organizations Backup Policies
</details>

---

## Question 15

An application uses a Network Load Balancer with EC2 instances in an Auto Scaling Group. The team detects that new instances receive traffic before the application is fully ready, causing temporary 503 errors. What is the best solution?

A) Increase the cooldown period of the Auto Scaling Group
B) Configure health checks on the NLB target group with a path that verifies the application is ready, and enable slow start on the target group
C) Use larger instances so they boot faster
D) Reduce the minimum number of instances to decrease rotation

<details>
<summary>Show answer</summary>

**Answer: B**

Configuring proper **health checks** on the target group ensures that the NLB only sends traffic to instances that pass the health check (application ready). Additionally, although NLB does not directly support slow start like ALB, configuring health checks with appropriate intervals and thresholds ensures that new instances do not receive traffic until they are ready. ASG lifecycle hooks can also be used to keep instances in "Pending:Wait" until the application is ready. Option A does not prevent sending traffic to unready instances. Options C and D do not solve the problem.

**Key service/concept:** Target Group health checks, ASG lifecycle hooks, instance readiness
</details>
