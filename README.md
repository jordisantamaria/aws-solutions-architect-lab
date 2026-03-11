# AWS Solutions Architect Associate (SAA-C03) Lab

Study repository for the **AWS Certified Solutions Architect - Associate (SAA-C03)** certification.

Combines theoretical documentation + hands-on projects with Terraform for learning by doing.

## Exam Domains

| Domain | Weight | Sections |
|--------|--------|----------|
| Design Secure Architectures | 30% | `02-iam-security`, `03-networking` |
| Design Resilient Architectures | 26% | `10-high-availability`, `04-compute`, `06-databases` |
| Design High-Performing Architectures | 24% | `03-networking`, `04-compute`, `05-storage`, `06-databases`, `07-application-services` |
| Design Cost-Optimized Architectures | 20% | `11-cost-optimization`, `04-compute`, `05-storage` |

## Structure

```
docs/           → Theory organized by service/domain
labs/           → Progressive Terraform projects (from simple to complex)
exam-prep/      → Cheat sheets, decision trees, practice questions
```

## Study Roadmap

### Phase 1: Fundamentals (Week 1-2)
- [ ] Cloud fundamentals and Well-Architected Framework
- [ ] IAM in depth
- [ ] VPC and networking
- [ ] **Lab 00**: Setup AWS CLI + Terraform + S3 backend
- [ ] **Lab 01**: Complete VPC with subnets, NAT, Security Groups

### Phase 2: Compute and Storage (Week 3-4)
- [ ] EC2, Auto Scaling, ELB
- [ ] S3, EBS, EFS
- [ ] Lambda and serverless
- [ ] **Lab 02**: Web server with EC2 + ALB + ASG
- [ ] **Lab 03**: Serverless API with API GW + Lambda + DynamoDB

### Phase 3: Databases and Applications (Week 5-6)
- [ ] RDS, Aurora, DynamoDB, ElastiCache
- [ ] SQS, SNS, EventBridge, Step Functions
- [ ] **Lab 04**: Three-tier app (ALB + ECS + Aurora + ElastiCache)
- [ ] **Lab 05**: Static website (S3 + CloudFront + Route53)

### Phase 4: Advanced Architectures (Week 7-8)
- [ ] Monitoring and observability
- [ ] Migration and data transfer
- [ ] High availability and DR
- [ ] **Lab 06**: Event-driven (SQS + SNS + Lambda + EventBridge)
- [ ] **Lab 07**: Data pipeline (Kinesis + Lambda + S3 + Athena)

### Phase 5: Integration and Review (Week 9-10)
- [ ] Cost optimization strategies
- [ ] **Lab 08**: Multi-region HA with failover
- [ ] **Lab 09**: Complete architecture (final project)
- [ ] Review cheat sheets and decision trees
- [ ] Complete all practice questions

## Prerequisites

- AWS account (Free Tier is sufficient for most labs)
- AWS CLI v2 installed and configured
- Terraform >= 1.5
- Basic networking knowledge (TCP/IP, DNS, HTTP)

## Costs

Each lab includes a cost estimate. Most can be done on Free Tier.
**Always run `terraform destroy` when finishing a lab** to avoid unexpected charges.

## Complementary Resources

- [AWS SAA-C03 Exam Guide (PDF)](https://d1.awsstatic.com/training-and-certification/docs-sa-assoc/AWS-Certified-Solutions-Architect-Associate_Exam-Guide.pdf)
- [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html)
- [AWS Free Tier](https://aws.amazon.com/free/)
- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
