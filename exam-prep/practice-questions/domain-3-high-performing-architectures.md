# Domain 3: Design High-Performing Architectures

## Question 1

A company has a global website with static content (images, CSS, JS) stored in S3 and dynamic content served by EC2 instances in eu-west-1. Users in Asia and the Americas experience latencies of 2-3 seconds. What is the best solution to improve performance globally?

A) Deploy the application in all regions with Route 53 Latency-based routing
B) Configure CloudFront with an S3 origin for static content and an ALB origin for dynamic content
C) Use S3 Transfer Acceleration for all requests
D) Increase the size of the EC2 instances

<details>
<summary>Show answer</summary>

**Answer: B**

CloudFront with multiple origins is the standard solution. Static content is cached at the 400+ global edge locations, eliminating latency to S3. Dynamic content benefits from AWS's optimized network between edge locations and the origin (ALB). CloudFront supports multiple origins with behaviors based on path patterns (e.g., /static/* → S3, /* → ALB). Option A is excessive and costly. Option C is for uploads, not delivery. Option D does not resolve geographic latency.

**Key service/concept:** CloudFront, multiple origins, edge caching, path-based routing
</details>

---

## Question 2

An e-commerce application has an RDS MySQL database with high read load. Product pages take more than 5 seconds to load because each view executes complex database queries. The same products are queried thousands of times per hour. What is the best solution to reduce latency?

A) Vertically scale the RDS instance to a larger class
B) Implement ElastiCache Redis as a cache layer between the application and RDS, with cache-aside pattern
C) Create 5 RDS Read Replicas
D) Migrate to DynamoDB

<details>
<summary>Show answer</summary>

**Answer: B**

ElastiCache Redis with the **cache-aside** (lazy loading) pattern drastically reduces latency: the first query reads from RDS and stores the result in cache; subsequent queries for the same product are served from Redis with sub-millisecond latency. For repeatedly queried data (popular products), the hit rate will be very high. Option A improves marginally. Option C distributes reads but each query still hits disk. Option D requires redesigning the application and is not compatible with complex SQL queries.

**Key service/concept:** ElastiCache Redis, cache-aside pattern, read performance
</details>

---

## Question 3

An IoT application ingests 100,000 events per second from globally distributed sensors. Each event is ~1 KB. The data must be available in real time for dashboards and also stored in S3 for later analytics. What is the most efficient architecture?

A) Sensors send to SQS → Lambda processes and stores in S3
B) Sensors send to API Gateway → Lambda stores in DynamoDB and S3
C) Sensors send to Kinesis Data Streams → Lambda for real-time dashboards + Kinesis Firehose for delivery to S3
D) Sensors send directly to S3 and a batch process analyzes every hour

<details>
<summary>Show answer</summary>

**Answer: C**

Kinesis Data Streams handles 100K+ events/second with multiple simultaneous consumers. Lambda (or Kinesis Data Analytics) consumes the stream for real-time dashboards, while Kinesis Firehose consumes the same stream to deliver data to S3 automatically (near real-time, with buffering and compression). Option A: SQS does not support multiple consumers of the same message. Option B: API Gateway + Lambda has concurrency limits and is more expensive for this volume. Option D is not real-time.

**Key service/concept:** Kinesis Data Streams, Kinesis Firehose, real-time streaming, multiple consumers
</details>

---

## Question 4

A global gaming application needs a NoSQL database with single-digit millisecond read latency that supports bursts of millions of requests. The table has a hot partition on the item "leaderboard-global" that is constantly read. How to optimize performance?

A) Use DynamoDB with provisioned capacity and increase RCUs
B) Use DynamoDB with DAX for caching frequent reads, resolving the hot partition
C) Migrate to RDS Aurora with read replicas
D) Use ElastiCache Redis directly as the primary database

<details>
<summary>Show answer</summary>

**Answer: B**

**DAX** (DynamoDB Accelerator) is an in-memory cache specific to DynamoDB that reduces latency from milliseconds to microseconds. For hot partitions (items constantly read like a global leaderboard), DAX absorbs repetitive reads without consuming RCUs on the underlying table. Option A only increases raw capacity but the hot partition remains a bottleneck. Option C changes to an inappropriate relational model. Option D loses DynamoDB's features.

**Key service/concept:** DynamoDB Accelerator (DAX), hot partition, microsecond latency
</details>

---

## Question 5

A company needs to serve video files of 2-10 GB stored in S3 to global users. Users experience slow download speeds, especially from Asia and South America. What is the best solution to accelerate downloads?

A) Enable S3 Transfer Acceleration
B) Use CloudFront with S3 as origin, enabling byte-range fetches
C) Copy the videos to S3 buckets in all regions
D) Use an NLB in front of S3 to improve throughput

<details>
<summary>Show answer</summary>

**Answer: B**

CloudFront caches content at global edge locations. For large video files, CloudFront supports **byte-range fetches** (Range requests) that allow partial and parallel downloads. Once a video is requested, it is cached at the edge location closest to the user, drastically improving subsequent downloads. Option A is for **uploads** to S3 (not downloads). Option C is costly and hard to manage. Option D: NLB cannot be placed in front of S3 directly.

**Key service/concept:** CloudFront, edge caching, byte-range fetches, large file delivery
</details>

---

## Question 6

A DynamoDB database has a table with provisioned mode (5,000 RCU, 1,000 WCU). The application needs to read items of 8 KB in size with eventual consistency. How many reads per second can the table perform?

A) 5,000 reads/s
B) 2,500 reads/s
C) 10,000 reads/s
D) 1,250 reads/s

<details>
<summary>Show answer</summary>

**Answer: A**

Calculation: 1 RCU = 1 strongly consistent read of up to 4 KB/s = 2 eventually consistent reads of up to 4 KB/s. For 8 KB items: each read consumes ceil(8/4) = 2 read capacity units (strongly consistent) or 1 RCU (eventually consistent, since 2/2 = 1). With 5,000 RCU and **eventually consistent** reads of 8 KB: 5,000 RCU / 1 RCU per read = **5,000 reads/s**.

Correction: The correct answer is **A) 5,000 reads/s**. Each 8 KB item requires ceil(8/4) = 2 read units. With eventually consistent, divide by 2: 2/2 = 1 RCU per read. With 5,000 RCU: 5,000/1 = 5,000 reads/s.

**Key service/concept:** DynamoDB RCU calculation, eventually consistent reads
</details>

---

## Question 7

An application needs a REST API that can handle bursts of up to 10,000 requests per second. The response for 80% of requests is identical during 5-minute periods. What is the most efficient way to handle this load?

A) API Gateway with Lambda backend and Lambda concurrency Auto Scaling
B) API Gateway with caching enabled (5 minutes TTL) and Lambda backend
C) ALB with EC2 Auto Scaling Group
D) API Gateway with direct integration to DynamoDB

<details>
<summary>Show answer</summary>

**Answer: B**

API Gateway offers **built-in caching** that stores responses and serves them directly without invoking the backend. With a 5-minute TTL and 80% of identical requests, the cache absorbs the vast majority of traffic, dramatically reducing Lambda invocations and latency for the user. This reduces costs and improves performance simultaneously. Option A handles the load but without optimizing repetitive requests. Option C requires more management. Option D only works for simple CRUD operations.

**Key service/concept:** API Gateway caching, TTL, request deduplication
</details>

---

## Question 8

A company needs their EC2 instances in eu-west-1 to access data in an S3 bucket in us-east-1 with maximum possible performance. The files are 5-50 GB each. What is the best strategy?

A) Use S3 Transfer Acceleration for cross-region transfers
B) Use multipart upload with parallel transfers and S3 Transfer Acceleration
C) Replicate the bucket to eu-west-1 with S3 Cross-Region Replication and access locally
D) Use Direct Connect between the two regions

<details>
<summary>Show answer</summary>

**Answer: C**

If EC2 instances in eu-west-1 need frequent, maximum-performance access to the data, the best solution is to **replicate the data to a local bucket** using S3 Cross-Region Replication (CRR). This way, instances access data in the same region with minimal latency. Options A and B improve transfer but remain cross-region. Option D is for on-prem, not between AWS regions. The additional storage cost is offset by the performance gains.

**Key service/concept:** S3 Cross-Region Replication, data locality, cross-region performance
</details>

---

## Question 9

A development team has a Lambda function invoked by API Gateway. Users experience elevated latency (3-5 seconds) on the first request after a period of inactivity, but subsequent requests are fast (~200ms). What is the best solution?

A) Increase the memory assigned to the Lambda
B) Configure Provisioned Concurrency for the Lambda function
C) Use Lambda@Edge instead of standard Lambda
D) Reduce the deployment package size

<details>
<summary>Show answer</summary>

**Answer: B**

The described problem is Lambda **cold start**. The first invocation after inactivity requires AWS to provision an execution environment, which takes additional time. **Provisioned Concurrency** maintains a configurable number of "warm" execution environments permanently, eliminating cold starts. Option A may help marginally but does not eliminate cold start. Option C changes the execution location, not the cold start problem. Option D helps minimally.

**Key service/concept:** Lambda cold start, Provisioned Concurrency
</details>

---

## Question 10

An application uses RDS PostgreSQL with a db.r5.xlarge instance. The monitoring team detects that ReadIOPS is constantly at 90% of the maximum, but CPU is at 30%. The most frequent queries are complex JOINs that access large tables. What is the best optimization?

A) Vertically scale to db.r5.2xlarge
B) Migrate from gp2 to io2 storage for more provisioned IOPS
C) Create Read Replicas to distribute reads
D) Create Read Replicas for read queries and add ElastiCache for frequent query results

<details>
<summary>Show answer</summary>

**Answer: D**

The bottleneck is I/O, not CPU. The combination of **Read Replicas** to distribute read queries across multiple instances and **ElastiCache** to cache frequent query results addresses the problem from two angles. Repetitive queries are served from cache (eliminating I/O), and non-cached queries are distributed across replicas. Option A gives more CPU but does not resolve I/O. Option B helps with IOPS but is more expensive and limited. Option C alone helps but does not optimize repetitive queries.

**Key service/concept:** Read Replicas, ElastiCache, I/O optimization, query caching
</details>

---

## Question 11

A company needs to process uploads of 10-50 GB video files uploaded by users from around the world. Uploads are slow and frequently fail, especially from Asia. What is the best solution to improve upload speed and reliability?

A) Increase the timeout of the web server receiving uploads
B) Use S3 Multipart Upload with S3 Transfer Acceleration enabled
C) Deploy upload servers in multiple regions
D) Use CloudFront to cache uploads

<details>
<summary>Show answer</summary>

**Answer: B**

**S3 Multipart Upload** splits large files into parts that upload in parallel. If one part fails, only that part is retried (not the entire file). **S3 Transfer Acceleration** uses CloudFront edge locations to accelerate data transfer to the destination S3 bucket using AWS's optimized network. Combined, they provide fast and reliable uploads from any global location. Option A does not improve speed. Option C is complex. Option D: CloudFront does not cache uploads.

**Key service/concept:** S3 Multipart Upload, S3 Transfer Acceleration, upload optimization
</details>

---

## Question 12

An application needs a database with consistent microsecond read performance and the ability to horizontally scale reads. The data is simple key-value pairs of less than 1 KB with a volume of 500,000 reads per second. What is the most appropriate solution?

A) DynamoDB with high Provisioned Capacity
B) DynamoDB with DAX
C) Aurora MySQL with read replicas
D) ElastiCache Redis cluster mode

<details>
<summary>Show answer</summary>

**Answer: B**

DynamoDB with DAX provides **microsecond** read latency. DynamoDB alone has single-digit millisecond latency. DAX works as a transparent cache: the application uses the same DynamoDB API but points to the DAX cluster. For 500K reads/s of simple, small key-value data, DAX is optimal since the items fit easily in memory. Option A gives milliseconds, not microseconds. Option C has higher latency for simple key-value. Option D works but loses DynamoDB's advantages as a persistent backend.

**Key service/concept:** DynamoDB + DAX, microsecond reads, key-value at scale
</details>

---

## Question 13

A company has an API Gateway REST API that invokes Lambda functions. The API serves data from multiple microservices. Performance needs to improve for responses that rarely change (product catalog). Additionally, some endpoints have heavy logic that would benefit from more resources. What are two improvements they can implement? (Select TWO)

A) Enable API Gateway stage caching with TTL for catalog endpoints
B) Increase the memory assigned to the Lambda functions (which also proportionally increases CPU)
C) Migrate from REST API to HTTP API in API Gateway
D) Use VPC endpoints for API Gateway
E) Convert the Lambdas to EC2 instances for more control

<details>
<summary>Show answer</summary>

**Answer: A and B**

**A)** API Gateway caching stores responses and serves them without invoking Lambda, ideal for data that rarely changes like product catalogs. **B)** In Lambda, CPU is allocated proportionally to memory. Increasing memory also increases CPU power, improving performance for computationally intensive logic. Option C may reduce latency marginally but does not cache. Option D is for private access, not performance. Option E adds operational complexity.

**Key service/concept:** API Gateway caching, Lambda memory/CPU scaling
</details>

---

## Question 14

A team needs to run analytical SQL queries on data stored in S3 in Parquet format. Queries are run ad-hoc a few times per day. They do not want to maintain infrastructure or load data into another database. What is the most efficient solution?

A) Load the data into Redshift and run queries
B) Use Amazon Athena for direct queries on S3
C) Use EMR with Apache Hive
D) Copy data to Aurora and run SQL queries

<details>
<summary>Show answer</summary>

**Answer: B**

**Amazon Athena** is a serverless interactive query service that allows running SQL directly on data in S3. It requires no infrastructure, you do not need to load data into another database, and you only pay for the amount of data scanned per query. Parquet is a columnar format that Athena automatically optimizes (scans only the necessary columns). Option A requires maintaining a cluster. Option C is complex for ad-hoc queries. Option D requires ETL and a database.

**Key service/concept:** Amazon Athena, serverless SQL on S3, Parquet optimization
</details>

---

## Question 15

There is a new compliance rule in your company that audits every Windows and Linux EC2 instances each month to view any performance issues. They have more than a hundred EC2 instances running in production, and each must have a logging function that collects various system details regarding that instance. The SysOps team will periodically review these logs and analyze their contents using AWS Analytics tools, and the result will need to be retained in an S3 bucket.

In this scenario, what is the most efficient way to collect and analyze logs from the instances with minimal effort?

A) Install the unified CloudWatch Logs agent in each instance which will automatically collect and push data to CloudWatch Logs. Analyze the log data with CloudWatch Logs Insights.
B) Install AWS Inspector Agent in each instance which will collect and push data to CloudWatch Logs periodically. Set up a CloudWatch dashboard to properly analyze the log data of all instances.
C) Install AWS SDK in each instance and create a custom daemon script that would collect and push data to CloudWatch Logs periodically. Enable CloudWatch detailed monitoring and use CloudWatch Logs Insights to analyze the log data of all instances.
D) Install the AWS Systems Manager Agent (SSM Agent) in each instance which will automatically collect and push data to CloudWatch Logs. Analyze the log data with CloudWatch Logs Insights.

<details>
<summary>Show answer</summary>

**Answer: A**

The **CloudWatch Unified Agent** is the tool specifically designed to collect logs and system metrics (RAM, disk, processes, etc.) from EC2 instances (Windows and Linux) and send them to CloudWatch Logs automatically. **CloudWatch Logs Insights** allows analyzing those logs with a query language. Logs can be exported to S3 for retention.

Why the others are incorrect:
- **B) Inspector Agent**: AWS Inspector is for **security vulnerability assessment** (CVEs, network exposure), not for collecting system performance logs. Wrong tool for the use case.
- **C) AWS SDK + custom daemon**: Would work technically, but creating a custom daemon is NOT "minimal effort". The CloudWatch Agent already does this out-of-the-box without writing code.
- **D) SSM Agent**: The SSM Agent is for **remote management** of instances (running commands, patching, inventory). It does not collect or send system logs to CloudWatch Logs. SSM could be used to *install* the CloudWatch Agent, but it does not do the collection itself.

**Exam pattern**: When the question says "minimal effort" or "most efficient", rule out options involving custom code if a managed service exists that does it. The CloudWatch Unified Agent is the standard answer for "collect system logs and metrics from EC2".

**Key services/concepts:** CloudWatch Unified Agent, CloudWatch Logs, CloudWatch Logs Insights, difference between Inspector/SSM/CloudWatch Agent
</details>

---

## Question 16

A global company needs their APIs to be available with ultra-low latency and static IPs so their enterprise clients can include them in their firewall allowlists. They currently use ALB in us-east-1. What is the best solution?

A) Deploy ALBs in multiple regions with Route 53 Latency-based routing
B) Put CloudFront in front of the ALB
C) Use AWS Global Accelerator in front of the ALB
D) Assign Elastic IPs to the ALB

<details>
<summary>Show answer</summary>

**Answer: C**

**AWS Global Accelerator** provides 2 global static Anycast IPs that clients can include in their firewall allowlists. Traffic enters through the nearest edge location to the user and is routed through AWS's global network to the ALB, significantly reducing latency. Option A requires deploying infrastructure in multiple regions. Option B provides a DNS domain, not static IPs. Option D: ALBs do not support Elastic IPs directly (only NLB).

**Key service/concept:** Global Accelerator, static Anycast IPs, reduced latency
</details>
