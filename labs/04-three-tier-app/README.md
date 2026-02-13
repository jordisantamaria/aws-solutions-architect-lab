# Lab 04: Arquitectura Three-Tier en AWS

## Objetivo

Desplegar una arquitectura three-tier clásica en AWS utilizando servicios gestionados y contenedores. Esta arquitectura es la base de la mayoría de aplicaciones web empresariales y uno de los patrones más preguntados en el examen AWS Solutions Architect.

## Arquitectura

```
                         ┌─────────────────────────────────────────────────┐
                         │                    INTERNET                     │
                         └────────────────────┬────────────────────────────┘
                                              │
                                              ▼
                    ┌─────────────────────────────────────────────────┐
                    │              PUBLIC SUBNETS (2 AZs)             │
                    │  ┌───────────────────────────────────────────┐  │
                    │  │     Application Load Balancer (ALB)       │  │
                    │  │         Puerto 80 / 443                   │  │
                    │  └─────────────────┬─────────────────────────┘  │
                    └────────────────────┼───────────────────────────-┘
                                         │
                    ┌────────────────────┼────────────────────────────┐
                    │              PRIVATE SUBNETS (App Tier)         │
                    │                    │                            │
                    │    ┌───────────────┴──────────────┐             │
                    │    │      ECS Fargate Service     │             │
                    │    │   ┌─────────┐ ┌─────────┐   │             │
                    │    │   │ Task 1  │ │ Task 2  │   │             │
                    │    │   │ (nginx) │ │ (nginx) │   │             │
                    │    │   └────┬────┘ └────┬────┘   │             │
                    │    └────────┼───────────┼────────┘             │
                    └─────────────┼───────────┼──────────────────────┘
                                  │           │
                    ┌─────────────┼───────────┼──────────────────────┐
                    │              PRIVATE SUBNETS (Data Tier)       │
                    │                 │           │                  │
                    │    ┌────────────┴──┐  ┌─────┴──────────┐      │
                    │    │ Aurora        │  │  ElastiCache    │      │
                    │    │ PostgreSQL    │  │  Redis          │      │
                    │    │ (Serverless)  │  │  (cache.t3.micro)│     │
                    │    │  AZ-a | AZ-b │  │                 │      │
                    │    └───────────────┘  └─────────────────┘      │
                    └────────────────────────────────────────────────┘
```

## Qué vas a aprender

- **ECS y Fargate**: orquestación de contenedores sin gestionar servidores
- **Aurora PostgreSQL Serverless v2**: base de datos relacional con escalado automático
- **ElastiCache Redis**: caché en memoria para reducir latencia y carga en la base de datos
- **Multi-AZ**: alta disponibilidad distribuyendo recursos en múltiples zonas de disponibilidad
- **Security Groups en capas**: cada tier solo acepta tráfico del tier anterior
- **Application Load Balancer**: distribución de tráfico HTTP/HTTPS
- **CloudWatch Logs**: centralización de logs de contenedores

## Componentes desplegados

| Componente | Servicio AWS | Tier |
|---|---|---|
| Balanceador de carga | ALB | Público |
| Aplicación | ECS Fargate (nginx) | Privado |
| Base de datos | Aurora PostgreSQL Serverless v2 | Privado |
| Caché | ElastiCache Redis | Privado |
| Logs | CloudWatch Log Group | - |

## Security Groups (capas de seguridad)

```
Internet ──► ALB SG (80/443) ──► ECS SG (80) ──► Aurora SG (5432)
                                       │
                                       └──► Redis SG (6379)
```

- **ALB SG**: permite tráfico entrante en puertos 80 y 443 desde cualquier IP
- **ECS SG**: permite tráfico entrante en puerto 80 solo desde el ALB SG
- **Aurora SG**: permite tráfico entrante en puerto 5432 solo desde el ECS SG
- **Redis SG**: permite tráfico entrante en puerto 6379 solo desde el ECS SG

## Requisitos previos

- Lab 01 (VPC Networking) desplegado (se usa el state remoto para obtener VPC y subnets)
- AWS CLI configurado
- Terraform >= 1.0

## Despliegue

```bash
terraform init
terraform plan
terraform apply
```

## Coste estimado

**~$5-8/día** cuando los recursos están activos.

| Servicio | Coste aproximado |
|---|---|
| Aurora Serverless v2 (0.5 ACU mín) | ~$2-4/día |
| ElastiCache Redis (cache.t3.micro) | ~$0.50/día |
| ALB | ~$0.60/día |
| ECS Fargate (2 tareas) | ~$1-2/día |
| CloudWatch Logs | ~$0.10/día |

## ⚠️ IMPORTANTE: Destruir al acabar

Aurora y ElastiCache generan costes significativos incluso en idle. **Destruye los recursos cuando termines**:

```bash
terraform destroy
```

Verifica en la consola de AWS que todos los recursos han sido eliminados correctamente, especialmente:
- Cluster Aurora y sus instancias
- Cluster ElastiCache
- Application Load Balancer
