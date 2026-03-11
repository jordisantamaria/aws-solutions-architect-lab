# Security - Quick Cheat Sheet

## IAM Policy Evaluation Logic

```
                         ┌───────────────────────┐
                         │  Is there an explicit  │
                         │  DENY?                 │
                         └───────┬───────────────┘
                                 │
                    ┌────────────┼────────────┐
                    │ YES                     │ NO
                    ▼                         ▼
            ┌──────────────┐      ┌─────────────────────┐
            │  DENIED      │      │ Is there an explicit │
            │  (always)    │      │  ALLOW?              │
            └──────────────┘      └───────┬─────────────┘
                                          │
                             ┌────────────┼────────────┐
                             │ YES                     │ NO
                             ▼                         ▼
                     ┌──────────────┐         ┌──────────────┐
                     │  ALLOWED     │         │  DENIED      │
                     │              │         │  (implicit)  │
                     └──────────────┘         └──────────────┘
```

### Full Evaluation Order

```
1. Explicit deny in any policy                → DENY (end)
2. Organizations SCP (if applicable)          → If no ALLOW → DENY
3. Resource-based policy                      → ALLOW? (can permit cross-account)
4. Identity-based policy                      → ALLOW?
5. Permissions boundary (if applicable)       → Limits the maximum
6. Session policy (if applicable)             → Limits the session
7. If nothing explicitly allows               → Implicit DENY
```

> **Exam key rules:**
> - **Explicit Deny ALWAYS wins** over any Allow.
> - **Everything is denied by default** (implicit deny) until explicitly allowed.
> - **SCP** does not grant permissions, it only limits the maximum (security guardrail).
> - **Permissions Boundary** limits the maximum permissions a user/role can have.
> - **Cross-account:** Needs permission on BOTH sides (resource policy + identity policy).

---

## Encryption At Rest vs In Transit

### Encryption at Rest

| Service | Encrypted by Default | Options |
|---------|---------------------|---------|
| **S3** | **Yes** (SSE-S3 since 2023) | SSE-S3, SSE-KMS, SSE-C, Client-Side |
| **EBS** | Optional (can be enforced per account) | AES-256 with KMS (aws/ebs or CMK) |
| **RDS** | Optional (at creation) | KMS. **Cannot be enabled after creation** — create snapshot, copy encrypted, restore |
| **Aurora** | Optional (at creation) | KMS. Same restriction as RDS |
| **DynamoDB** | **Yes** (always encrypted) | AWS owned key, AWS managed key (aws/dynamodb), or CMK |
| **EFS** | Optional (at creation) | KMS |
| **Redshift** | Optional | KMS or CloudHSM |
| **ElastiCache** | Optional | At-rest encryption with KMS |
| **Lambda** | **Yes** (environment variables) | KMS for environment variables |
| **SQS** | Optional | SSE with KMS |
| **Kinesis** | Optional | KMS server-side encryption |

### Encryption in Transit

| Method | Service/Use |
|--------|-------------|
| **TLS/SSL (HTTPS)** | All AWS API endpoints. ALB/NLB terminate SSL. ACM for certificates |
| **VPN IPSec** | Site-to-Site VPN — automatic encryption in tunnels |
| **VPN over Direct Connect** | DX does not encrypt by default; add IPSec VPN on top for encryption |
| **SSL on database** | Force SSL on RDS with `rds.force_ssl = 1` (PostgreSQL) or similar parameters |
| **Redis AUTH + TLS** | ElastiCache in-transit encryption |

> **Exam key:** "Encrypt data in transit over Direct Connect" → **VPN over DX** (DX alone does NOT encrypt).

---

## KMS vs CloudHSM vs Secrets Manager vs Parameter Store

| Feature | KMS | CloudHSM | Secrets Manager | Parameter Store |
|---------|-----|----------|-----------------|----------------|
| **Type** | Key management | Hardware Security Module | Secret management | Configuration store |
| **Management** | AWS manages hardware | **You manage** the HSM | AWS managed | AWS managed |
| **Model** | Shared tenancy | **Single-tenant** dedicated | N/A | N/A |
| **Keys** | Symmetric and asymmetric | Symmetric and asymmetric | N/A | N/A |
| **FIPS 140-2** | Level 2 | **Level 3** | Uses KMS internally | Uses KMS internally |
| **AWS Integration** | Native (S3, EBS, RDS, etc.) | Via KMS custom key store | Native automatic rotation | Manual / Lambda for rotation |
| **Rotation** | Automatic (annual) for CMKs | Manual | **Automatic** (configurable: days) | Lambda custom (not native) |
| **Cost** | $1/key/month + API calls | ~$1.50/hour/HSM | $0.40/secret/month + API | Free (standard) / $0.05 advanced |
| **Use case** | General encryption for AWS services | Strict compliance, full HSM control | DB credentials, API keys with rotation | App config, parameters, simple values |

> **Exam rules:**
> - "Encryption for AWS services" → **KMS**
> - "FIPS 140-2 **Level 3** compliance" or "dedicated HSM" → **CloudHSM**
> - "Automatically rotate database credentials" → **Secrets Manager**
> - "Store application configuration" → **Parameter Store** (more economical)
> - "Secret + automatic rotation" → **Secrets Manager** (not Parameter Store)

---

## WAF vs Shield vs Shield Advanced

| Feature | WAF | Shield Standard | Shield Advanced |
|---------|-----|----------------|-----------------|
| **Type** | Web Application Firewall | Basic DDoS protection | Advanced DDoS protection |
| **Layer** | Layer 7 (HTTP/HTTPS) | Layer 3/4 | Layer 3/4 **and** Layer 7 |
| **Cost** | Per rules and requests | **Free** (included) | $3,000/month + data |
| **Protection** | SQL injection, XSS, geo-blocking, rate limiting, IP block | SYN flood, UDP reflection, DNS amplification | Everything from Standard + sophisticated DDoS attacks |
| **Protected resources** | ALB, API Gateway, CloudFront, AppSync, Cognito | All AWS resources | CloudFront, ALB, NLB, Elastic IP, Global Accelerator |
| **Response Team** | No | No | **Yes** — AWS DDoS Response Team (DRT) 24/7 |
| **Cost protection** | No | No | **Yes** — credit for scaling caused by DDoS |
| **Visibility** | Logs, metrics | Basic metrics | Advanced metrics, real-time dashboards |

> **Exam rules:**
> - "Block SQL injection or XSS" → **WAF**
> - "Basic Layer 3/4 DDoS protection" → **Shield Standard** (free, always active)
> - "Advanced DDoS protection with response team" → **Shield Advanced**
> - "IP rate limiting" → **WAF** (rate-based rules)
> - "Geo-blocking (block countries)" → **WAF** or **CloudFront geo restriction**

---

## Cognito: User Pools vs Identity Pools

| Feature | Cognito User Pools | Cognito Identity Pools |
|---------|-------------------|----------------------|
| **Function** | **Authentication** (who you are) | **Authorization** (what you can do on AWS) |
| **Result** | JWT token (ID token, Access token) | **Temporary AWS credentials** (STS) |
| **Flow** | Sign-up, sign-in, MFA, password recovery | Federate identity → obtain temporary IAM role |
| **Providers** | Username/password, SAML, OIDC, social (Google, Facebook, Apple) | User Pools, SAML, OIDC, social, **unauthenticated identities** |
| **Use case** | Web/mobile app login, user management | Direct access to AWS services (S3, DynamoDB) from app |
| **Integration** | ALB, API Gateway, Lambda | IAM roles, S3, DynamoDB, any AWS service |

```
Typical combined flow:

  User ──→ Cognito User Pool ──→ JWT Token
                                        │
                                        ▼
                              Cognito Identity Pool ──→ AWS Credentials (IAM Role)
                                                              │
                                                              ▼
                                                    S3, DynamoDB, etc.
```

> **Exam key:**
> - "User authentication in the app" → **User Pool**
> - "Give temporary AWS service access to users" → **Identity Pool**
> - "Login with Google/Facebook in your app" → **User Pool** (as social provider)
> - "Access S3 from mobile app" → **Identity Pool** (temporary credentials)
> - ALB can integrate **User Pool** directly for authentication.

---

## AWS Security Services

| Service | Description (1 line) |
|---------|---------------------|
| **GuardDuty** | Intelligent threat detection analyzing CloudTrail, VPC Flow Logs, DNS logs, and S3 data events with ML |
| **Inspector** | Automated vulnerability assessment on **EC2, ECR images, and Lambda** — continuous CVE scanning |
| **Macie** | Discovery and protection of **sensitive data (PII)** in S3 using ML — detects exposed data |
| **Detective** | Investigation and analysis of the **root cause** of security findings — correlates data from GuardDuty, CloudTrail, VPC Flow Logs |
| **Security Hub** | Centralized security dashboard — aggregates findings from GuardDuty, Inspector, Macie, Firewall Manager, etc. |
| **CloudTrail** | Records **all API calls** in your AWS account — auditing, compliance, forensic investigation |
| **Config** | Evaluates the **configuration** of AWS resources against rules — detects compliance deviations |
| **Firewall Manager** | Centralized management of WAF, Shield Advanced, Security Groups, NACLs at the **AWS Organizations** level |
| **IAM Access Analyzer** | Identifies externally shared resources and validates IAM policies — detects unintended public access |
| **Audit Manager** | Automates evidence collection for compliance audits (SOC2, PCI-DSS, HIPAA, etc.) |

```
Typical security flow:

  CloudTrail (records APIs) ──→ GuardDuty (detects threats) ──→ Security Hub (centralizes)
                                                                        │
  Inspector (vulnerabilities)  ──→ Security Hub ◄────── Macie (sensitive data in S3)
                                         │
                                         ▼
                                 EventBridge ──→ SNS / Lambda (automatic remediation)
```

> **Exam rules:**
> - "Detect threats in the account" → **GuardDuty**
> - "Scan vulnerabilities in EC2/Lambda" → **Inspector**
> - "Find PII in S3" → **Macie**
> - "Investigate root cause of an incident" → **Detective**
> - "Centralize security findings" → **Security Hub**
> - "Audit API calls" → **CloudTrail**
> - "Evaluate configuration compliance" → **Config**

---

## Quick Decision Summary - Security

```
EXAM QUESTION                                        → ANSWER
────────────────────────────────────────────────────────────────────
"General AWS service encryption"                      → KMS
"Dedicated HSM / FIPS 140-2 Level 3"                  → CloudHSM
"Automatically rotate DB credentials"                 → Secrets Manager
"Store app config/parameters"                         → Parameter Store
"Block SQL injection / XSS"                           → WAF
"DDoS protection with response team"                  → Shield Advanced
"User login for web/mobile app"                       → Cognito User Pools
"Temporary S3 access from mobile app"                 → Cognito Identity Pools
"Detect threats with ML"                              → GuardDuty
"Find sensitive data in S3"                           → Macie
"Scan vulnerabilities in EC2"                         → Inspector
"Centralize security findings"                        → Security Hub
"Audit all API calls"                                 → CloudTrail
"Cross-account access"                                → IAM Role + Resource Policy
"Limit maximum permissions of a user"                 → Permissions Boundary
"Limit permissions of an entire account/OU"           → SCP (Organizations)
```
