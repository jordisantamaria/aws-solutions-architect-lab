# Domain 1: Design Secure Architectures

## Question 1

A company has a web application deployed on EC2 with an Application Load Balancer. The security team requires that all HTTP traffic be automatically redirected to HTTPS. What is the simplest solution?

A) Configure a Security Group rule to block port 80
B) Configure a listener rule on the ALB to redirect HTTP (port 80) to HTTPS (port 443)
C) Use AWS WAF to block HTTP requests
D) Modify the application code to detect HTTP and redirect to HTTPS

<details>
<summary>Show answer</summary>

**Answer: B**

The ALB natively supports listener rules that can redirect HTTP traffic to HTTPS with a 301 or 302 status code. This is the simplest and most efficient solution. Option A would block traffic instead of redirecting it. Option C is complex and unnecessary for a simple redirect. Option D requires code changes and is not the "simplest".

**Key service/concept:** ALB Listener Rules, HTTPS redirect
</details>

---

## Question 2

A company needs to give a Lambda application in Account A access to write to a DynamoDB table in Account B. What is the most secure way to implement this?

A) Create an IAM user in Account B with access credentials and store them as environment variables in Lambda
B) Create an IAM Role in Account B with DynamoDB permissions and configure a trust policy that allows Account A to assume the role
C) Make the DynamoDB table public with a permissive resource policy
D) Use VPC Peering between both accounts and access DynamoDB through the private network

<details>
<summary>Show answer</summary>

**Answer: B**

The cross-account pattern in AWS is implemented with IAM Roles and STS AssumeRole. A role is created in Account B with the necessary permissions and a trust policy that allows Account A (or a specific role) to assume that role. Lambda in Account A assumes the role and obtains temporary credentials. Option A uses long-term credentials (bad practice). Option C exposes data. Option D does not solve the IAM permissions problem.

**Key service/concept:** IAM Cross-Account Roles, STS AssumeRole
</details>

---

## Question 3

A development team needs to store connection credentials for an RDS database. The credentials must be rotated automatically every 30 days without causing application downtime. What is the best solution?

A) Store the credentials in a .env file in the application code and update them manually
B) Store the credentials in AWS Systems Manager Parameter Store with manual rotation via Lambda
C) Store the credentials in AWS Secrets Manager with automatic rotation enabled
D) Store the encrypted credentials in S3 and read them when the application starts

<details>
<summary>Show answer</summary>

**Answer: C**

AWS Secrets Manager offers native automatic rotation for RDS, Aurora, Redshift, and DocumentDB database credentials. You just need to enable rotation and configure the period (30 days). Secrets Manager uses an AWS-managed Lambda to rotate credentials without downtime. Option B requires implementing rotation manually. Option A is insecure. Option D does not support automatic rotation.

**Key service/concept:** AWS Secrets Manager, automatic rotation
</details>

---

## Question 4

A company has multiple AWS accounts under AWS Organizations. The security team wants to ensure that no account can launch EC2 instances outside the eu-west-1 and eu-central-1 regions. What is the correct approach?

A) Create an IAM Policy in each account that denies EC2 actions outside those regions
B) Create a Service Control Policy (SCP) on the OU that denies all EC2 actions if aws:RequestedRegion is not eu-west-1 or eu-central-1
C) Configure AWS Config rules in each account to detect instances in non-permitted regions
D) Use AWS Firewall Manager to block traffic from non-approved regions

<details>
<summary>Show answer</summary>

**Answer: B**

SCPs (Service Control Policies) in AWS Organizations are the correct mechanism to limit actions at the account or OU level. An SCP with the `aws:RequestedRegion` condition can prevent any user or role (except the organization root) from launching resources outside the specified regions. Option A requires managing policies individually in each account. Option C is detective, not preventive. Option D does not apply to regional service restrictions.

**Key service/concept:** AWS Organizations, Service Control Policies (SCP)
</details>

---

## Question 5

An application on EC2 needs to access encrypted objects in S3 using SSE-KMS. The application uses an IAM Role. Developers report "Access Denied" errors when trying to download objects. The role has s3:GetObject permissions on the bucket. What is missing?

A) The EC2 instance's Security Group does not allow outbound traffic on port 443
B) The IAM Role needs kms:Decrypt permissions on the KMS key used to encrypt the objects
C) A VPC Endpoint for S3 is needed
D) The bucket policy needs to allow access from the VPC

<details>
<summary>Show answer</summary>

**Answer: B**

When objects in S3 are encrypted with SSE-KMS, the download process requires the caller to have permissions to decrypt with the specific KMS key. The role needs both `s3:GetObject` on the bucket and `kms:Decrypt` on the KMS key. Without the KMS permission, S3 cannot decrypt the object to deliver it. Options A, C, and D could cause other issues, but the scenario indicates the error is specifically about permissions.

**Key service/concept:** SSE-KMS, KMS permissions, kms:Decrypt
</details>

---

## Question 6

A company needs to store credit card data and comply with PCI-DSS. They require that encryption keys be managed in dedicated hardware with FIPS 140-2 Level 3 certification. What service should they use?

A) AWS KMS with AWS-managed keys
B) AWS KMS with Customer Managed Keys (CMK)
C) AWS CloudHSM
D) AWS Secrets Manager

<details>
<summary>Show answer</summary>

**Answer: C**

AWS CloudHSM provides dedicated Hardware Security Modules (HSM) with FIPS 140-2 Level 3 certification. Standard KMS has Level 2 certification. CloudHSM offers single-tenant HSMs where the customer has exclusive control of the cryptographic hardware. It is the appropriate service when compliance explicitly requires FIPS 140-2 Level 3.

**Key service/concept:** AWS CloudHSM, FIPS 140-2 Level 3
</details>

---

## Question 7

An architect needs to configure a VPC so that instances in a private subnet can download updates from the internet, but are NOT accessible from the internet. What components are needed?

A) Internet Gateway + Public IP on the private subnet instances
B) NAT Gateway in a public subnet + route in the private subnet's route table to the NAT Gateway
C) VPC Endpoint Gateway for internet
D) Elastic IP assigned directly to each instance in the private subnet

<details>
<summary>Show answer</summary>

**Answer: B**

A NAT Gateway allows instances in private subnets to initiate outbound connections to the internet (for updates, patches, etc.) without being accessible from the internet. The NAT Gateway is placed in a public subnet (with a route to the IGW) and the private subnet's route table points 0.0.0.0/0 to the NAT Gateway. Options A and D would make the instances accessible from the internet. Option C does not exist for general internet access.

**Key service/concept:** NAT Gateway, private subnets, outbound internet access
</details>

---

## Question 8

A web application handles user authentication with username and password, and also allows login with Google and Facebook. Authenticated users need to access files directly in a private S3 bucket. What combination of AWS services is the most appropriate?

A) IAM Users for each application user with attached S3 policies
B) Cognito User Pool for authentication + Cognito Identity Pool for temporary AWS credentials to access S3
C) ALB with OIDC authentication + S3 presigned URLs
D) API Gateway with Lambda Authorizer + S3 presigned URLs

<details>
<summary>Show answer</summary>

**Answer: B**

Cognito User Pool handles authentication (username/password, Google, Facebook) and issues JWT tokens. Cognito Identity Pool exchanges those tokens for temporary AWS credentials (IAM Role) that allow direct access to S3. This combination is the standard AWS pattern for giving access to AWS services from web/mobile applications with authenticated users. Option A does not scale and is insecure. Options C and D would partially work but do not provide direct S3 access as the scenario requests.

**Key service/concept:** Cognito User Pools, Cognito Identity Pools, temporary credentials
</details>

---

## Question 9

A security team needs to automatically detect if any S3 bucket contains personally identifiable information (PII) such as social security numbers, credit card numbers, or email addresses. What service should they use?

A) Amazon GuardDuty
B) Amazon Inspector
C) Amazon Macie
D) AWS Config

<details>
<summary>Show answer</summary>

**Answer: C**

Amazon Macie uses machine learning and pattern matching to discover and protect sensitive data (PII) stored in S3. It can automatically identify data such as social security numbers, credit cards, passports, etc. GuardDuty detects threats but does not analyze data content. Inspector evaluates vulnerabilities in EC2/Lambda. Config evaluates resource configuration, not data content.

**Key service/concept:** Amazon Macie, PII detection in S3
</details>

---

## Question 10

A company has an API Gateway + Lambda application that is publicly accessible. They have received SQL injection and cross-site scripting attacks. What is the best solution to protect the API?

A) Implement input validation in the Lambda code
B) Configure AWS Shield Advanced on the API
C) Deploy AWS WAF with managed rules against SQL injection and XSS associated with the API Gateway
D) Configure a Security Group on the API Gateway to filter malicious traffic

<details>
<summary>Show answer</summary>

**Answer: C**

AWS WAF can be associated directly with API Gateway and offers managed rules (AWS Managed Rules) that detect and block SQL injection, XSS, and other common application layer attacks. It is the most direct and complete solution. Option A is good practice but is not sufficient on its own. Option B protects against DDoS, not against SQLi/XSS. Option D is incorrect as API Gateway does not have Security Groups.

**Key service/concept:** AWS WAF, API Gateway, SQL injection, XSS protection
</details>

---

## Question 11

A company wants to ensure that all EC2 instances have EBS volume encryption enabled across the entire organization. They want a preventive solution, not just detective. What is the best approach?

A) Use AWS Config rule to detect unencrypted volumes and send alerts via SNS
B) Enable the "EBS encryption by default" option in each account and region, and use SCP to prevent disabling it
C) Create a Lambda that scans EBS volumes every hour and encrypts those that are not encrypted
D) Use Amazon Inspector to identify instances with unencrypted volumes

<details>
<summary>Show answer</summary>

**Answer: B**

"EBS encryption by default" is an account/region-level setting that automatically encrypts all new EBS volumes. Combined with an SCP that prevents account administrators from disabling this setting, you get an organizational-level preventive control. Option A is detective, not preventive. Options C and D are also detective/reactive.

**Key service/concept:** EBS encryption by default, SCP, preventive controls
</details>

---

## Question 12

An architect is designing a solution where an application in a VPC must access S3 without traffic passing through the internet. The solution must be as cost-effective as possible. What should be implemented?

A) VPC Interface Endpoint for S3 (PrivateLink)
B) VPC Gateway Endpoint for S3
C) NAT Gateway + internet route to access S3
D) Dedicated AWS Direct Connect for S3 traffic

<details>
<summary>Show answer</summary>

**Answer: B**

VPC Gateway Endpoints for S3 (and DynamoDB) are **free**. They are configured as an entry in the subnet's route table and traffic to S3 is routed directly within the AWS network without passing through the internet. Interface Endpoints (option A) have hourly and per-GB costs. The NAT Gateway (option C) has costs and traffic would go out to the internet. Direct Connect (option D) is the most expensive option.

**Key service/concept:** VPC Gateway Endpoint, S3, free private traffic
</details>

---

## Question 13

A company needs to centralize security logs from all their AWS accounts in a single location for auditing. They need to record all API calls across all accounts and regions, and ensure that logs cannot be deleted or modified. What is the best solution?

A) Enable CloudTrail in each account individually and send logs to local S3 buckets
B) Create an Organization Trail in AWS CloudTrail that sends logs to a centralized S3 bucket with Object Lock (compliance mode) and a bucket policy that prevents deletion
C) Use AWS Config in all accounts to record configuration changes
D) Enable VPC Flow Logs in all VPCs and centralize them in CloudWatch Logs

<details>
<summary>Show answer</summary>

**Answer: B**

An Organization Trail in CloudTrail automatically captures all API events across all organization accounts and all regions. Sending logs to a centralized S3 bucket in a dedicated security account, with S3 Object Lock in compliance mode (WORM), logs cannot be deleted even by the root user during the retention period. Option A is not centralized and does not prevent deletion. Options C and D capture different data than API calls.

**Key service/concept:** CloudTrail Organization Trail, S3 Object Lock (compliance mode)
</details>

---

## Question 14

An application uses an IAM Role with the following policy attached. A developer reports that they cannot perform the `s3:DeleteObject` action despite having a separate policy that allows `s3:*`. Why?

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": "s3:DeleteObject",
      "Resource": "arn:aws:s3:::production-bucket/*"
    }
  ]
}
```

A) The Allow policy needs to be more specific than the Deny policy
B) An explicit Deny always prevails over any Allow, regardless of where it is defined
C) Role policies take priority over user policies
D) An explicit Allow is needed in the same policy that contains the Deny

<details>
<summary>Show answer</summary>

**Answer: B**

In IAM policy evaluation, an **explicit Deny always wins** over any explicit Allow, regardless of how many Allow policies exist or where they are defined. This is the fundamental principle of IAM: Explicit Deny > Explicit Allow > Implicit Deny. Even though the developer has `s3:*` in another policy, the explicit Deny on `s3:DeleteObject` prevails.

**Key service/concept:** IAM Policy Evaluation Logic, Explicit Deny
</details>

---

## Question 15

A company is migrating its application to AWS and needs to implement a Web Application Firewall solution. They require protection against the OWASP top 10 risks, rate limiting to prevent abuse, and geo-blocking to block traffic from certain countries. The application uses CloudFront as a CDN. What is the most complete solution?

A) Configure CloudFront geographic restrictions for geo-blocking and Security Groups for rate limiting
B) Deploy AWS WAF associated with CloudFront with: AWS Managed Rules for OWASP top 10, rate-based rules for rate limiting, and geo-match conditions for geo-blocking
C) Use AWS Shield Advanced for all protection
D) Implement an Nginx proxy on EC2 with ModSecurity and custom rules

<details>
<summary>Show answer</summary>

**Answer: B**

AWS WAF associated with CloudFront covers all requirements: AWS Managed Rules include rule sets against OWASP top 10 (SQL injection, XSS, etc.), rate-based rules limit requests per IP, and geo-match conditions allow blocking traffic by country. It is the most complete and managed native AWS solution. Option A does not protect against OWASP. Option C protects against DDoS but does not offer detailed OWASP rules. Option D requires manual management and is not a managed solution.

**Key service/concept:** AWS WAF, CloudFront, Managed Rules, rate-based rules, geo-match
</details>
