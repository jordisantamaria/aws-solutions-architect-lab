# Decision Tree: Compute Selection

## Main Question: What type of compute do you need?

```
What do you need to run?
│
├── FULL OS CONTROL / Custom AMI / GPU / Special Licenses
│   │
│   └──→ Amazon EC2
│        │
│        ├── What pricing model?
│        │   │
│        │   ├── Unpredictable workload / testing / short term
│        │   │   └──→ On-Demand ($$$)
│        │   │
│        │   ├── Stable workload / production / 1-3 years
│        │   │   ├──→ Reserved Instances (up to 72% discount)
│        │   │   └──→ Savings Plans (more flexibility across families)
│        │   │
│        │   ├── Tolerates interruptions / batch / CI/CD
│        │   │   └──→ Spot Instances (up to 90% discount)
│        │   │       └── Combine with On-Demand in ASG (mixed instances)
│        │   │
│        │   ├── Compliance / per-socket licensing
│        │   │   └──→ Dedicated Hosts
│        │   │
│        │   └── Dedicated hardware without managing host
│        │       └──→ Dedicated Instances
│        │
│        ├── Instance type?
│        │   ├── General purpose ──→ t3/m5/m6i
│        │   ├── CPU intensive ──→ c5/c6i
│        │   ├── Memory intensive ──→ r5/r6i/x1
│        │   ├── Storage I/O ──→ i3/d2
│        │   └── GPU (ML/render) ──→ p4/g5/inf1
│        │
│        └── Auto Scaling?
│            ├── Target Tracking (simplest)
│            ├── Step/Simple Scaling (alarm-based actions)
│            ├── Scheduled Scaling (known events)
│            └── Predictive Scaling (ML patterns)
│
├── SHORT-DURATION CODE (< 15 minutes, event-driven)
│   │
│   └──→ AWS Lambda
│        │
│        ├── Triggers:
│        │   ├── API Gateway (HTTP requests)
│        │   ├── S3 Events (object created/deleted)
│        │   ├── DynamoDB Streams (table changes)
│        │   ├── SQS (queue messages)
│        │   ├── SNS (notifications)
│        │   ├── EventBridge (scheduled/custom events)
│        │   ├── Kinesis (streaming data)
│        │   └── CloudWatch Events/Alarms
│        │
│        ├── Pricing: Per invocation + duration (ms) + memory
│        │   └── Free: 1M invocations + 400,000 GB-s/month
│        │
│        └── Limitations:
│            ├── Maximum 15 minutes per execution
│            ├── Maximum 10 GB of memory
│            ├── 1,000 concurrency by default
│            └── Cold start (mitigate with Provisioned Concurrency)
│
├── CONTAINERS
│   │
│   ├── Do you specifically need Kubernetes?
│   │   │
│   │   ├── YES ──→ Amazon EKS (Elastic Kubernetes Service)
│   │   │   ├── Multi-cloud portability
│   │   │   ├── Existing K8s ecosystem
│   │   │   ├── Helm charts, operators, etc.
│   │   │   └── Price: $0.10/hr per cluster + compute
│   │   │
│   │   └── NO (I want something simpler)
│   │       └──→ Amazon ECS (Elastic Container Service)
│   │           ├── Deeper native AWS integration
│   │           ├── Task definitions, services
│   │           ├── Simpler than K8s
│   │           └── No control plane cost
│   │
│   └── Do you want to manage the underlying EC2 infrastructure?
│       │
│       ├── YES ──→ EC2 Launch Type
│       │   ├── Full control of instances
│       │   ├── You can use Spot/Reserved
│       │   └── You manage the capacity
│       │
│       └── NO (serverless) ──→ AWS Fargate
│           ├── No server management
│           ├── Pay per vCPU + memory used
│           ├── Works with ECS and EKS
│           └── More expensive than EC2 Launch Type but no management
│
├── BATCH PROCESSING (queued jobs, massive processing)
│   │
│   └──→ AWS Batch
│        ├── Schedules and runs jobs on EC2 or Fargate
│        ├── Automatic queue and compute management
│        ├── Ideal with Spot Instances for savings
│        ├── Image processing, simulations, rendering
│        └── No time limit (unlike Lambda)
│
├── PaaS (I just want to deploy my code, without managing infra)
│   │
│   └──→ AWS Elastic Beanstalk
│        ├── Supports: Java, .NET, PHP, Node.js, Python, Ruby, Go, Docker
│        ├── Automatically manages: EC2, ASG, ELB, RDS
│        ├── You control the underlying resources
│        ├── No additional cost (you pay for the resources)
│        └── Deployments: All at once, Rolling, Immutable, Blue/Green
│
├── EDGE COMPUTING (processing close to the user)
│   │
│   ├── Lightweight code at CloudFront edge
│   │   ├── CloudFront Functions (< 1 ms, JS, header manipulation)
│   │   └── Lambda@Edge (up to 30s, more features, viewer/origin)
│   │
│   ├── Outposts (AWS in your datacenter)
│   │   └── Ultra-low latency, data residency
│   │
│   └── Wavelength (within 5G networks)
│       └── Ultra-low latency mobile applications
│
└── HYBRID COMPUTING
    │
    ├── AWS in your datacenter ──→ Outposts
    ├── VMware on AWS ──→ VMware Cloud on AWS
    └── Manage on-prem servers ──→ Systems Manager
```

---

## Quick Decision Table with Pricing

| Service | Pricing Model | Relative Cost | When to Use |
|---------|--------------|---------------|-------------|
| **EC2 On-Demand** | Per hour/second | $$$ | Development, testing, unpredictable workloads |
| **EC2 Reserved** | 1-3 year commitment | $ | Stable production (up to 72% discount) |
| **EC2 Spot** | Bid for spare capacity | ¢ | Batch, CI/CD, fault-tolerant (up to 90% discount) |
| **Lambda** | Per invocation + duration | ¢-$$ | Event-driven, < 15 min, variable traffic |
| **Fargate** | Per vCPU + memory per second | $$ | Containers without server management |
| **ECS (EC2)** | Underlying EC2 instances | $-$$ | Containers with infra control |
| **EKS** | $0.10/hr cluster + compute | $$-$$$ | Kubernetes, portability, K8s ecosystem |
| **Batch** | Underlying EC2/Fargate | $-$$ | Queued jobs, massive processing |
| **Beanstalk** | Underlying resources | $-$$$ | Quick PaaS, no operations overhead |

---

## Comparison: Lambda vs Fargate vs EC2

| Criterion | Lambda | Fargate | EC2 |
|-----------|--------|---------|-----|
| **Server management** | None | None | You manage |
| **Maximum duration** | 15 minutes | Unlimited | Unlimited |
| **Scaling** | Automatic (concurrency) | Automatic (tasks) | Auto Scaling Groups |
| **Cold start** | Yes (mitigable) | Yes (~30s) | No (instance running) |
| **Billing** | Per ms of execution | Per second (vCPU+mem) | Per hour/second |
| **Idle cost** | $0 | $0 (if 0 tasks) | You pay for the instance |
| **Container support** | Container images | Native Docker | Docker on EC2 |
| **Networking** | VPC optional | VPC (ENI per task) | Full VPC |
| **Ideal for** | Events, APIs, short processing | Microservices, long-running apps without management | Full control, GPU, compliance |

---

## Common Exam Patterns

### Pattern 1: Scalable Web Application
```
Route 53 ──→ CloudFront ──→ ALB ──→ EC2 Auto Scaling Group
                                         │
                                    ┌────┴────┐
                                    │ EC2     │ EC2 (min 2, multi-AZ)
                                    └─────────┘
```

### Pattern 2: Serverless Microservices
```
API Gateway ──→ Lambda ──→ DynamoDB
                  │
                  └──→ SQS ──→ Lambda (async processing)
```

### Pattern 3: Containers with High Availability
```
ALB ──→ ECS/EKS Fargate ──→ Aurora
             │
        Auto Scaling (target tracking by CPU)
```

### Pattern 4: Cost-Effective Batch Processing
```
S3 (input) ──→ EventBridge ──→ AWS Batch (Spot Instances) ──→ S3 (output)
```

---

## Exam Keywords → Service

```
"Full OS control / custom AMI"               → EC2
"GPU / ML training"                           → EC2 (P/G instances) or SageMaker
"Event-driven, short duration"                → Lambda
"Serverless containers"                       → Fargate (ECS or EKS)
"Kubernetes"                                  → EKS
"Simple container orchestration"              → ECS
"Deploy code without managing infra"          → Elastic Beanstalk
"Batch jobs / queue processing"               → AWS Batch
"Lowest cost, can be interrupted"             → Spot Instances
"Stable workload, cost savings"               → Reserved / Savings Plans
"Edge computing on CloudFront"                → Lambda@Edge / CloudFront Functions
"AWS in your datacenter"                      → Outposts
"Auto scale based on CPU"                     → ASG + Target Tracking
"Scheduled scaling for known events"          → ASG + Scheduled Scaling
"Run containers, no cluster management"       → Fargate
"Licensing per physical socket"               → Dedicated Hosts
```
