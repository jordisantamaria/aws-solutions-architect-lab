# Practice Questions - AWS Solutions Architect Associate (SAA-C03)

## Exam Information

| Detail | Description |
|--------|-------------|
| **Exam code** | SAA-C03 |
| **Number of questions** | 65 questions (50 scored + 15 unscored) |
| **Duration** | 130 minutes |
| **Scoring** | 100 - 1,000 points |
| **Passing score** | **720 points** |
| **Format** | Multiple choice (1 answer) and multiple response (2+ answers) |
| **Languages** | English, Japanese, Korean, Simplified Chinese, and more |
| **Cost** | $150 USD |
| **Validity** | 3 years |

> **Note:** The 15 unscored questions are used to evaluate new questions for future exams. You cannot tell which ones they are, so answer all with the same effort.

---

## Exam Domains and Weights

| Domain | Weight | Approx. Questions |
|--------|--------|-------------------|
| **Domain 1:** Design Secure Architectures | **30%** | ~20 questions |
| **Domain 2:** Design Resilient Architectures | **26%** | ~17 questions |
| **Domain 3:** Design High-Performing Architectures | **24%** | ~16 questions |
| **Domain 4:** Design Cost-Optimized Architectures | **20%** | ~13 questions |

---

## Question Types

### 1. Single Answer
- A scenario is presented with **4 options** (A, B, C, D)
- Only **1 answer** is correct
- Most questions are of this type

### 2. Multiple Answer
- A scenario is presented with **5-6 options**
- You must select **2 or 3 correct answers** (indicated in the prompt)
- Example: "Select TWO answers that meet the requirement"
- You must get ALL correct options to earn the point

---

## Answering Strategy

### Before the Exam
1. **Read the official exam guide** (Exam Guide) from AWS
2. **Practice with mock exams** from reliable sources
3. **Review the cheat sheets** in this folder the night before
4. Get a good night's sleep

### During the Exam

#### Step 1: Read the Full Question
- Read **the last line first** (what they are actually asking for)
- Then read the full scenario
- Identify the **key keywords** that narrow down the options

#### Step 2: Look for Restrictive Keywords
The most common keywords and what they imply:

| Keyword | Meaning |
|---------|---------|
| **"Most cost-effective"** | The cheapest option that meets requirements |
| **"Least operational overhead"** | Managed/serverless services |
| **"Highest availability"** | Multi-AZ, multi-region, redundancy |
| **"Minimum downtime"** | Blue/green, rolling, automatic failover |
| **"Most secure"** | Principle of least privilege, encryption, private VPC |
| **"Fastest"** | Caching, CDN, read replicas, larger instance |
| **"Simplest / easiest"** | Least complexity, managed services |
| **"Durable"** | S3 (11 nines), Multi-AZ, backups |
| **"Decouple"** | SQS, SNS, EventBridge |
| **"Serverless"** | Lambda, Fargate, DynamoDB, S3, API Gateway |
| **"Real-time"** | Kinesis, WebSocket, ElastiCache |

#### Step 3: Eliminate Incorrect Options
- Eliminate options that **do not exist** in AWS or misuse services
- Eliminate options that **work but are unnecessarily complex**
- Eliminate options that **do not satisfy a key requirement** of the scenario

#### Step 4: Between Remaining Options
- If two options seem correct, the one with **fewer steps** is usually the answer
- AWS prefers **managed services** over custom solutions
- AWS prefers **serverless** when possible
- If they ask for "cost-effective", the simplest service usually wins

#### Step 5: Flag and Move On
- If you are unsure, flag the question and move on
- Return to flagged questions at the end
- **Do not leave questions unanswered** (there is no penalty)

---

## Common Mistakes to Avoid

1. **Not reading all options** — Sometimes option D is better than B
2. **Choosing the "most complete" option** — Sometimes less is more
3. **Ignoring scenario constraints** — "On-prem" or "existing Oracle DB" changes everything
4. **Confusing HA with DR** — Multi-AZ is HA, cross-region is DR
5. **Forgetting data transfer costs** — Cross-region and internet egress cost money
6. **Assuming everything is serverless** — Sometimes the question explicitly requires EC2
7. **Not considering limits** — Lambda has a 15 min limit, SQS FIFO has a 3,000 msg/s limit

---

## Practice Resources

### Official AWS Practice Exams
- **AWS Skill Builder** — Official practice exams (free and paid)
  - URL: [https://explore.skillbuilder.aws/learn/signin](https://explore.skillbuilder.aws/learn/signin)
  - Includes a free 20-question practice exam
  - Full official exam: $20 USD

### Other Recommended Resources
- **AWS Whitepapers** relevant to the exam:
  - Well-Architected Framework
  - Architecting for the Cloud: Best Practices
  - Disaster Recovery
  - Security Best Practices
- **AWS FAQs** for key services (S3, EC2, RDS, Lambda, VPC)
- **AWS re:Invent videos** on architecture

---

## Practice Question Structure

Each question in this folder follows the format:

```
## Question X

[Scenario based on a real-world case]

A) Option A
B) Option B
C) Option C
D) Option D

<details>
<summary>Show answer</summary>

**Answer: X**

[Detailed explanation of why it is correct and why the others are not]

**Key service/concept:** [Main AWS service]
</details>
```

---

## Question Files by Domain

| File | Domain | Questions |
|------|--------|-----------|
| [domain-1-secure-architectures.md](./domain-1-secure-architectures.md) | Design Secure Architectures | 15 questions |
| [domain-2-resilient-architectures.md](./domain-2-resilient-architectures.md) | Design Resilient Architectures | 15 questions |
| [domain-3-high-performing-architectures.md](./domain-3-high-performing-architectures.md) | Design High-Performing Architectures | 15 questions |
| [domain-4-cost-optimized-architectures.md](./domain-4-cost-optimized-architectures.md) | Design Cost-Optimized Architectures | 15 questions |

**Total: 60 practice questions**

> **Tip:** Try to answer each question BEFORE viewing the answer. Flag the ones you get wrong and review them again in a few days.
