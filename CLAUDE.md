# AWS Solutions Architect Lab

## Context
Study repository for AWS Certified Solutions Architect Associate (SAA-C03). Combines theoretical documentation + Terraform projects for learning by doing.

## Stack
- **IaC**: Terraform (HCL)
- **Cloud**: AWS
- **Default region**: eu-west-1
- **Documentation**: English
- **Terraform code**: English (comments in English, industry standard)

## Structure
```
docs/       → Theory by exam domain (11 sections)
labs/       → Progressive Terraform projects (00-09)
exam-prep/  → Cheat sheets, decision trees, practice questions
```

## Terraform Conventions
- Each lab has: main.tf, variables.tf, outputs.tf, backend.tf, README.md
- Remote backend in S3 with DynamoDB for state locking
- Variables always with description and validation where applicable
- Tags on all resources: Project, Environment, ManagedBy=terraform
- Security groups with specific rules, never 0.0.0.0/0 in production
- Always include cost estimation in README
- Always remember `terraform destroy` when finished

## SAA-C03 Exam Domains
1. Design Secure Architectures (30%)
2. Design Resilient Architectures (26%)
3. Design High-Performing Architectures (24%)
4. Design Cost-Optimized Architectures (20%)

## Relationship with Other Repos
- `ai-engineering-lab`: ML models can be deployed on this infrastructure
- `llm-playbook`: LLM applications run on these AWS services
