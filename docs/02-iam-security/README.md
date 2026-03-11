# IAM and Security in AWS

## Table of Contents

- [IAM Fundamentals](#iam-fundamentals)
- [Types of IAM Policies](#types-of-iam-policies)
- [Policy Evaluation Logic](#policy-evaluation-logic)
- [IAM Best Practices](#iam-best-practices)
- [AWS Organizations](#aws-organizations)
- [AWS Control Tower](#aws-control-tower)
- [AWS RAM (Resource Access Manager)](#aws-ram-resource-access-manager)
- [STS and AssumeRole](#sts-and-assumerole)
- [AWS IAM Identity Center (SSO)](#aws-iam-identity-center-sso)
- [AWS KMS](#aws-kms)
- [Secrets Manager vs Parameter Store](#secrets-manager-vs-parameter-store)
- [AWS CloudHSM](#aws-cloudhsm)
- [AWS WAF, Shield and Shield Advanced](#aws-waf-shield-and-shield-advanced)
- [Amazon Cognito](#amazon-cognito)
- [AWS Directory Service (Active Directory)](#aws-directory-service-active-directory)
- [Detection and Security Services](#detection-and-security-services)
- [AWS Certificate Manager (ACM)](#aws-certificate-manager-acm)
- [Security Exam Tips](#security-exam-tips)

---

## IAM Fundamentals

IAM (Identity and Access Management) is a **global** (not regional) service that controls who can do what in your AWS account.

### Main Components

#### Users

- Represent a person or application that interacts with AWS.
- Can have console credentials (username/password) and/or programmatic access credentials (Access Key ID + Secret Access Key).
- A new user has **no permissions** by default (implicit deny).
- Limit: 5,000 IAM users per account.

#### Groups

- Collection of IAM users.
- Allow assigning policies to multiple users at once.
- A user can belong to **multiple groups** (maximum 10).
- Groups **cannot contain other groups** (no nesting).
- There is no "default group" that includes all users.
- Groups **are not identities** (you cannot reference a group in a resource-based policy as a principal).

#### Roles

- IAM identity with permissions, but **without long-term credentials**.
- Temporarily "assumed" by users, applications, or AWS services.
- Main use cases:
  - **EC2 Instance Role**: Grant permissions to an EC2 instance to access other services.
  - **Cross-account access**: Allow an external account to access resources in your account.
  - **Service Role**: Allow an AWS service (Lambda, ECS) to access other resources.
  - **Federation**: External users (AD, SAML, OIDC) who assume a role.

#### Policies

- JSON documents that define permissions.
- Structure of a policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowS3Read",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::my-bucket",
        "arn:aws:s3:::my-bucket/*"
      ],
      "Condition": {
        "IpAddress": {
          "aws:SourceIp": "192.168.1.0/24"
        }
      }
    }
  ]
}
```

- **Version**: Always use `"2012-10-17"` (current version).
- **Effect**: `Allow` or `Deny`.
- **Action**: The API actions allowed or denied.
- **Resource**: The affected resources (ARN).
- **Condition** (optional): Conditions that must be met.

---

## Types of IAM Policies

| Policy Type | Attached to | Description | Example |
|-------------|-------------|-------------|---------|
| **Identity-based** | Users, Groups, Roles | Defines what the identity can do | Policy allowing S3 read attached to a role |
| **Resource-based** | Resources (S3, SQS, KMS, etc.) | Defines who can access the resource | S3 bucket policy, KMS key policy |
| **Permission Boundary** | Users, Roles | Maximum permissions limit that an identity can have | Limit a developer to only us-east-1 services |
| **SCP (Service Control Policy)** | AWS Organization (OU or account) | Maximum permissions limit for the entire account/OU | Prohibit creating resources outside EU |
| **Session Policy** | STS sessions | Limits permissions of a temporary AssumeRole session | Restrict access during a federated session |
| **ACL (Access Control List)** | Resources (S3, VPC) | Cross-account access control without JSON policy format | S3 ACL (legacy, not recommended) |

### Identity-based Policies: Managed vs Inline

| Type | Description | Recommendation |
|------|-------------|----------------|
| **AWS Managed** | Created and maintained by AWS | Use for common permissions (ReadOnlyAccess, etc.) |
| **Customer Managed** | Created by you, reusable | Recommended for custom policies |
| **Inline** | Embedded directly in a user, group, or role | Only for strict 1:1 relationships, not generally recommended |

### Permission Boundaries

- Do not grant permissions on their own; they only **limit** the maximum permissions.
- Effective permissions are the **intersection** between the identity-based policy and the permission boundary.
- Use case: Allow developers to create IAM roles while ensuring they can never exceed certain permissions.
- Only apply to users and roles (not groups).

---

## Policy Evaluation Logic

The order of policy evaluation in AWS follows this logic:

```
1. Explicit Deny in any policy  -->  DENY (always wins)
        |
        v (if no explicit deny)
2. SCP allows the action?  -->  if NO --> DENY
        |
        v (if SCP allows)
3. Resource-based policy allows (with Principal)?  -->  if YES --> ALLOW
        |
        v (if no resource-based or doesn't apply)
4. Permission Boundary allows?  -->  if NO --> DENY
        |
        v (if Permission Boundary allows)
5. Session Policy allows?  -->  if NO --> DENY
        |
        v (if Session Policy allows)
6. Identity-based policy allows?  -->  if YES --> ALLOW
        |
        v (if no policy allows)
7. Implicit DENY (default)
```

### Golden Rule

> **Explicit Deny > Explicit Allow > Implicit Deny (default)**

### Cross-account Evaluation

When a principal from Account A attempts to access a resource in Account B:
- Account A must have an **identity-based policy** that allows the action.
- Account B must have a **resource-based policy** that allows the principal from Account A.
- **Both** must allow; whichever denies prevails.

> **Exception:** If the resource in Account B has a resource-based policy that specifies the principal from Account A directly, and it's same-account (not cross-account), no identity-based policy is needed.

---

## IAM Best Practices

1. **Do not use the root account** for daily tasks. Protect it with hardware MFA.
2. **Create individual IAM users** - Do not share credentials.
3. **Use groups** to assign permissions.
4. **Principle of Least Privilege** - Grant only the necessary permissions.
5. **Enable MFA** for all users, especially privileged ones.
6. **Use roles** instead of access keys for applications on EC2/Lambda/ECS.
7. **Rotate credentials** regularly (access keys).
8. **Use strong password policies** (minimum length, complexity, rotation).
9. **Use IAM Access Analyzer** to identify externally shared resources.
10. **Monitor with CloudTrail** all IAM actions.
11. **Never embed access keys** in code. Use roles or Secrets Manager.
12. **Use Permission Boundaries** to delegate IAM management securely.

---

## AWS Organizations

AWS Organizations allows you to centrally manage multiple AWS accounts.

### Key Concepts

- **Management Account** (formerly "Master Account"): The root account of the organization. SCPs do not apply to it.
- **Member Accounts**: The accounts that belong to the organization.
- **Organizational Units (OUs)**: Logical groupings of accounts (can be nested).
- **Root**: The top container of the organization (contains all OUs and accounts).

### Service Control Policies (SCPs)

- Define the **maximum permissions** available for accounts in an OU or individual account.
- **Do not grant permissions**, they only restrict them.
- Do not apply to the Management Account.
- Apply to **all users and roles** in the account (including the account root user).
- Do not apply to service-linked roles.
- Must have an explicit `Allow` (by default, when using "deny list strategy", the `FullAWSAccess` SCP is attached).

### SCP Strategies

| Strategy | Description | Use |
|----------|-------------|-----|
| **Deny List** (default) | `FullAWSAccess` attached + explicit deny SCPs | Block specific services/actions |
| **Allow List** | Remove `FullAWSAccess` + explicit allow SCPs | Only allow specific services (more restrictive) |

### Consolidated Billing

- A single bill for all accounts in the organization.
- **Volume discounts** are aggregated across accounts (e.g., S3, EC2).
- **Reserved Instances** are shared across organization accounts (unless disabled).
- Allows tracking costs per individual account with AWS Cost Explorer.

---

## AWS Control Tower

Service for setting up and governing a **secure multi-account environment** based on best practices. Built on top of AWS Organizations.

### What Problem It Solves

Setting up a multi-account environment manually requires: creating accounts, configuring SSO, applying SCPs, setting up centralized logging, etc. **Control Tower automates all of this**.

### Main Components

| Component | Description |
|-----------|-------------|
| **Landing Zone** | Pre-configured multi-account environment with best practices. Includes logging, audit accounts, and OU structure |
| **Account Factory** | Automated provisioning of new AWS accounts with standardized configuration. Uses AWS Service Catalog under the hood |
| **Guardrails (Controls)** | Governance rules applied to OUs. Can be preventive (SCP) or detective (AWS Config Rules) |
| **Dashboard** | Centralized view of compliance status for all accounts and guardrails |

### Types of Guardrails

| Type | Mechanism | Example |
|------|-----------|---------|
| **Preventive** | SCP (Service Control Policy) | "Do not allow deleting CloudTrail logs" |
| **Detective** | AWS Config Rules | "Detect if an S3 bucket is public" |
| **Proactive** | CloudFormation Hooks | "Block deployment of non-compliant resources before creating them" |

### Guardrail Levels

| Level | Description |
|-------|-------------|
| **Mandatory** | Always enabled. Cannot be deactivated (e.g., prohibit changes to the logging account) |
| **Strongly Recommended** | Based on AWS best practices (e.g., enable EBS encryption) |
| **Elective** | Optional, for specific company requirements |

### Landing Zone Structure

```
Management Account (root)
├── Security OU
│   ├── Log Archive Account      → Stores CloudTrail and Config logs from ALL accounts
│   └── Audit Account            → Cross-account access for auditing and compliance
├── Sandbox OU
│   └── Dev accounts             → For experimentation with relaxed guardrails
├── Production OU
│   └── Prod accounts            → Strict guardrails
└── Guardrails applied per OU
```

### Control Tower Drift Detection

**Drift** occurs when resources managed by Control Tower are modified outside its control (manually or by other services), deviating from the expected state.

**Types of drift detected:**
- Changes to SCPs managed by Control Tower.
- Changes to account configuration (CloudTrail disabled, Config disabled).
- Accounts moved between OUs manually.
- Changes to mandatory guardrails.

**Drift notifications:**
- Control Tower detects drift automatically and sends notifications via **SNS** to the admin.
- Can be integrated with **EventBridge** to automate remediation.
- Drift appears in the **Control Tower Dashboard** with the status of affected accounts and guardrails.
- To resolve it, you can use **Re-register OU** or correct manually and then **Update Landing Zone**.

> **Exam tip:** If the question mentions "detect unauthorized changes in Control Tower accounts" or "notify when a managed SCP is modified" -> **Control Tower drift detection**. Notifications go via SNS and appear in the dashboard.

### Control Tower vs Organizations

| Feature | Organizations (only) | Control Tower |
|---------|---------------------|---------------|
| **Create accounts** | Manual or API | Account Factory (automated, standardized) |
| **Guardrails** | Manual SCPs | Predefined guardrails (preventive + detective) |
| **Centralized logging** | Configure manually | Pre-configured (Log Archive Account) |
| **Compliance dashboard** | No | Yes |
| **Automatic best practices** | No | Yes (Landing Zone) |

> **Exam tip:** If the question mentions "set up multi-account environment with best practices", "landing zone", "automated multi-account governance", "Account Factory" -> **Control Tower**. If you only need to group accounts and apply SCPs manually -> **Organizations**. Control Tower uses Organizations under the hood.

---

## AWS RAM (Resource Access Manager)

Service for **sharing AWS resources between accounts** securely, without needing to create duplicates.

### Resources That Can Be Shared

| Resource | Use Case |
|----------|----------|
| **VPC Subnets** | Different accounts launch resources in shared subnets of a central VPC |
| **Transit Gateway** | Share a Transit Gateway between accounts without each one creating their own |
| **Route 53 Resolver Rules** | Share DNS resolution rules |
| **License Manager** | Share license configurations |
| **Aurora DB Cluster** | Share an Aurora cluster between accounts |
| **AWS CodeBuild Projects** | Share build projects |
| **EC2 (Dedicated Hosts, Capacity Reservations)** | Share dedicated hosts |

### Most Common Use Case: VPC Subnet Sharing

```
Account A (Network Account): Creates the VPC and subnets
    │
    ├── Shares subnet-private-1 via RAM → Account B
    ├── Shares subnet-private-2 via RAM → Account C
    │
    ▼
Account B: Launches EC2/RDS/Lambda in subnet-private-1 (from Account A's VPC)
Account C: Launches EC2/RDS/Lambda in subnet-private-2 (from Account A's VPC)
```

- Resources from each account are **isolated** (each account manages its own security groups, instances, etc.).
- The VPC and subnets are **managed only by the owner account**.
- Reduces the complexity of VPC peering between many accounts.

### RAM with AWS Organizations

- If accounts are in the same Organization, RAM can share automatically without invitations.
- If they are not in the same Organization, an invitation is sent that the other account must accept.

### RAM vs Other Alternatives

| Need | Solution |
|------|---------|
| "Share a subnet between accounts" | **RAM** |
| "Share a Transit Gateway between accounts" | **RAM** |
| "Access resources from another account via API" | **STS AssumeRole (cross-account)** |
| "Share an S3 bucket with another account" | **S3 Bucket Policy** (no need for RAM) |
| "Share an AMI with another account" | **AMI Sharing** (no need for RAM) |

> **Exam tip:** If the question mentions "share VPC subnets between accounts", "share Transit Gateway between accounts", "share resources between Organization accounts" -> **RAM**. Don't confuse with cross-account IAM roles (STS AssumeRole), which is for accessing APIs, not for sharing network resources.

---

## STS and AssumeRole

AWS Security Token Service (STS) is a global service that allows obtaining **temporary credentials** with limited privileges.

### Main STS Operations

| Operation | Description | Use Case |
|-----------|-------------|----------|
| **AssumeRole** | Assume an IAM role (same or different account) | Cross-account access, service roles |
| **AssumeRoleWithSAML** | Assume role with SAML 2.0 authentication | Federation with Active Directory / corporate IdP |
| **AssumeRoleWithWebIdentity** | Assume role with web IdP token (Google, Facebook, Amazon) | Mobile apps (although Cognito is recommended) |
| **GetSessionToken** | Get temporary credentials for IAM user | Programmatic access with MFA |
| **GetFederationToken** | Temporary credentials for a federated user | Custom federation proxy |

### Cross-Account Access with AssumeRole

**Scenario**: A user from Account A needs to access an S3 bucket in Account B.

1. **Account B**: Create an IAM role with a **trust policy** that allows Account A to assume the role.
2. **Account B**: The role has a **permission policy** that allows access to the S3 bucket.
3. **Account A**: The user has a policy that allows executing `sts:AssumeRole` on the ARN of Account B's role.
4. The user calls `sts:AssumeRole` and receives temporary credentials.
5. Uses those credentials to access the S3 bucket in Account B.

### Temporary Credentials

- Include: Access Key ID, Secret Access Key, and **Session Token**.
- Configurable duration (15 minutes to 12 hours depending on the case).
- Cannot be individually revoked, but the role can have its policy modified.

### Federation + IAM Policy Variables (per-user S3 access)

Typical exam scenario: 1000+ employees of a company with corporate AD need access each to their own folder in S3, with SSO.

**Don't create 1000 IAM users.** Use federation + a single IAM Role with policy variables:

```
Employee ──► Corporate AD (SSO)
                 │
                 ▼
         Federation proxy / IdP (SAML 2.0)
                 │
                 ▼
         STS: AssumeRoleWithSAML → temporary credentials
                 │
                 ▼
         IAM Role with policy variable → access only to their folder in S3
```

**The policy uses `${aws:userid}` which is automatically replaced** by the federated user's identity:

```json
{
  "Effect": "Allow",
  "Action": ["s3:GetObject", "s3:PutObject"],
  "Resource": "arn:aws:s3:::company-docs/${aws:userid}/*"
}
```

When John authenticates, `${aws:userid}` resolves to `john` -> can only access `s3://company-docs/john/*`. Mary sees only `mary/*`. **One Role, one policy, thousands of users.**

**Available policy variables:**

| Variable | Replaced by | Example |
|---|---|---|
| `${aws:userid}` | User ID (or role-id:session-name in federation) | `AROA12345:john` |
| `${aws:username}` | IAM user name | `john` |
| `${aws:PrincipalTag/department}` | Federated session tag | `engineering` |
| `${s3:prefix}` | Requested prefix in the S3 operation | `home/john/` |

> **Exam tip:** If the question says "thousands of corporate users + SSO + individual S3 folder" -> **Federation (SAML/IdP) + STS + IAM Role with policy variables**. Never create one IAM user per employee.

---

## AWS IAM Identity Center (SSO)

Formerly called **AWS Single Sign-On (SSO)**, it is the recommended service for managing people's access to multiple AWS accounts and business applications.

### Features

- **Single access point** for all organization accounts and SAML 2.0 apps.
- Integrates with **AWS Organizations** for centralized management.
- Supported **Identity Sources**:
  - Identity Center directory (built-in).
  - Active Directory (AWS Managed AD or AD Connector).
  - External SAML 2.0 providers (Okta, Azure AD, etc.).
- **Permission Sets**: Collections of policies that define access to an AWS account.
- Provides a **web portal** where users see all available accounts and roles.

### Access Flow

1. User accesses the IAM Identity Center portal.
2. Authenticates against the configured Identity Source.
3. Sees the assigned AWS accounts and Permission Sets.
4. Selects account + Permission Set and gets temporary STS credentials.

> **Exam tip:** If they ask how to give centralized access to multiple AWS accounts to corporate employees, the answer is **IAM Identity Center**.

---

## AWS KMS

AWS Key Management Service (KMS) is a managed service for creating and controlling encryption keys used to protect your data.

### Key Types

| Type | Description | Rotation | Cost |
|------|-------------|----------|------|
| **AWS Owned Keys** | AWS manages them internally (SSE-S3) | Automatic (varies) | Free |
| **AWS Managed Keys** | AWS creates and manages them for you (aws/service-name) | Automatic every ~1 year | Free (but charges for usage) |
| **Customer Managed Keys (CMK)** | You create, manage, and control them | Automatic (optional, every ~1 year) or manual | $1/month + $0.03 per 10,000 requests |

### Envelope Encryption

KMS can encrypt data up to **4 KB** directly. For larger data, **envelope encryption** is used:

1. Call the KMS `GenerateDataKey` API.
2. KMS returns a **plaintext Data Key** + an **encrypted copy** of the Data Key.
3. Use the plaintext Data Key to encrypt your data (client-side).
4. Store the encrypted Data Key alongside the encrypted data.
5. Discard the plaintext Data Key from memory.
6. To decrypt: send the encrypted Data Key to KMS (`Decrypt`), receive the plaintext Data Key, and decrypt the data.

> **Why envelope encryption?** Avoids sending large volumes of data to KMS (4 KB limit). You only send the key, not the data.

### Key Policies

- Every CMK **must** have a key policy (there is no global default).
- The **default key policy** allows the account root (and thus IAM users with permissions) to manage the key.
- You can create **custom key policies** to define who can administer and who can use the key.
- Combined with IAM policies to control key access.

### Key Rotation

| Key Type | Automatic Rotation | Period |
|----------|-------------------|--------|
| AWS Managed Key | Mandatory | Every ~1 year |
| Customer Managed Key (symmetric) | Optional (manually enabled) | Every ~1 year |
| Customer Managed Key (asymmetric) | Not supported | Manual |
| Imported Key Material | Not supported | Manual |

- When automatically rotated, KMS keeps old versions of the key to decrypt previous data.
- The Key ID does not change during automatic rotation.
- Manual rotation creates a new key and requires updating aliases.

### Multi-Region Keys

- Replicas of a KMS key in multiple regions.
- Same key material in all replicas.
- Data encrypted in one region can be decrypted in another.
- Use case: client-side encryption of data replicated between regions (DynamoDB Global Tables, Aurora Global).

---

## Secrets Manager vs Parameter Store

| Feature | AWS Secrets Manager | AWS Systems Manager Parameter Store |
|---------|--------------------|------------------------------------|
| **Primary purpose** | Secrets management (DB credentials, API keys) | Configuration and secrets store |
| **Automatic rotation** | Yes (native integration with Lambda for RDS, Redshift, DocumentDB) | No (you can implement it yourself with Lambda + EventBridge) |
| **Encryption** | Always encrypted with KMS | Optional (SecureString uses KMS) |
| **Versioning** | Yes | Yes |
| **Cross-account access** | Yes (via resource-based policy) | Not directly (needs additional layer) |
| **Data types** | Text/binary | String, StringList, SecureString |
| **Hierarchy** | No | Yes (paths: /dev/db/password) |
| **Cost** | $0.40 per secret/month + $0.05 per 10,000 API calls | Free (Standard) or $0.05 per advanced parameter/month |
| **Maximum size** | 64 KB | 4 KB (Standard) or 8 KB (Advanced) |
| **Throughput** | High (no practical limit) | Standard: 40 TPS / Advanced: up to 10,000 TPS |
| **CloudFormation integration** | Yes (dynamic reference) | Yes (dynamic reference) |

> **Exam tip:** If the question mentions **automatic rotation of database credentials**, the answer is **Secrets Manager**. If it's just configuration storage, Parameter Store is more cost-effective.

---

## AWS CloudHSM

CloudHSM provides dedicated hardware security modules (HSM) in the AWS cloud.

### CloudHSM vs KMS

| Feature | KMS | CloudHSM |
|---------|-----|----------|
| **HSM type** | Multi-tenant (shared) | Single-tenant (dedicated) |
| **Key management** | AWS manages the hardware and software | You manage the keys; AWS manages the hardware |
| **Cryptographic standard** | FIPS 140-2 Level 2 (some Level 3) | FIPS 140-2 Level 3 |
| **Availability** | Highly available by default | You must deploy in multiple AZs manually |
| **AWS integration** | Native integration with almost all services | Limited integration; works as custom key store for KMS |
| **Price** | Pay per use | ~$1.50/hour per HSM (minimum 2 for HA) |
| **Access** | Via KMS API | You control the keys; AWS cannot access |
| **Algorithms** | Symmetric and asymmetric | Symmetric, asymmetric, and hashing |
| **Use cases** | General encryption, AWS service integration | Strict regulatory compliance (FIPS 140-2 L3), SSL/TLS offloading, PKI |

### Custom Key Store (KMS + CloudHSM)

A custom key store connects KMS with your CloudHSM cluster. You get the **best of both worlds**:

- **From KMS**: native integration with AWS services (S3, EBS, RDS, etc.).
- **From CloudHSM**: full control over the hardware where the key material resides.

```
Without custom key store:                 With custom key store:
App → KMS → AWS shared HSM               App → KMS → Your dedicated CloudHSM
(easy but no full control)                (easy + full control)
```

**Exclusive custom key store capabilities:**
- **Immediately delete key material** from AWS (impossible with normal KMS keys, which have a 7-30 day waiting period).
- **Audit key usage in CloudHSM logs**, independently of CloudTrail.
- Key material is **non-extractable**: it never leaves the HSM in plaintext.

### Types of KMS Keys (for the exam)

| Type | Who controls it | Rotation | Can you delete it | Example |
|---|---|---|---|---|
| **AWS Owned Key** | AWS completely | AWS decides | No | Default S3 encryption (SSE-S3) |
| **AWS Managed Key** | AWS manages it, you use it | Automatic (~1 year) | No | `aws/s3`, `aws/ebs`, `aws/rds` |
| **Customer Managed Key** | You control it | Optional | Yes (7-30 day wait) | Keys you create in KMS |
| **Customer Managed Key in Custom Key Store** | You control it + HSM control | Optional | Yes (immediate, deleting from HSM) | KMS keys backed by CloudHSM |

> **Exam tip:**
> - **FIPS 140-2 Level 3** or **single-tenant HSM** or **full key control** -> **CloudHSM**.
> - **Easy integration with AWS services + full control + immediately delete material** -> **KMS with custom key store (CloudHSM)**.
> - **Audit key usage independently of CloudTrail** -> **Custom key store** (CloudHSM logs are independent).

---

## AWS WAF, Shield and Shield Advanced

### AWS WAF (Web Application Firewall)

- Protects web applications against common web exploits (Layer 7).
- Deployed on: **ALB, API Gateway, CloudFront, AppSync, Cognito User Pool**.
- Defines **Web ACLs** with rules that allow, block, or count requests.
- Can filter based on:
  - **IP addresses** (IP sets).
  - **Country of origin** (geo-match).
  - **Request size**.
  - **Strings/regex** in headers, body, URI.
  - **SQL injection** and **Cross-Site Scripting (XSS)** detection.
  - **Rate-based rules** for application-level DDoS protection.
- **AWS Managed Rules**: Pre-configured rule sets maintained by AWS or marketplace.

### AWS Shield

| Feature | Shield Standard | Shield Advanced |
|---------|----------------|-----------------|
| **Cost** | Free (automatically included) | $3,000/month per organization + usage costs |
| **Protection** | Common Layer 3/4 DDoS attacks | Sophisticated Layer 3/4/7 DDoS attacks |
| **Protects** | All AWS resources automatically | EC2, ELB, CloudFront, Global Accelerator, Route 53 |
| **Visibility** | Basic | Real-time diagnostics, detailed metrics |
| **DDoS Response Team (DRT)** | No | Yes, 24/7 |
| **Cost protection** | No | Yes (credits for involuntary DDoS scaling) |
| **WAF included** | No | Yes (WAF at no additional cost for protected resources) |

### Typical Protection Architecture

```
Internet -> CloudFront (Shield + WAF) -> ALB (Shield + WAF) -> EC2 (Security Groups)
```

---

## Amazon Cognito

Amazon Cognito provides authentication, authorization, and user management for web and mobile applications.

### User Pools vs Identity Pools

| Feature | Cognito User Pools | Cognito Identity Pools |
|---------|-------------------|----------------------|
| **Purpose** | Authentication (sign-up, sign-in) | Authorization (access to AWS services) |
| **Output** | JSON Web Tokens (JWT) | Temporary AWS credentials (STS) |
| **Functionality** | User directory, social login, MFA, password recovery | Federate identities and map them to IAM roles |
| **Identity providers** | Local users, Google, Facebook, Apple, SAML, OIDC | Cognito User Pools, Google, Facebook, SAML, OIDC, custom |
| **Use case** | Login for your web/mobile application | Give direct access to AWS services (S3, DynamoDB) from the client |
| **ALB integration** | Yes (authentication on ALB) | Not directly |
| **Guest access** | No | Yes (unauthenticated users can have a limited IAM role) |

### Typical Combined Flow

1. The user authenticates with the **User Pool** and receives a **JWT token**.
2. The JWT is exchanged with the **Identity Pool** for **temporary AWS credentials**.
3. With those credentials, the client accesses AWS services directly (S3, API Gateway, etc.).

> **Exam tip:** User Pools = authentication (who you are). Identity Pools = authorization (what you can do in AWS). Many questions try to confuse you between the two.

---

## AWS Directory Service (Active Directory)

### What is Active Directory

**Active Directory (AD)** is Microsoft's system for managing identities in an organization. It's the "employee database" that controls authentication (who you are) and authorization (what you have access to) in Windows environments.

```
Active Directory (typical on-premises)
├── Users: john@company.com, mary@company.com
├── Groups: Engineering, HR, Finance
├── Permissions: Engineering → access to \\server\code
│                HR → access to \\server\payroll
└── Policies: Password minimum 12 characters, lockout after 3 attempts
```

When an employee logs into their Windows PC, the PC queries AD: "does this user exist and is the password correct?". Once authenticated, AD determines which shared folders, applications, and printers the user has access to.

### AWS Directory Service

Companies migrating to AWS don't want to recreate thousands of users in IAM. AWS Directory Service offers three ways to use Active Directory in the cloud:

| Type | What it is | AD on-premises? | Use Case |
|---|---|---|---|
| **AWS Managed Microsoft AD** | Full AD managed by AWS. Supports bidirectional trust with on-premises AD | Optional (works standalone or connected) | FSx for Windows, RDS SQL Server, WorkSpaces, SSO, hybrid environments |
| **AD Connector** | Proxy that redirects all requests to on-premises AD. Does not store data in AWS | **Required** (without on-premises AD it doesn't work) | Companies that want to use their existing AD without replicating data in AWS |
| **Simple AD** | Basic standalone AD based on Samba. No connection to on-premises AD | Not supported | Small companies without existing AD that need basic AD functionality |

```
AWS Managed Microsoft AD:
  AWS Users  ──►  AWS Managed AD  ◄──  trust  ──►  AD on-premises
                  (full AD)                        (corporate users)
                  Users from both sides see each other

AD Connector:
  AWS Users  ──►  AD Connector  ──────────────────►  AD on-premises
                  (proxy only)                        (everything lives here)

Simple AD:
  AWS Users  ──►  Simple AD
                  (standalone, basic)
```

### Integration with AWS Services

| Service | How it uses AD |
|---|---|
| **FSx for Windows File Server** | "Joins" the AD domain. Users access with their corporate credentials |
| **RDS for SQL Server** | Windows integrated authentication via Managed AD |
| **Amazon WorkSpaces** | Virtual desktops with corporate AD login |
| **IAM Identity Center (SSO)** | Single sign-on with AD credentials for the AWS console and apps |
| **Amazon EC2 Windows** | Instances can join the AD domain |

> **Exam tip:**
> - "SharePoint / Windows file share + Active Directory in AWS" -> **FSx for Windows File Server + AWS Managed Microsoft AD** (not EFS, which is Linux only).
> - "Use existing on-premises AD without storing directory data in AWS" -> **AD Connector**.
> - "Cloud-managed AD with trust to on-premises" -> **AWS Managed Microsoft AD**.
> - "Basic AD without on-premises connection, low budget" -> **Simple AD**.

---

## Detection and Security Services

### Amazon GuardDuty

- **Intelligent threat detection** using ML, anomalies, and threat intelligence.
- Analyzes: **VPC Flow Logs, CloudTrail Logs, DNS Logs, EKS Audit Logs, S3 Data Events**.
- You don't need to enable Flow Logs or CloudTrail manually; GuardDuty analyzes them independently.
- Generates **findings** classified by severity.
- Can trigger notifications via **EventBridge** and remediate automatically with Lambda.
- **Delegated Administrator**: In Organizations, a member account can administer GuardDuty for the entire organization.

### Amazon Inspector

- **Automatic vulnerability assessment** in:
  - **EC2 instances**: Network and OS vulnerabilities (requires SSM Agent).
  - **Container images in ECR**: Vulnerabilities in Docker images.
  - **Lambda functions**: Vulnerabilities in code and dependencies.
- Generates a **risk score** to prioritize remediations.
- Runs automatically when changes are detected (new deploy, new CVE published).

### Amazon Macie

- Uses ML and pattern matching to **discover and protect sensitive data in S3**.
- Detects: PII (Personally Identifiable Information), financial data, credentials, etc.
- Generates **findings** when sensitive information is detected.
- Integrates with EventBridge to automate remediations.

### Amazon Detective

- **Investigates and analyzes** the root cause of security findings.
- Ingests data from **GuardDuty, VPC Flow Logs, CloudTrail, EKS**.
- Creates **graphical visualizations** to understand relationships between resources and activities.
- Does not detect threats (that's what GuardDuty does); it only helps **investigate them**.

### Security Services Summary

| Service | Primary Function |
|---------|-----------------|
| **GuardDuty** | Threat detection (ML + threat intelligence) |
| **Inspector** | Vulnerability assessment (EC2, ECR, Lambda) |
| **Macie** | Sensitive data discovery in S3 |
| **Detective** | Root cause investigation of security findings |
| **Security Hub** | Centralized panel that aggregates findings from all the above |

---

## AWS Certificate Manager (ACM)

- Service for **provisioning, managing, and deploying SSL/TLS certificates** both public and private.
- Public certificates issued by ACM are **free**.
- **Automatic renewal** of certificates issued by ACM.
- Integrates with: **ELB (ALB/NLB), CloudFront, API Gateway, Elastic Beanstalk**.
- **Cannot be used directly with EC2** (you must configure SSL/TLS manually on the instance).
- ACM certificates are **regional**. To use them with CloudFront, they must be in **us-east-1**.
- You can import external certificates (but you lose automatic renewal).

> **Exam tip:** If you need SSL/TLS for ALB or CloudFront, use ACM (free and automatic renewal). If the question says "certificate in us-east-1 for CloudFront", that's normal ACM behavior.

---

## Security Exam Tips

### IAM

- **IAM policies** are evaluated as: Explicit Deny > Explicit Allow > Implicit Deny.
- The **root** account cannot be restricted by IAM policies, but it can be by **SCPs** from Organizations (except the Management Account).
- **Access keys** are for programmatic access; username/password for the console.
- **Roles** are the recommended way to grant permissions to AWS services (not access keys).
- **Permission Boundaries** limit the maximum permissions, they do not grant permissions.
- **"Thousands of corporate users + SSO + per-user S3 folder"** -> Federation + STS + IAM Role with policy variables (`${aws:userid}`). Never create one IAM user per employee.

### Organizations and SCPs

- SCPs do not apply to the **Management Account**.
- SCPs do not apply to **service-linked roles**.
- SCPs affect **all users and roles** in the account, including the member account root user.

### Control Tower

- **"Set up multi-account environment with best practices"** -> Control Tower.
- **"Landing Zone"** -> Control Tower.
- **"Account Factory"** -> Control Tower (automated account provisioning).
- **Preventive guardrails** = SCPs. **Detective guardrails** = Config Rules.
- Control Tower uses Organizations under the hood but automates all configuration.

### RAM (Resource Access Manager)

- **"Share subnets between accounts"** -> RAM.
- **"Share Transit Gateway between accounts"** -> RAM.
- Don't confuse with cross-account roles (STS AssumeRole) which is for API access.
- In Organizations, RAM shares without invitations. Outside, requires accepting an invitation.

### Encryption

- **KMS** for most encryption scenarios. Multi-tenant.
- **CloudHSM** when you need FIPS 140-2 Level 3 or full key control.
- **Envelope encryption** for data larger than 4 KB.
- **Multi-Region Keys** to decrypt data replicated between regions.
- SSE-S3 uses **AWS Owned Keys**. SSE-KMS uses **AWS Managed** or **Customer Managed Keys**. SSE-C = the customer provides the key.

### Secrets and Configuration

- **Secrets Manager** = automatic rotation of DB credentials. More expensive.
- **Parameter Store** = general configuration and simple secrets. Cheaper. Hierarchy with paths.

### Web Protection

- **WAF** = Layer 7 (HTTP/HTTPS). Rules against SQL injection, XSS, rate limiting.
- **Shield Standard** = free, basic Layer 3/4 DDoS.
- **Shield Advanced** = advanced DDoS + DRT + cost protection.
- WAF deploys on ALB, CloudFront, API Gateway (not on NLB or EC2 directly).

### Cognito

- **User Pools** = authentication (JWT).
- **Identity Pools** = temporary AWS credentials.
- To give direct S3 access from a mobile app: User Pool + Identity Pool.
- ALB can authenticate against Cognito User Pools or OIDC providers.

### Active Directory

- **"Migrate Windows workloads with Active Directory"** -> AWS Managed Microsoft AD (+ FSx for Windows for file shares).
- **"Use existing on-premises AD without replicating in AWS"** -> AD Connector.
- **"Windows file share + AD"** -> FSx for Windows (not EFS). EFS = Linux/NFS only.
- **AWS Managed AD** supports bidirectional trust with on-premises AD. AD Connector only redirects.

### Detection

- **GuardDuty** detects threats by analyzing logs.
- **Inspector** scans vulnerabilities in EC2, ECR, and Lambda.
- **Macie** detects sensitive data (PII) in S3.
- **Detective** investigates security findings (does not detect).
- If they ask "discover sensitive data in S3" -> Macie.
- If they ask "detect suspicious behavior or threats" -> GuardDuty.
- If they ask "scan software vulnerabilities" -> Inspector.
