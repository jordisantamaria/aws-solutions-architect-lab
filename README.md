# AWS Solutions Architect Associate (SAA-C03) Lab

Repositorio de estudio para la certificación **AWS Certified Solutions Architect - Associate (SAA-C03)**.

Combina documentación teórica + proyectos prácticos con Terraform para aprender haciendo.

## Dominios del examen

| Dominio | Peso | Secciones |
|---------|------|-----------|
| Design Secure Architectures | 30% | `02-iam-security`, `03-networking` |
| Design Resilient Architectures | 26% | `10-high-availability`, `04-compute`, `06-databases` |
| Design High-Performing Architectures | 24% | `03-networking`, `04-compute`, `05-storage`, `06-databases`, `07-application-services` |
| Design Cost-Optimized Architectures | 20% | `11-cost-optimization`, `04-compute`, `05-storage` |

## Estructura

```
docs/           → Teoría organizada por servicio/dominio
labs/           → Proyectos Terraform progresivos (de simple a complejo)
exam-prep/      → Cheat sheets, decision trees, preguntas de práctica
```

## Roadmap de estudio

### Fase 1: Fundamentos (Semana 1-2)
- [ ] Cloud fundamentals y Well-Architected Framework
- [ ] IAM en profundidad
- [ ] VPC y networking
- [ ] **Lab 00**: Setup AWS CLI + Terraform + backend S3
- [ ] **Lab 01**: VPC completa con subnets, NAT, Security Groups

### Fase 2: Compute y Storage (Semana 3-4)
- [ ] EC2, Auto Scaling, ELB
- [ ] S3, EBS, EFS
- [ ] Lambda y serverless
- [ ] **Lab 02**: Web server con EC2 + ALB + ASG
- [ ] **Lab 03**: API serverless con API GW + Lambda + DynamoDB

### Fase 3: Bases de datos y aplicaciones (Semana 5-6)
- [ ] RDS, Aurora, DynamoDB, ElastiCache
- [ ] SQS, SNS, EventBridge, Step Functions
- [ ] **Lab 04**: Three-tier app (ALB + ECS + Aurora + ElastiCache)
- [ ] **Lab 05**: Static website (S3 + CloudFront + Route53)

### Fase 4: Arquitecturas avanzadas (Semana 7-8)
- [ ] Monitoring y observabilidad
- [ ] Migración y transferencia de datos
- [ ] Alta disponibilidad y DR
- [ ] **Lab 06**: Event-driven (SQS + SNS + Lambda + EventBridge)
- [ ] **Lab 07**: Data pipeline (Kinesis + Lambda + S3 + Athena)

### Fase 5: Integración y repaso (Semana 9-10)
- [ ] Cost optimization strategies
- [ ] **Lab 08**: Multi-region HA con failover
- [ ] **Lab 09**: Arquitectura completa (proyecto final)
- [ ] Repasar cheat sheets y decision trees
- [ ] Hacer todas las preguntas de práctica

## Prerequisitos

- Cuenta AWS (Free Tier es suficiente para la mayoría de labs)
- AWS CLI v2 instalado y configurado
- Terraform >= 1.5
- Conocimientos básicos de redes (TCP/IP, DNS, HTTP)

## Costes

Cada lab incluye una estimación de coste. La mayoría se puede hacer en Free Tier.
**Siempre ejecuta `terraform destroy` al terminar un lab** para evitar cargos inesperados.

## Recursos complementarios

- [AWS SAA-C03 Exam Guide (PDF)](https://d1.awsstatic.com/training-and-certification/docs-sa-assoc/AWS-Certified-Solutions-Architect-Associate_Exam-Guide.pdf)
- [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/latest/framework/welcome.html)
- [AWS Free Tier](https://aws.amazon.com/free/)
- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
