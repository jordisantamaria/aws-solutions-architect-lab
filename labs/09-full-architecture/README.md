# Lab 09: Complete Architecture - E-Commerce Platform (Final Project)

## Objective

Final project that combines all the concepts learned in the previous labs. Deploy a complete serverless e-commerce platform with authentication, API, database, cache, asynchronous processing, notifications, monitoring and security.

## Architecture

```
                                    +-------------+
                                    |   WAF       |
                                    |  (rules)    |
                                    +------+------+
                                           |
+----------+    +--------------+    +------v------+    +-------------+
| Users    |--->|  CloudFront  |--->| S3 Frontend |    |  Cognito    |
|          |    |  (CDN)       |    | (React/Vue) |    | (Auth)      |
+----+-----+    +--------------+    +-------------+    +------+------+
     |                                                         |
     |          +--------------+    +-------------+    +------v------+
     +--------->|  API Gateway |<-->|  Cognito    |--->|  Lambda     |
                |  (REST API)  |    |  Authorizer |    |  Functions  |
                +------+-------+    +-------------+    +--+---+---+-+
                       |                                   |   |   |
              +--------+--------+                          |   |   |
              |                 |                           |   |   |
       +------v------+  +------v------+           +--------+   |  +v--------+
       | get_products |  |create_order |           |Aurora   |  |  |ElastiCa-|
       | (Lambda)     |  |(Lambda)     |           |Server-  |  |  |che Redis|
       +------+-------+  +------+------+           |less v2  |  |  |(cache+  |
              |                 |                   +--------+   |  |sessions)|
              |                 v                                |  +---------+
              |          +-------------+                        |
              |          |  SQS Queue  |                        |
              |          | (orders)    |                        |
              |          +------+------+                        |
              |                 |              +-----------------+
              |          +------v------+       |
              |          |process_pay- |       |
              |          |ment (Lambda)|       |
              |          +------+------+       |
              |                 |        +-----v------+
              |          +------v------+ |S3 Uploads  |
              |          |  SNS Topic  | |(presigned  |
              |          |(notifica-   | | URLs)      |
              |          | tions)      | +------------+
              |          +-------------+
              |
       +------v----------------------------+
       |  CloudWatch                       |
       |  - Alarms (5xx, DLQ, CPU)         |
       |  - Dashboards                     |
       |  - Logs                           |
       +-----------------------------------+
```

## Mapping to the 4 SA Associate Exam Domains

### Domain 1: Design Secure Architectures (30%)
- **Cognito**: user authentication and authorization
- **WAF**: protection against common web attacks (SQL injection, XSS)
- **IAM Roles**: principle of least privilege for each Lambda
- **S3 Presigned URLs**: secure temporary access to files
- **Encryption**: data encrypted at rest and in transit

### Domain 2: Design Resilient Architectures (26%)
- **SQS + DLQ**: asynchronous processing with failure handling
- **Aurora Serverless**: automatic database scaling
- **ElastiCache**: cache to reduce database load
- **CloudFront**: global distribution with high availability
- **Multi-AZ**: Aurora and ElastiCache with replication

### Domain 3: Design High-Performing Architectures (24%)
- **CloudFront CDN**: static content close to the user
- **ElastiCache Redis**: session and frequent data cache
- **API Gateway**: throttling and response caching
- **Aurora Serverless v2**: rapid scaling based on demand
- **Lambda**: automatic scaling per function

### Domain 4: Design Cost-Optimized Architectures (20%)
- **Serverless**: pay-per-use (Lambda, API Gateway, Aurora Serverless)
- **S3 + CloudFront**: static hosting without servers
- **SQS**: decoupling to optimize resources
- **Aurora Serverless v2**: scales down to 0.5 ACU when there is no traffic

## Deployed Components

| Service | Resource | Function |
|----------|---------|---------|
| Cognito | User Pool + App Client | User authentication |
| S3 | Frontend bucket | Frontend hosting |
| CloudFront | Distribution | Global CDN |
| API Gateway | REST API | API entry point |
| Lambda | get_products | Query products |
| Lambda | create_order | Create orders |
| Lambda | process_payment | Process payments |
| Aurora | Serverless v2 PostgreSQL | Database |
| ElastiCache | Redis cluster | Cache and sessions |
| SQS | Queue + DLQ | Order processing |
| SNS | Topic | Order notifications |
| S3 | Uploads bucket | File uploads |
| WAF | WebACL | Web protection |
| CloudWatch | Alarms | Monitoring |

## Estimated Cost

**~$5-8/day** (mainly Aurora Serverless and ElastiCache)

> **Note**: Aurora Serverless v2 has a minimum of 0.5 ACU (~$0.12/hour). ElastiCache has a per-node cost. Destroy when not in use.

## This lab is the most complex - take your time

1. **Do not try to understand everything at once**. Review section by section.
2. **Deploy and experiment**. Make changes, break things, learn.
3. **Relate each component to the exam**. Ask yourself: if they ask me about this service on the exam, what would I answer?
4. **Draw the architecture by hand**. This helps a lot to consolidate knowledge.

## How to Deploy

```bash
# Initialize Terraform
terraform init

# View the plan (it will be long - many resources)
terraform plan

# Deploy
terraform apply

# Destroy when finished
terraform destroy
```

## Basic Testing

### 1. Test authentication with Cognito
```bash
# Create a test user
aws cognito-idp sign-up \
  --client-id <app_client_id> \
  --username testuser@example.com \
  --password "Test1234!"

# Confirm user (admin)
aws cognito-idp admin-confirm-sign-up \
  --user-pool-id <user_pool_id> \
  --username testuser@example.com
```

### 2. Test the API
```bash
# Get token
TOKEN=$(aws cognito-idp initiate-auth \
  --client-id <app_client_id> \
  --auth-flow USER_PASSWORD_AUTH \
  --auth-parameters USERNAME=testuser@example.com,PASSWORD="Test1234!" \
  --query 'AuthenticationResult.IdToken' --output text)

# Call the API
curl -H "Authorization: $TOKEN" https://<api_id>.execute-api.eu-west-1.amazonaws.com/prod/products
```

### 3. Verify CloudWatch
```bash
# View active alarms
aws cloudwatch describe-alarms --state-value ALARM
```

## Cleanup

```bash
# IMPORTANT: Destroy everything when finished
terraform destroy
```

> Verify in the console that no active resources remain. Pay special attention to Aurora, ElastiCache and S3 buckets.
