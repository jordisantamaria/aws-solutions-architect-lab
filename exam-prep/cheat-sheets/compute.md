# Compute - Quick Cheat Sheet

## EC2 Instance Types

| Family | Prefix | Quick Description |
|--------|--------|-------------------|
| **General Purpose** | `t3, t3a, m5, m6i` | Balanced CPU/memory — web apps, microservices, dev environments |
| **Compute Optimized** | `c5, c6i, c7g` | High CPU — batch processing, scientific modeling, gaming servers |
| **Memory Optimized** | `r5, r6i, x1, z1d` | High memory — in-memory databases, large caches, SAP HANA |
| **Storage Optimized** | `i3, i4i, d2, h1` | High sequential or random I/O — data warehouses, HDFS, Elasticsearch |
| **Accelerated Computing** | `p4, p5, g5, inf1, trn1` | GPU/FPGA — machine learning, 3D rendering, video transcoding |
| **HPC Optimized** | `hpc6a, hpc7g` | High computational performance — simulations, fluid dynamics |

> **Exam trick:** The initial letter indicates the family: **T**urbo(burstable), **M**emory+CPU, **C**ompute, **R**AM, **I**/O, **P**arallel processing (GPU).

---

## EC2 Pricing Models

| Model | Discount vs On-Demand | Commitment | Interruption | Use Case |
|-------|----------------------|------------|-------------|----------|
| **On-Demand** | 0% (base price) | None | No | Unpredictable workloads, testing, development |
| **Reserved (RI)** | Up to **72%** | 1 or 3 years | No | Stable and predictable workloads (production) |
| **Savings Plans** | Up to **72%** | 1 or 3 years ($/hr) | No | Flexibility across families, regions, or services |
| **Spot Instances** | Up to **90%** | None | **Yes** (2 min notice) | Batch, CI/CD, fault-tolerant processing |
| **Dedicated Hosts** | Variable | Optional | No | Per-socket/core licenses, strict compliance |
| **Dedicated Instances** | Variable | None | No | Dedicated hardware without managing the host |
| **Capacity Reservations** | 0% | None (On-Demand pricing) | No | Guarantee capacity in a specific AZ |

> **Exam key:** If they ask "lowest cost" + "can be interrupted" = **Spot**. If it's "lowest cost" + "stable workload" = **Reserved/Savings Plans**.

---

## AWS Lambda Limits

| Parameter | Limit |
|-----------|-------|
| **Memory** | 128 MB — 10,240 MB (10 GB) |
| **Maximum timeout** | 15 minutes (900 seconds) |
| **Package size (zip, direct)** | 50 MB compressed / 250 MB uncompressed |
| **Size with layers** | 250 MB uncompressed total |
| **Container image** | 10 GB |
| **Concurrency per region** | 1,000 (default, can be increased) |
| **Reserved concurrency** | Configurable per function |
| **Ephemeral storage `/tmp`** | 512 MB — 10,240 MB |
| **Environment variables** | 4 KB total |
| **Synchronous payload** | 6 MB |
| **Asynchronous payload** | 256 KB |

> **Exam trick:** If the process lasts more than 15 min → **DO NOT** use Lambda. Consider ECS/Fargate, Batch, or Step Functions.

---

## ECS vs EKS vs Fargate

| Service | When to use |
|---------|-------------|
| **ECS** | Simple container orchestration, native AWS integration, don't need Kubernetes |
| **EKS** | Already using Kubernetes, need multi-cloud portability, or team knows K8s |
| **Fargate** | Don't want to manage underlying servers/instances — serverless for containers (works with ECS or EKS) |

```
Containers?
  ├── Need Kubernetes? ──→ YES ──→ EKS
  │                        └─ NO ──→ ECS
  └── Want to manage the infrastructure (EC2)?
       ├── YES ──→ EC2 Launch Type
       └── NO ──→ Fargate Launch Type
```

---

## Auto Scaling Policies

| Policy Type | Description | Example |
|-------------|-------------|---------|
| **Target Tracking** | Maintains a metric at a target value — the simplest and recommended | "Keep CPU at 50%" |
| **Step Scaling** | Stepped actions based on alarm magnitude | CPU > 60% → +1, CPU > 80% → +3 |
| **Simple Scaling** | One action per alarm, waits cooldown before another action | CPU > 70% → +1 (cooldown 300s) |
| **Scheduled Scaling** | Scale at predefined schedules | "Monday to Friday at 8:00 AM → min 10 instances" |
| **Predictive Scaling** | Uses ML to predict future traffic and pre-scale | Recurring daily/weekly patterns |

> **Exam key:** **Target Tracking** is the default answer when they ask for the "simplest" way to scale. **Predictive** when they mention predictable patterns. **Scheduled** for known events.

### Key Auto Scaling Concepts

- **Cooldown period:** Wait time after a scaling action (default 300s)
- **Warm-up time:** Time a new instance needs before contributing to metrics
- **Desired capacity:** Current number of desired instances
- **Min/Max capacity:** Group limits

---

## Elastic Beanstalk Deployment Types

| Type | Downtime | Speed | Rollback | Extra Cost | Description |
|------|----------|-------|----------|------------|-------------|
| **All at once** | **Yes** | Fastest | Manual re-deploy | No | Deploys to all instances simultaneously |
| **Rolling** | No (partial) | Medium | Manual re-deploy | No | Deploys in batches — some instances temporarily on previous version |
| **Rolling with additional batch** | No | Medium-slow | Manual re-deploy | **Yes** (extra instances) | Launches extra batch before updating — maintains full capacity |
| **Immutable** | No | Slow | Terminate new ones | **Yes** (temporary double) | Creates new instances in new ASG, swaps if healthy |
| **Traffic splitting** | No | Slow | Redirect traffic | **Yes** (temporary double) | Canary: sends % of traffic to new version |
| **Blue/Green** | No | Medium | Swap URL | **Yes** (duplicated environment) | Two Beanstalk environments, swap CNAME when ready |

> **Exam key:** "No downtime + lowest risk" = **Immutable** or **Blue/Green**. "No extra cost" = **Rolling**. "Fastest" = **All at once**.

---

## Quick Decision Summary - Compute

```
EXAM QUESTION                                → ANSWER
─────────────────────────────────────────────────────────
"Lowest possible cost, tolerates interruptions" → Spot Instances
"Stable workload, lowest long-term cost"        → Reserved / Savings Plans
"Run code without managing servers"             → Lambda (< 15 min) or Fargate
"Containers without managing infrastructure"    → Fargate
"Simplest deployment for developers"            → Elastic Beanstalk
"Auto scale based on demand"                    → Auto Scaling + Target Tracking
"Large-scale batch processing"                  → AWS Batch (+ Spot)
"GPU for machine learning"                      → EC2 P/G instances or SageMaker
```
