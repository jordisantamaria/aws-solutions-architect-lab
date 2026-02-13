# Arbol de Decisión: Selección de Compute

## Pregunta Principal: ¿Qué tipo de cómputo necesitas?

```
¿Qué necesitas ejecutar?
│
├── CONTROL TOTAL del SO / AMI personalizada / GPU / Licencias especiales
│   │
│   └──→ Amazon EC2
│        │
│        ├── ¿Qué modelo de precio?
│        │   │
│        │   ├── Carga impredecible / pruebas / corto plazo
│        │   │   └──→ On-Demand ($$$)
│        │   │
│        │   ├── Carga estable / producción / 1-3 años
│        │   │   ├──→ Reserved Instances (hasta 72% descuento)
│        │   │   └──→ Savings Plans (más flexibilidad entre familias)
│        │   │
│        │   ├── Tolerante a interrupciones / batch / CI/CD
│        │   │   └──→ Spot Instances (hasta 90% descuento)
│        │   │       └── Combinar con On-Demand en ASG (mixed instances)
│        │   │
│        │   ├── Compliance / licencias por socket
│        │   │   └──→ Dedicated Hosts
│        │   │
│        │   └── Hardware dedicado sin gestionar host
│        │       └──→ Dedicated Instances
│        │
│        ├── ¿Tipo de instancia?
│        │   ├── General purpose ──→ t3/m5/m6i
│        │   ├── CPU intensivo ──→ c5/c6i
│        │   ├── Memoria intensivo ──→ r5/r6i/x1
│        │   ├── Storage I/O ──→ i3/d2
│        │   └── GPU (ML/render) ──→ p4/g5/inf1
│        │
│        └── ¿Auto Scaling?
│            ├── Target Tracking (lo más simple)
│            ├── Step/Simple Scaling (acciones por alarma)
│            ├── Scheduled Scaling (eventos conocidos)
│            └── Predictive Scaling (patrones ML)
│
├── CÓDIGO DE CORTA DURACIÓN (< 15 minutos, event-driven)
│   │
│   └──→ AWS Lambda
│        │
│        ├── Triggers:
│        │   ├── API Gateway (HTTP requests)
│        │   ├── S3 Events (object created/deleted)
│        │   ├── DynamoDB Streams (cambios en tabla)
│        │   ├── SQS (mensajes en cola)
│        │   ├── SNS (notificaciones)
│        │   ├── EventBridge (eventos programados/custom)
│        │   ├── Kinesis (streaming data)
│        │   └── CloudWatch Events/Alarms
│        │
│        ├── Precio: Por invocación + duración (ms) + memoria
│        │   └── Gratis: 1M invocaciones + 400,000 GB-s/mes
│        │
│        └── Limitaciones:
│            ├── Máximo 15 minutos por ejecución
│            ├── Máximo 10 GB de memoria
│            ├── 1,000 concurrencia por defecto
│            └── Cold start (mitigar con Provisioned Concurrency)
│
├── CONTENEDORES
│   │
│   ├── ¿Necesitas Kubernetes específicamente?
│   │   │
│   │   ├── SÍ ──→ Amazon EKS (Elastic Kubernetes Service)
│   │   │   ├── Portabilidad multi-cloud
│   │   │   ├── Ecosistema K8s existente
│   │   │   ├── Helm charts, operators, etc.
│   │   │   └── Precio: $0.10/hr por cluster + compute
│   │   │
│   │   └── NO (quiero algo más simple)
│   │       └──→ Amazon ECS (Elastic Container Service)
│   │           ├── Integración nativa AWS más profunda
│   │           ├── Task definitions, services
│   │           ├── Más simple que K8s
│   │           └── Sin costo del control plane
│   │
│   └── ¿Quieres gestionar la infraestructura EC2 subyacente?
│       │
│       ├── SÍ ──→ EC2 Launch Type
│       │   ├── Control total de instancias
│       │   ├── Puedes usar Spot/Reserved
│       │   └── Tú gestionas el capacity
│       │
│       └── NO (serverless) ──→ AWS Fargate
│           ├── Sin gestión de servidores
│           ├── Pago por vCPU + memoria usada
│           ├── Funciona con ECS y EKS
│           └── Más caro que EC2 Launch Type pero sin gestión
│
├── BATCH PROCESSING (jobs en cola, procesamiento masivo)
│   │
│   └──→ AWS Batch
│        ├── Planifica y ejecuta jobs en EC2 o Fargate
│        ├── Gestión automática de cola y compute
│        ├── Ideal con Spot Instances para ahorro
│        ├── Procesamiento de imágenes, simulaciones, rendering
│        └── Sin límite de tiempo (a diferencia de Lambda)
│
├── PaaS (solo quiero desplegar mi código, sin gestionar infra)
│   │
│   └──→ AWS Elastic Beanstalk
│        ├── Soporta: Java, .NET, PHP, Node.js, Python, Ruby, Go, Docker
│        ├── Gestiona automáticamente: EC2, ASG, ELB, RDS
│        ├── Tú controlas los recursos subyacentes
│        ├── Sin costo adicional (pagas por los recursos)
│        └── Despliegues: All at once, Rolling, Immutable, Blue/Green
│
├── EDGE COMPUTING (procesamiento cerca del usuario)
│   │
│   ├── Código ligero en CloudFront edge
│   │   ├── CloudFront Functions (< 1 ms, JS, header manipulation)
│   │   └── Lambda@Edge (hasta 30s, más features, viewer/origin)
│   │
│   ├── Outposts (AWS en tu datacenter)
│   │   └── Latencia ultra-baja, residencia de datos
│   │
│   └── Wavelength (dentro de redes 5G)
│       └── Aplicaciones móviles ultra-baja latencia
│
└── COMPUTACIÓN HÍBRIDA
    │
    ├── AWS en tu datacenter ──→ Outposts
    ├── VMware en AWS ──→ VMware Cloud on AWS
    └── Gestionar servers on-prem ──→ Systems Manager
```

---

## Tabla de Decisión Rápida con Precios

| Servicio | Modelo de precio | Costo relativo | Cuándo usarlo |
|----------|-----------------|---------------|---------------|
| **EC2 On-Demand** | Por hora/segundo | $$$ | Desarrollo, pruebas, cargas impredecibles |
| **EC2 Reserved** | 1-3 años compromiso | $ | Producción estable (hasta 72% descuento) |
| **EC2 Spot** | Bid por capacidad sobrante | ¢ | Batch, CI/CD, tolerante a fallos (hasta 90% descuento) |
| **Lambda** | Por invocación + duración | ¢-$$ | Event-driven, < 15 min, tráfico variable |
| **Fargate** | Por vCPU + memoria por segundo | $$ | Contenedores sin gestión de servidores |
| **ECS (EC2)** | Instancias EC2 subyacentes | $-$$ | Contenedores con control de infra |
| **EKS** | $0.10/hr cluster + compute | $$-$$$ | Kubernetes, portabilidad, ecosistema K8s |
| **Batch** | EC2/Fargate subyacente | $-$$ | Jobs en cola, procesamiento masivo |
| **Beanstalk** | Recursos subyacentes | $-$$$ | PaaS rápido, sin overhead de operaciones |

---

## Comparación: Lambda vs Fargate vs EC2

| Criterio | Lambda | Fargate | EC2 |
|----------|--------|---------|-----|
| **Gestión de servidor** | Ninguna | Ninguna | Tú gestionas |
| **Duración máxima** | 15 minutos | Ilimitado | Ilimitado |
| **Escalado** | Automático (concurrencia) | Automático (tasks) | Auto Scaling Groups |
| **Cold start** | Sí (mitigable) | Sí (~30s) | No (instancia running) |
| **Pago** | Por ms de ejecución | Por segundo (vCPU+mem) | Por hora/segundo |
| **Costo en reposo** | $0 | $0 (si 0 tasks) | Pagas la instancia |
| **Container support** | Container images | Docker nativo | Docker en EC2 |
| **Networking** | VPC opcional | VPC (ENI por task) | VPC completo |
| **Ideal para** | Eventos, APIs, procesamiento corto | Microservicios, apps long-running sin gestión | Control total, GPU, compliance |

---

## Patrones Comunes en el Examen

### Patrón 1: Web Application escalable
```
Route 53 ──→ CloudFront ──→ ALB ──→ EC2 Auto Scaling Group
                                         │
                                    ┌────┴────┐
                                    │ EC2     │ EC2 (min 2, multi-AZ)
                                    └─────────┘
```

### Patrón 2: Microservicios serverless
```
API Gateway ──→ Lambda ──→ DynamoDB
                  │
                  └──→ SQS ──→ Lambda (async processing)
```

### Patrón 3: Contenedores con alta disponibilidad
```
ALB ──→ ECS/EKS Fargate ──→ Aurora
             │
        Auto Scaling (target tracking por CPU)
```

### Patrón 4: Batch processing económico
```
S3 (input) ──→ EventBridge ──→ AWS Batch (Spot Instances) ──→ S3 (output)
```

---

## Keywords del Examen → Servicio

```
"Full OS control / custom AMI"               → EC2
"GPU / ML training"                           → EC2 (P/G instances) o SageMaker
"Event-driven, short duration"                → Lambda
"Serverless containers"                       → Fargate (ECS o EKS)
"Kubernetes"                                  → EKS
"Simple container orchestration"              → ECS
"Deploy code without managing infra"          → Elastic Beanstalk
"Batch jobs / queue processing"               → AWS Batch
"Lowest cost, can be interrupted"             → Spot Instances
"Stable workload, cost savings"               → Reserved / Savings Plans
"Edge computing on CloudFront"                → Lambda@Edge / CloudFront Functions
"AWS in your datacenter"                      → Outposts
"Auto scale based on CPU"                     → ASG + Target Tracking
"Scheduled scaling for known events"          → ASG + Scheduled Scaling
"Run containers, no cluster management"       → Fargate
"Licensing per physical socket"               → Dedicated Hosts
```
