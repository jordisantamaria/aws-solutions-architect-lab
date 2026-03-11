# Secondary Services for the SAA-C03 Exam

Services that appear in exam questions as correct answers or distractors. They don't need a full section but you need to know what they do to select or eliminate them.

## Table of Contents

- [Marketing and Communication](#marketing-and-communication)
- [Governance and Compliance](#governance-and-compliance)
- [Storage and Analysis](#storage-and-analysis)
- [Additional Security](#additional-security)
- [Application Integration](#application-integration)
- [Additional Machine Learning](#additional-machine-learning)
- [Cheat Sheet: Frequently Confused Services](#cheat-sheet-frequently-confused-services)

---

## Marketing and Communication

### Amazon Pinpoint
**Multi-channel Marketing Platform**

- Bulk sending of SMS, email, push notifications, voice
- Journeys: automated marketing flows (user registers → email day 1 → SMS day 3 → ...)
- Campaigns segmented by user behavior
- Two-way SMS: receive responses from users
- Integration with Kinesis for real-time event analysis

```
Use cases:
  - SMS marketing campaign to subscribers
  - Automated welcome email
  - Segmented push notifications
  - Collect SMS responses and analyze them
```

**For the exam:**
```
"Marketing campaign SMS/email/push"          → Pinpoint
"Multi-engagement campaign"                   → Pinpoint
"Two-way SMS (send and receive responses)"   → Pinpoint
"Send a simple notification/alert"           → SNS (not Pinpoint)
```

**Pinpoint vs SNS:**
```
Pinpoint: marketing (campaigns, journeys, segmentation, analytics)
SNS:      simple notifications (alerts, triggers, pub/sub)

"Notify admin that the server went down"     → SNS
"Send Black Friday offer to 50k users"       → Pinpoint
```

---

### Amazon Connect
**Cloud Contact Center (Call Center)**

- Complete virtual phone system
- IVR (interactive voice response)
- Call routing to agents
- Real-time chat
- Integration with Lex (chatbots) for self-service
- Contact flows: configurable call flows
- Call recording
- Agent performance analytics

```
Use cases:
  - Customer service call center
  - Automated phone system (IVR)
  - Technical support with chat + calls
  - Phone chatbot (Connect + Lex)
```

**For the exam:**
```
"Call center", "contact center"              → Amazon Connect
"IVR", "phone menu"                          → Amazon Connect
"Call routing to agents"                     → Amazon Connect
"Send SMS to customers" (without call center) → Pinpoint or SNS (NOT Connect)
```

**Connect vs Pinpoint:**
```
Connect:  customer service (the customer calls/writes you)
Pinpoint: marketing (you send messages to the customer)
```

---

## Governance and Compliance

### AWS Service Catalog
**Catalog of Approved IT Products**

- The infra team creates "products" (CloudFormation templates)
- Developers can only launch products from the catalog
- Centralized control of what can be deployed
- Versions, permissions, launch constraints
- Portfolios: product groupings by team/department

```
Example:
  IT creates 3 approved products:
    - "Web server" (pre-configured EC2 + ALB + ASG)
    - "Database" (RDS with encryption and backups)
    - "Data pipeline" (Glue + S3 + Athena)

  Developer wants a server → picks from catalog → launches with approved config
  Cannot create random EC2 without encryption or tags
```

**For the exam:**
```
"Catalog of approved IT products"                → Service Catalog
"Restrict what resources devs can launch"        → Service Catalog
"Standardize deployments"                         → Service Catalog
"Governance of what can be created"              → Service Catalog
```

**Service Catalog vs Control Tower:**
```
Service Catalog: controls WHAT RESOURCES can be created
Control Tower:   controls WHAT ACCOUNTS are created and how they are governed
```

---

### AWS Audit Manager
**Automate Compliance Audits**

- Automatically collects evidence from your AWS resources
- Pre-built frameworks (GDPR, HIPAA, PCI-DSS, SOC 2, etc.)
- Generates reports for auditors
- Maps controls to resources

```
For the exam:
  "Automate evidence collection for audits"   → Audit Manager
  "Prepare compliance reports"                 → Audit Manager
```

---

### AWS Artifact
**AWS Compliance Documents**

- Download AWS certifications (ISO 27001, SOC 1/2/3, PCI, HIPAA)
- Agreements (BAA for HIPAA, DPA for GDPR)
- Not an active service, it's a document portal

```
For the exam:
  "Download AWS compliance certifications"     → Artifact
  "BAA agreement for HIPAA"                     → Artifact
  "Prove that AWS complies with ISO 27001"      → Artifact
```

---

## Storage and Analysis

### S3 Storage Lens
**Analytics Dashboard for All Your S3 Buckets**

- Global view of all your buckets (multi-account, multi-region)
- Metrics: size, number of objects, costs
- Configuration analysis: versioning, encryption, public access
- Cost optimization recommendations
- Free dashboard with basic metrics, paid for advanced

```
What it answers:
  - "How many buckets do I have and how much do they store?"
  - "Which ones DON'T have versioning enabled?"
  - "Which ones DON'T have encryption?"
  - "Where can I save money on S3?"
```

**For the exam:**
```
"Analyze the state of all S3 buckets"            → S3 Storage Lens
"Which buckets don't have versioning?"            → S3 Storage Lens
"S3 metrics dashboard multi-account"              → S3 Storage Lens
"Who accessed which object?"                      → CloudTrail Data Events (NOT Storage Lens)
```

**Storage Lens vs other analysis services:**
```
Storage Lens:        "How ARE my buckets?"         (current state, configuration)
CloudTrail:          "What HAPPENED?"               (action log)
AWS Config:          "Does it COMPLY with the rule?" (resource compliance)
IAM Access Analyzer: "Who HAS access?"              (permissions)
```

---

## Additional Security

### AWS Network Firewall
**Managed Firewall for VPC**

- Network-level traffic inspection (Layer 3-7)
- Filtering by IP, port, protocol, domain
- Intrusion detection (IDS/IPS)
- Stateful and stateless rules

**For the exam:**
```
"Deep network traffic inspection"          → Network Firewall
"IDS/IPS on AWS"                           → Network Firewall
"Filter traffic by domain"                 → Network Firewall
"Block malicious HTTP requests"            → WAF (not Network Firewall)
```

**Network Firewall vs WAF vs Security Groups:**
```
Security Groups:   basic IP/port rules per instance (Layer 4)
Network Firewall:  deep inspection of entire VPC (Layer 3-7)
WAF:               HTTP/HTTPS web app protection (Layer 7)
```

---

## Application Integration

### Amazon AppFlow
**No-Code Data Integration Between SaaS and AWS**

- Connects Salesforce, Slack, SAP, Google Analytics, etc. with S3, Redshift, etc.
- Scheduled or event-driven transfers
- Basic transformations (filter, map fields)
- No code required

```
For the exam:
  "Integrate Salesforce with S3"                → AppFlow
  "Transfer data from SaaS to AWS without code"  → AppFlow
```

---

## Additional Machine Learning

### Amazon Augmented AI (A2I)
**Human Review of ML Predictions**

- When an ML model is not confident, it passes to human review
- Review workflows with people
- Integration with Textract, Rekognition, SageMaker

```
For the exam:
  "Human review of ML predictions"            → A2I
  "Human in the loop"                          → A2I
```

---

## Cheat Sheet: Frequently Confused Services

### Communication Services
```
SNS:      simple notifications (alert, trigger)
SES:      email at scale (transactional, marketing)
Pinpoint: multi-channel marketing (SMS + email + push + journeys)
Connect:  call center (calls + support chat)
```

### State Analysis Services
```
CloudTrail:         What HAPPENED? (action log)
AWS Config:         Does it COMPLY with the rule? (compliance)
Storage Lens:       How ARE my S3 buckets? (metrics and config)
IAM Access Analyzer: Who HAS access? (permissions)
Trusted Advisor:    What can I IMPROVE? (recommendations)
Security Hub:       What is my SECURITY POSTURE? (dashboard)
```

### Protection Services
```
Security Groups:    per-instance firewall (IP/port)
NACLs:              per-subnet firewall (stateless)
WAF:                HTTP/HTTPS protection (SQL injection, XSS)
Shield:             DDoS protection
Network Firewall:   deep VPC traffic inspection
GuardDuty:          threat detection (intelligent analysis)
Inspector:          vulnerability scanning (EC2, containers)
Macie:              sensitive data detection in S3
```

### Transfer Services
```
DataSync:           move data on-premise → AWS (migration)
Storage Gateway:    continuous bridge on-premise ↔ AWS
Transfer Family:    SFTP/FTP → S3 (third parties upload files)
Snow Family:        physical migration (TB/PB on device)
DMS:                migrate databases
MGN:                migrate servers (lift & shift)
```

### Governance Services
```
Organizations:      group accounts, billing, SCPs
Control Tower:      Landing Zone, Account Factory, guardrails
RAM:                share resources between accounts
Service Catalog:    catalog of approved IT products
Artifact:           AWS compliance documents
Audit Manager:      automate evidence collection
```

### Edge/Location Services
```
CloudFront:         global CDN (content caching)
Global Accelerator: optimized network-level routing
Wavelength:         compute in 5G networks
Outposts:           AWS in your data center (your hardware)
Local Zones:        AWS closer to a city (AWS hardware)
```
