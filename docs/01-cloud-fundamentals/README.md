# Cloud Computing and AWS Fundamentals

## Table of Contents

- [What is Cloud Computing](#what-is-cloud-computing)
- [AWS Global Infrastructure](#aws-global-infrastructure)
- [How to Choose a Region](#how-to-choose-a-region)
- [AWS Well-Architected Framework](#aws-well-architected-framework)
- [Shared Responsibility Model](#shared-responsibility-model)
- [AWS Support Plans](#aws-support-plans)
- [Pricing Fundamentals](#pricing-fundamentals)
- [Key Points for the Exam](#key-points-for-the-exam)

---

## What is Cloud Computing

### NIST Definition

The National Institute of Standards and Technology (NIST) defines cloud computing as a model that enables ubiquitous, convenient, on-demand network access to a shared pool of configurable computing resources (networks, servers, storage, applications, and services) that can be rapidly provisioned and released with minimal management effort or service provider interaction.

### Five Essential Characteristics (NIST)

1. **On-demand self-service** - The user provisions resources without human interaction with the provider.
2. **Broad network access** - Resources are available over the network through standard mechanisms.
3. **Resource pooling** - The provider's resources are pooled to serve multiple consumers (multi-tenant).
4. **Rapid elasticity** - Resources can be elastically provisioned and released, sometimes automatically.
5. **Measured service** - Resource usage is monitored, controlled, and reported transparently.

### Service Models

| Model | Description | You manage | AWS manages | AWS Example |
|-------|-------------|------------|-------------|-------------|
| **IaaS** (Infrastructure as a Service) | Basic virtualized infrastructure | OS, apps, data, middleware, runtime | Hardware, network, virtualization | EC2, VPC, EBS |
| **PaaS** (Platform as a Service) | Platform for developing and deploying apps | Application code and data | OS, middleware, runtime, infrastructure | Elastic Beanstalk, RDS, Lambda |
| **SaaS** (Software as a Service) | Fully managed application | Usage and configuration only | Everything else | Amazon WorkMail, Amazon Chime |

### Deployment Models

| Model | Description | Use Case |
|-------|-------------|----------|
| **Public Cloud** | Resources owned by the cloud provider, delivered over the internet | Startups, scalable web applications |
| **Private Cloud** | Cloud infrastructure exclusive to one organization | Strict regulations, full control |
| **Hybrid Cloud** | Combination of public cloud and private/on-premises | Gradual migration, sensitive data on-prem |

---

## AWS Global Infrastructure

### Regions

- A **Region** is a geographic area containing multiple Availability Zones.
- Each Region is completely isolated from others to achieve maximum fault tolerance.
- Most AWS services are **regional** (data is not automatically replicated between regions).
- There are currently more than 30 regions globally.

### Availability Zones (AZs)

- Each Region has **at least 2 AZs** (generally 3, some have up to 6).
- Each AZ is one or more discrete data centers with redundant power, networking, and connectivity.
- AZs within a Region are connected with **low-latency, high-throughput, highly redundant** networks.
- They are physically separated (significant distance) to protect against local disasters.
- Identified with a region code + letter (e.g., `eu-west-1a`, `eu-west-1b`).

> **Important for the exam:** AZ letters are mapped differently per account. The AZ `us-east-1a` in your account may not be the same data center as `us-east-1a` in another account. Use **AZ IDs** (e.g., `use1-az1`) for consistent identification.

### Edge Locations

- Points of Presence (PoP) distributed worldwide (400+).
- Used by **CloudFront** (CDN) and **Route 53** (DNS).
- Allow serving content with low latency to end users.
- Also used by **AWS WAF** and **AWS Shield** for DDoS protection.
- **Regional Edge Caches** are an intermediate level between the Origin and Edge Locations.

### Local Zones

- Extensions of a Region that place compute, storage, and database services closer to large population centers.
- Provide single-digit millisecond latency for latency-sensitive applications.
- Example: `us-east-1-bos-1a` (Boston Local Zone of us-east-1).
- Ideal for gaming, real-time streaming, machine learning inference.

### AWS Wavelength

- AWS infrastructure embedded within 5G networks of telecommunications operators.
- Ultra-low latency for mobile applications.
- Use case: applications requiring single-digit millisecond latency from 5G devices.

### AWS Outposts

- AWS hardware installed in your own on-premises data center.
- Offers the same AWS services, APIs, and tools on your infrastructure.
- For workloads requiring low latency to on-premises systems or local data residency.

---

## How to Choose a Region

When selecting an AWS Region, consider these four factors (in typical priority order):

| Factor | Description | Example |
|--------|-------------|---------|
| **Compliance / Regulatory requirements** | Legal requirements about where data must reside | GDPR requires EU citizen data in the EU; French government data must be in France |
| **Latency / Proximity to users** | Choose the region closest to end users | App for users in Spain -> `eu-west-1` (Ireland) or `eu-south-2` (Spain) |
| **Available services** | Not all services are available in all regions | New services usually launch first in `us-east-1` |
| **Cost** | Prices vary between regions | Sao Paulo is usually more expensive than Virginia |

> **Exam tip:** If a question mentions compliance or regulatory requirements, **always** prioritize the region that meets those requirements, even if it's not the cheapest or closest.

---

## AWS Well-Architected Framework

The Well-Architected Framework provides a consistent approach for evaluating architectures and guidance for implementing designs that scale over time. It consists of **6 pillars**:

### 1. Operational Excellence

- **Goal:** Run and monitor systems to deliver business value and continuously improve processes and procedures.
- **Key principles:**
  - Perform operations as code (IaC).
  - Make frequent, small, reversible changes.
  - Refine operations procedures frequently.
  - Anticipate failure and learn from all operational failures.
- **Key services:** CloudFormation, AWS Config, CloudWatch, CloudTrail, X-Ray.

### 2. Security

- **Goal:** Protect data, systems, and assets through risk assessments and mitigation strategies.
- **Key principles:**
  - Implement a strong identity foundation (least privilege).
  - Enable traceability.
  - Apply security at all layers.
  - Automate security best practices.
  - Protect data in transit and at rest.
  - Keep people away from data.
  - Prepare for security events.
- **Key services:** IAM, KMS, CloudTrail, GuardDuty, WAF, Shield, Macie.

### 3. Reliability

- **Goal:** Ensure a system can recover from infrastructure or service failures, dynamically acquire resources to meet demand, and mitigate disruptions.
- **Key principles:**
  - Automatically test recovery procedures.
  - Automatically recover from failure.
  - Scale horizontally to increase availability.
  - Stop guessing capacity.
  - Manage change through automation.
- **Key services:** Auto Scaling, CloudWatch, Route 53, S3, RDS Multi-AZ, Backup.

### 4. Performance Efficiency

- **Goal:** Use computing resources efficiently to meet system requirements and maintain that efficiency as demand changes and technologies evolve.
- **Key principles:**
  - Democratize advanced technologies (use managed services).
  - Go global in minutes.
  - Use serverless architectures.
  - Experiment more frequently.
  - Have mechanical sympathy (use the right technology for each use case).
- **Key services:** Auto Scaling, Lambda, ECS/EKS, ElastiCache, CloudFront, Global Accelerator.

### 5. Cost Optimization

- **Goal:** Run systems to deliver business value at the lowest possible cost.
- **Key principles:**
  - Implement Cloud Financial Management.
  - Adopt a consumption model (pay only for what you use).
  - Measure overall efficiency.
  - Stop spending money on undifferentiated heavy lifting (use managed services).
  - Analyze and attribute expenditure.
- **Key services:** Cost Explorer, Budgets, Reserved Instances, Savings Plans, S3 Intelligent-Tiering, Trusted Advisor.

### 6. Sustainability

- **Goal:** Minimize the environmental impact of running workloads in the cloud.
- **Key principles:**
  - Understand the impact.
  - Establish sustainability goals.
  - Maximize utilization.
  - Anticipate and adopt new, more efficient hardware/software offerings.
  - Use managed services.
  - Reduce the downstream impact of cloud workloads.
- **Key services:** EC2 Auto Scaling (right-sizing), Graviton instances, S3 lifecycle policies, Lambda.

---

## Shared Responsibility Model

The shared responsibility model defines what AWS manages and what you manage as a customer. It is one of the **most frequently asked** concepts on the exam.

### General Rule

- **AWS is responsible for security "OF" the cloud** (infrastructure).
- **The customer is responsible for security "IN" the cloud** (data, configuration).

### Detailed Breakdown

| Layer | AWS manages | Customer manages |
|-------|-------------|------------------|
| **Physical infrastructure** | Data centers, hardware, global network, power, cooling | - |
| **Network infrastructure** | Physical network, switches, routers | Security Groups, NACLs, Route Tables configuration |
| **Virtualization** | Hypervisor, isolation between instances | - |
| **Operating System** | Host OS (hypervisor) | Guest OS (patches, updates on EC2) |
| **Applications** | Managed services (RDS engine, Lambda runtime) | Application code, application configuration |
| **Data** | Storage durability (S3 11 9s) | Data encryption, classification, backups, access permissions |
| **Identity** | IAM infrastructure | User management, MFA, policies, key rotation |

### Examples by Service

| Service | AWS Responsibility | Customer Responsibility |
|---------|-------------------|------------------------|
| **EC2** | Hardware, hypervisor, physical network | OS patches, firewall (SGs), IAM roles, data encryption |
| **RDS** | Hardware, OS, DB engine patches, automatic backups | Security Groups, IAM policies, data encryption, DB user management |
| **S3** | Infrastructure, durability, availability | Bucket policies, ACLs, encryption, versioning, lifecycle |
| **Lambda** | All infrastructure + runtime + patches | Function code, IAM roles, VPC configuration |

> **Exam tip:** The more "managed" the service, the more responsibilities AWS assumes. Lambda/Fargate = AWS manages almost everything. EC2 = you manage the OS and application.

---

## AWS Support Plans

| Feature | Basic | Developer | Business | Enterprise On-Ramp | Enterprise |
|---------|-------|-----------|----------|-------------------|------------|
| **Cost** | Free | From $29/month | From $100/month | From $5,500/month | From $15,000/month |
| **Trusted Advisor** | 7 basic checks | 7 basic checks | All checks | All checks | All checks |
| **Technical support** | No | 1 contact, business hours | Unlimited contacts, 24/7 | Unlimited contacts, 24/7 | Unlimited contacts, 24/7 |
| **General severity** | - | < 24 business hours | < 24h | < 24h | < 24h |
| **System impaired severity** | - | < 12 business hours | < 12h | < 12h | < 12h |
| **Production system impaired** | - | - | < 4h | < 4h | < 4h |
| **Production system down** | - | - | < 1h | < 1h | < 1h |
| **Business-critical system down** | - | - | - | < 30 min | < 15 min |
| **Technical Account Manager (TAM)** | No | No | No | Pool of TAMs | Designated TAM |
| **Concierge Support Team** | No | No | No | No | Yes |
| **Infrastructure Event Management** | No | No | Additional cost | 1 per year included | Included |
| **Well-Architected Reviews** | No | No | No | Yes | Yes |
| **AWS Support API** | No | No | Yes | Yes | Yes |

> **Exam tip:** If they ask about "TAM" or "Technical Account Manager", the answer is Enterprise. If they ask about "all Trusted Advisor checks", it's Business or higher.

---

## Pricing Fundamentals

### EC2 Purchase Models

| Model | Description | Discount vs On-Demand | Commitment | Ideal for |
|-------|-------------|----------------------|------------|-----------|
| **On-Demand** | Pay per hour or second with no commitment | 0% (base price) | None | Unpredictable workloads, development, testing |
| **Reserved Instances (RI)** | Capacity reservation for 1 or 3 years | Up to ~72% | 1 or 3 years | Stable, predictable workloads (databases) |
| **Savings Plans** | Spending commitment per hour in $/h | Up to ~72% | 1 or 3 years | Flexibility across types/regions/services |
| **Spot Instances** | AWS surplus capacity at the best price | Up to ~90% | None (can be interrupted) | Fault-tolerant workloads (batch, CI/CD, HPC) |
| **Dedicated Hosts** | Physical server exclusively dedicated | Varies | None or On-Demand or Reserved | BYOL licensing, compliance |
| **Dedicated Instances** | Instance on hardware dedicated to your account | Varies | None | Hardware-level isolation |
| **Capacity Reservations** | Capacity reservation in a specific AZ | 0% (you pay On-Demand) | None | Guaranteeing capacity for events |

### Types of Reserved Instances

| Type | Flexibility | Discount |
|------|------------|----------|
| **Standard RI** | Fixed instance type | Higher discount (up to ~72%) |
| **Convertible RI** | Can change instance type | Lower discount (up to ~54%) |

### Payment Options for RI

| Option | Description | Discount |
|--------|-------------|----------|
| **All Upfront** | Full upfront payment | Highest discount |
| **Partial Upfront** | Partial upfront payment + monthly | Medium discount |
| **No Upfront** | No upfront payment, monthly only | Lowest discount |

### Savings Plans - Types

| Type | Coverage | Flexibility |
|------|----------|-------------|
| **Compute Savings Plans** | EC2, Lambda, Fargate | Maximum flexibility (any region, family, OS, tenancy) |
| **EC2 Instance Savings Plans** | EC2 only | Fixed to instance family and region, flexible in OS/tenancy/size |
| **SageMaker Savings Plans** | SageMaker only | Flexible in instance type, region, and component |

### General AWS Pricing Principles

1. **Pay only for what you use** - No upfront costs (except RI upfront).
2. **Pay less when you use more** - Volume discounts (e.g., S3 storage tiers).
3. **Pay less when you reserve** - Long-term commitments get discounts.
4. **Data transfer** - Inbound is free. Outbound has cost (inter-region > inter-AZ > intra-AZ). Intra-AZ with private IP is free.

---

## Key Points for the Exam

### Cloud Fundamentals
- Know the 5 cloud computing attributes according to NIST.
- Differentiate IaaS, PaaS, and SaaS with concrete AWS service examples.
- Understand that hybrid cloud = on-premises + public cloud.

### Global Infrastructure
- Region > AZ > Data Center. Minimum 2 AZs per region.
- Edge Locations are for CloudFront and Route 53 (don't confuse with AZs).
- Local Zones = low latency to specific cities.
- Wavelength = ultra-low latency on 5G networks.

### Well-Architected Framework
- Memorize the 6 pillars and their key principles.
- Common questions about which pillar applies to a given scenario.
- Sustainability was the most recently added pillar (December 2021).

### Shared Responsibility Model
- "Security OF the cloud" (AWS) vs "Security IN the cloud" (customer).
- If the exam asks who patches the OS on an EC2 instance -> customer.
- If it asks who patches the database engine on RDS -> AWS.
- Data encryption is **always** the customer's responsibility (although AWS provides the tools).

### Support Plans
- TAM = Enterprise only.
- Full Trusted Advisor = Business or higher.
- 15-minute response for business-critical = Enterprise only.
- Concierge = Enterprise only.

### Pricing
- Spot can give up to 90% discount but can be interrupted with 2 minutes notice.
- Reserved Instances: 1 or 3 years, Standard doesn't change type, Convertible does.
- Savings Plans: more flexible than RI, commitment in $/hour.
- Data transfer between AZs has cost. Using private IP within the same AZ is free.
- Dedicated Hosts is required for BYOL (Bring Your Own License) licensing.
