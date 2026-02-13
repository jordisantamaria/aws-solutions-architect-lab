# Compute en AWS

## Tabla de Contenidos

- [EC2 Instance Types](#ec2-instance-types)
- [EC2 Purchasing Options](#ec2-purchasing-options)
- [EC2 Placement Groups](#ec2-placement-groups)
- [EC2 Networking](#ec2-networking)
- [AMIs](#amis)
- [User Data e Instance Metadata](#user-data-e-instance-metadata)
- [Auto Scaling Groups](#auto-scaling-groups)
- [AWS Lambda](#aws-lambda)
- [ECS vs EKS vs Fargate](#ecs-vs-eks-vs-fargate)
- [Elastic Beanstalk](#elastic-beanstalk)
- [AWS Batch](#aws-batch)
- [AWS Outposts, Wavelength y Local Zones](#aws-outposts-wavelength-y-local-zones)
- [Compute Exam Tips](#compute-exam-tips)

---

## EC2 Instance Types

### Naming Convention

El nombre de un tipo de instancia sigue el formato: `m5a.xlarge`

| Parte | Significado | Ejemplo |
|-------|-------------|---------|
| **m** | Familia de instancia | m = general purpose |
| **5** | Generación | 5ta generación |
| **a** | Atributo adicional (opcional) | a = AMD, g = Graviton (ARM), n = networking optimized, d = NVMe local storage |
| **xlarge** | Tamaño | nano, micro, small, medium, large, xlarge, 2xlarge... metal |

### Familias de instancias

#### General Purpose (Propósito general) - Familias: M, T, A

| Familia | Procesador | Caso de uso |
|---------|-----------|-------------|
| **M7g, M7i, M6i, M5** | Intel/AMD/Graviton | Aplicaciones balanceadas (web servers, repositorios de código, entornos de desarrollo) |
| **T3, T3a, T2** | Intel/AMD | Cargas con ráfagas (burstable). Acumulan créditos de CPU |
| **A1** | Graviton (ARM) | Cargas ligeras ARM-compatible |

> **T instances (burstable):** Tienen un nivel de rendimiento base de CPU. Cuando la carga es baja, acumulan créditos. Cuando necesitan más CPU, gastan créditos. Si se agotan los créditos y está en modo `standard`, el rendimiento se degrada. En modo `unlimited`, se cobra extra por créditos adicionales.

#### Compute Optimized (Optimizadas para cómputo) - Familia: C

| Familia | Caso de uso |
|---------|-------------|
| **C7g, C7i, C6i, C5** | Procesamiento por lotes, HPC, machine learning inference, gaming servers, transcodificación de media, modelos científicos, servidores de anuncios |

- Mayor ratio de vCPU a memoria.
- Ideal cuando el cuello de botella es la CPU.

#### Memory Optimized (Optimizadas para memoria) - Familias: R, X, z

| Familia | Caso de uso |
|---------|-------------|
| **R7g, R7i, R6i, R5** | Bases de datos en memoria, caches distribuidos (ElastiCache), análisis en tiempo real |
| **X2idn, X2iedn, X1** | SAP HANA, Apache Spark, bases de datos in-memory de gran escala |
| **z1d** | Aplicaciones EDA (Electronic Design Automation), bases de datos con alta frecuencia de CPU |

- Gran cantidad de RAM.
- **R** = RAM (nemotécnico para recordar).

#### Storage Optimized (Optimizadas para almacenamiento) - Familias: I, D, H

| Familia | Caso de uso |
|---------|-------------|
| **I4i, I3, I3en** | Bases de datos NoSQL (Cassandra, MongoDB), data warehousing, sistemas de archivos distribuidos. Altísimo IOPS (NVMe SSD local) |
| **D3, D3en** | MapReduce, HDFS, sistemas de archivos distribuidos. HDD de alta densidad |
| **H1** | MapReduce, HDFS. HDD con alto throughput secuencial |

- Ideal cuando necesitas alto IOPS local o gran capacidad de disco.

#### Accelerated Computing (Cómputo acelerado) - Familias: P, G, Inf, Trn, F, VT

| Familia | Acelerador | Caso de uso |
|---------|-----------|-------------|
| **P5, P4d, P3** | GPU NVIDIA (training) | Machine learning training, HPC, análisis computacional |
| **G5, G4dn, G4ad** | GPU NVIDIA/AMD (gráficos) | Machine learning inference, gráficos 3D, gaming streaming, transcodificación de video |
| **Inf2, Inf1** | AWS Inferentia | Machine learning inference de alto rendimiento |
| **Trn1** | AWS Trainium | Machine learning training optimizado |
| **F1** | FPGA | Genómica, análisis financiero, codificación de video |
| **VT1** | Xilinx | Transcodificación de video en tiempo real |

---

## EC2 Purchasing Options

| Opción | Descripción | Descuento | Compromiso | Interrupción | Ideal para |
|--------|-------------|-----------|------------|-------------|------------|
| **On-Demand** | Pago por segundo (Linux) o por hora (Windows) | 0% (base) | Ninguno | No | Dev/test, cargas impredecibles, primer uso |
| **Reserved Instances (Standard)** | Reserva de tipo específico en una región | Hasta ~72% | 1 o 3 años | No | Bases de datos, workloads estables 24/7 |
| **Reserved Instances (Convertible)** | RI que permite cambiar tipo, familia, SO, tenancy | Hasta ~54% | 1 o 3 años | No | Workloads estables pero con posibilidad de cambiar requerimientos |
| **Savings Plans (Compute)** | Compromiso de $/hora. Flexible en familia, región, SO, tenancy | Hasta ~66% | 1 o 3 años | No | Uso flexible entre EC2, Lambda, Fargate |
| **Savings Plans (EC2 Instance)** | Compromiso de $/hora. Fijo a familia + región | Hasta ~72% | 1 o 3 años | No | EC2 con familia y región conocidas |
| **Spot Instances** | Capacidad sobrante de AWS | Hasta ~90% | Ninguno | **Sí** (2 min aviso) | Batch, CI/CD, data analysis, cargas tolerantes a fallos |
| **Dedicated Hosts** | Servidor físico dedicado completo | Bajo demanda o Reserved | Ninguno o 1-3 años | No | Licencias BYOL (por socket/core), compliance estricto |
| **Dedicated Instances** | Instancia en hardware dedicado a tu cuenta | Menor que Dedicated Host | Ninguno | No | Aislamiento a nivel de hardware sin necesidad de control del servidor |
| **Capacity Reservations** | Reserva capacidad en una AZ específica | 0% (pagas On-Demand) | Ninguno | No | Garantizar disponibilidad en AZ para eventos o DR |

### Spot Instances - Detalle

- **Spot Price**: Precio variable según oferta/demanda. Tú defines un **max price**.
- **Spot Request**: One-time (se lanza y termina) o Persistent (se relanza automáticamente si se interrumpe).
- **Spot Fleet**: Colección de Spot Instances (y opcionalmente On-Demand) que cumple una capacidad target.
  - Estrategias: `lowestPrice`, `diversified`, `capacityOptimized`, `priceCapacityOptimized` (recomendado).
- **Interrupción**: AWS da un aviso de **2 minutos** antes de reclamar la instancia.
  - Acciones posibles: `terminate`, `stop`, `hibernate`.
- **Spot Block** (deprecated en muchas regiones): Reserva Spot por 1-6 horas sin interrupción.

### Dedicated Hosts vs Dedicated Instances

| Característica | Dedicated Host | Dedicated Instance |
|---------------|---------------|-------------------|
| **Control del servidor** | Sí (visibilidad de sockets, cores, host ID) | No |
| **Licencias BYOL** | Sí (por socket/core/VM) | No |
| **Afinidad a servidor** | Sí (puedes elegir el host) | No |
| **Placement control** | Sí | No |
| **Coste** | Más caro | Menos caro que Dedicated Host |

> **Tip para el examen:** Si la pregunta menciona "licencias existentes por socket/core" o "BYOL", la respuesta es **Dedicated Hosts**.

---

## EC2 Placement Groups

Los Placement Groups controlan cómo se colocan las instancias EC2 en el hardware subyacente.

| Estrategia | Descripción | Pros | Contras | Caso de uso |
|-----------|-------------|------|---------|-------------|
| **Cluster** | Agrupa instancias en la **misma AZ, mismo rack** | Baja latencia de red (10 Gbps entre instancias), alto throughput | Si el rack falla, todas las instancias fallan | HPC, Big Data jobs, aplicaciones con comunicación inter-nodo intensa |
| **Spread** | Distribuye instancias en **hardware distinto** (diferentes racks) | Máximo aislamiento de fallos de hardware | **Máximo 7 instancias por AZ** por placement group | Aplicaciones críticas que necesitan alta disponibilidad |
| **Partition** | Distribuye instancias en **particiones lógicas** (cada partición en un rack diferente) | Aislamiento de fallos por partición. Hasta 7 particiones por AZ | Las instancias en la misma partición comparten hardware | HDFS, HBase, Cassandra, Kafka (sistemas distribuidos big data) |

### Diferencias clave

```
Cluster:     [Rack 1: i1, i2, i3, i4, i5]         -> Todo junto, rápido pero arriesgado

Spread:      [Rack 1: i1] [Rack 2: i2] [Rack 3: i3]  -> Separados, seguro pero limitado a 7/AZ

Partition:   [Rack 1: i1,i2,i3] [Rack 2: i4,i5,i6] [Rack 3: i7,i8,i9]  -> Grupos en racks separados
```

> **Tip para el examen:** Si preguntan por "baja latencia entre instancias" -> Cluster. Si preguntan "máximo aislamiento de hardware" -> Spread. Si preguntan "Kafka, HDFS, Cassandra con aislamiento" -> Partition.

---

## EC2 Networking

### ENI (Elastic Network Interface)

- Componente lógico de red en una VPC que representa una **tarjeta de red virtual**.
- Atributos: IP privada principal, IPs privadas secundarias, Elastic IP, IP pública, MAC address, Security Groups.
- Se puede **mover entre instancias** (en la misma AZ) para failover.
- Cada instancia tiene una ENI primaria (`eth0`) que no se puede desadjuntar.
- Puedes adjuntar ENIs adicionales para escenarios de multi-homing o gestión de red.

### ENA (Elastic Network Adapter)

- Proporciona **Enhanced Networking** usando SR-IOV (Single Root I/O Virtualization).
- Hasta **100 Gbps** de throughput.
- Mayor PPS (packets per second) y menor latencia que la interfaz estándar.
- Soportado en la mayoría de instancias modernas.
- **Sin coste adicional** (viene habilitado en tipos de instancia soportados).

### EFA (Elastic Fabric Adapter)

- Interfaz de red para **HPC (High Performance Computing)** y **machine learning** en EC2.
- Proporciona comunicación inter-nodo de baja latencia y alto throughput.
- Soporta **OS-bypass** que permite a la aplicación comunicarse directamente con el hardware de red (solo Linux).
- Utilizado con **MPI (Message Passing Interface)** para aplicaciones HPC.

### Resumen de networking

| Interfaz | Velocidad | Caso de uso |
|----------|-----------|-------------|
| **ENI** | Estándar | Uso general, failover de red, logging |
| **ENA** | Hasta 100 Gbps (enhanced networking) | Aplicaciones que necesitan alto throughput/bajo latencia |
| **EFA** | Máximo rendimiento + OS-bypass | HPC, machine learning distribuido |

---

## AMIs

### Qué es una AMI

Una **Amazon Machine Image (AMI)** es una plantilla que contiene la configuración de software (SO, aplicaciones, configuraciones) necesaria para lanzar una instancia.

### Tipos de AMI

| Tipo | Descripción |
|------|-------------|
| **AWS-provided** | AMIs oficiales mantenidas por AWS (Amazon Linux, Ubuntu, Windows Server) |
| **Marketplace** | AMIs de terceros (con o sin coste de licencia) |
| **Community** | AMIs compartidas por la comunidad (verificar seguridad) |
| **Custom (propia)** | AMIs creadas por ti a partir de una instancia configurada |

### Crear una AMI personalizada

1. Lanzar una instancia y configurarla (instalar software, aplicar parches).
2. Detener la instancia (recomendado para consistencia de datos).
3. Crear la AMI (AWS crea snapshots de los volúmenes EBS).
4. La AMI está disponible para lanzar nuevas instancias idénticas.

### Cross-Region Copy

- Las AMIs son **regionales** (solo disponibles en la región donde se crean).
- Puedes **copiar** una AMI a otra región para usarla allí.
- La copia incluye los snapshots EBS subyacentes.
- Las AMIs cifradas pueden copiarse entre regiones (con re-cifrado usando una KMS key de la región destino).

### AMI Sharing

- Puedes compartir una AMI con cuentas AWS específicas o hacerla pública.
- Si la AMI usa EBS cifrado con CMK, debes compartir la KMS key con la cuenta destino.
- Compartir una AMI **no copia** la AMI a la otra cuenta; se referencia desde la cuenta original.
- La otra cuenta puede copiar la AMI compartida a su propia cuenta (y re-cifrarla con su propia clave).

---

## User Data e Instance Metadata

### EC2 User Data

- Script que se ejecuta **una sola vez** al primer arranque de la instancia.
- Se ejecuta como **root** (con privilegios de administrador).
- Se usa para:
  - Instalar software y actualizaciones.
  - Descargar archivos de configuración.
  - Iniciar servicios.
  - Registrar la instancia en un servicio de descubrimiento.
- Máximo **16 KB** de tamaño.
- Accesible desde `http://169.254.169.254/latest/user-data`.

**Ejemplo de User Data:**

```bash
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "Hello from $(hostname -f)" > /var/www/html/index.html
```

### EC2 Instance Metadata (IMDS)

- Datos sobre la instancia accesibles desde la propia instancia.
- URL: `http://169.254.169.254/latest/meta-data/`
- Información disponible: instance-id, instance-type, AMI-id, hostname, IP local, IP pública, IAM role credentials, placement (AZ), security-groups, etc.

#### IMDSv1 vs IMDSv2

| Característica | IMDSv1 | IMDSv2 |
|---------------|--------|--------|
| **Método** | GET request simple | Requiere token de sesión (PUT + GET) |
| **Seguridad** | Vulnerable a SSRF (Server-Side Request Forgery) | Protegido contra SSRF |
| **Recomendación** | No recomendado | **Recomendado** (puede configurarse como obligatorio) |

**IMDSv2 - Flujo:**

```bash
# Paso 1: Obtener token (PUT)
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

# Paso 2: Usar token para consultar metadata (GET)
curl -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id
```

> **Tip para el examen:** Si la pregunta menciona protección contra SSRF o seguridad del metadata service, la respuesta es **IMDSv2**. Puedes hacer obligatorio IMDSv2 a nivel de instancia o a nivel de cuenta.

---

## Auto Scaling Groups

Un Auto Scaling Group (ASG) permite escalar automáticamente el número de instancias EC2 según la demanda.

### Componentes principales

| Componente | Descripción |
|-----------|-------------|
| **Launch Template** (recomendado) | Define la configuración de la instancia (AMI, tipo, SGs, User Data, IAM role, etc.) |
| **Launch Configuration** (legacy) | Similar al Launch Template pero sin versionado ni funcionalidades avanzadas |
| **Min/Max/Desired capacity** | Mínimo, máximo y número deseado de instancias |
| **Scaling Policies** | Reglas que definen cuándo escalar |
| **Health Checks** | EC2 (default) o ELB health checks |
| **Cooldown Period** | Tiempo de espera después de un scaling action antes de evaluar más acciones (default: 300s) |

### Launch Template vs Launch Configuration

| Característica | Launch Template | Launch Configuration |
|---------------|----------------|---------------------|
| **Versionado** | Sí | No |
| **Múltiples tipos de instancia** | Sí (mixed instances) | No |
| **Spot + On-Demand mix** | Sí | No |
| **Placement groups** | Sí | Limitado |
| **T2/T3 unlimited** | Sí | No |
| **Capacity Reservations** | Sí | No |
| **Recomendación** | **Usar siempre** | Legacy, no usar |

### Scaling Policies

#### 1. Target Tracking Scaling

- La más simple y recomendada.
- Define un **valor objetivo** para una métrica y el ASG ajusta la capacidad para mantener ese valor.
- Ejemplo: "Mantener el CPU promedio al 50%".
- Métricas predefinidas: `ASGAverageCPUUtilization`, `ASGAverageNetworkIn`, `ASGAverageNetworkOut`, `ALBRequestCountPerTarget`.
- También soporta métricas personalizadas de CloudWatch.

#### 2. Step Scaling

- Define acciones de escalado basadas en **umbrales de alarmas CloudWatch**.
- Permite definir múltiples pasos con diferentes acciones según la severidad.
- Ejemplo:
  - CPU > 70%: añadir 1 instancia.
  - CPU > 85%: añadir 3 instancias.
  - CPU < 30%: eliminar 1 instancia.
- Mayor control que Target Tracking pero más complejo de configurar.

#### 3. Scheduled Scaling

- Escala en momentos predefinidos (schedule).
- Basado en **cron expressions** o fecha/hora específica.
- Ejemplo: "Aumentar a 10 instancias todos los viernes a las 17:00" (para picos de tráfico conocidos).
- Ideal para patrones de tráfico predecibles y recurrentes.

#### 4. Predictive Scaling

- Usa **machine learning** para predecir tráfico futuro basado en patrones históricos.
- Analiza datos de los últimos 14 días de CloudWatch.
- Provisiona capacidad **proactivamente** antes de que llegue el pico de tráfico.
- Se combina bien con Target Tracking para ajustes en tiempo real.
- Ideal para cargas con patrones cíclicos (ej: tráfico diario, semanal).

### Lifecycle Hooks

- Permiten ejecutar acciones personalizadas cuando una instancia entra o sale del ASG.
- Estados:
  - `Pending:Wait` -> Instancia lanzándose (antes de ponerse en servicio).
  - `Terminating:Wait` -> Instancia terminando (antes de eliminarse).
- Caso de uso: Instalar software adicional, registrar en servicio externo, guardar logs antes de terminar.
- Timeout por defecto: 1 hora (configurable hasta 48 horas o heartbeat).

### Warm Pools

- Mantiene un pool de instancias pre-inicializadas en estado **Stopped** o **Running** (pero fuera de servicio).
- Cuando el ASG necesita escalar, usa instancias del warm pool en lugar de lanzar nuevas desde cero.
- Reduce significativamente el **tiempo de arranque** (boot time).
- Coste: las instancias en estado Stopped no incurren en coste de cómputo (solo EBS).

### Instance Refresh

- Permite actualizar todas las instancias del ASG con una nueva configuración (nueva AMI, nuevo launch template).
- Define un **minimum healthy percentage** (ej: 90%) para mantener disponibilidad durante la actualización.
- El ASG reemplaza instancias gradualmente respetando el porcentaje mínimo.

---

## AWS Lambda

AWS Lambda es un servicio de cómputo **serverless** que ejecuta código en respuesta a eventos sin aprovisionar ni gestionar servidores.

### Características principales

| Característica | Detalle |
|---------------|---------|
| **Lenguajes** | Node.js, Python, Java, Go, C#/.NET, Ruby, PowerShell, Custom Runtime (via Lambda Layers o container images) |
| **Memoria** | 128 MB a 10,240 MB (10 GB), en incrementos de 1 MB |
| **CPU** | Proporcional a la memoria configurada (a más memoria, más CPU) |
| **Timeout** | Máximo **15 minutos** (900 segundos) |
| **Almacenamiento efímero** | `/tmp` hasta **10 GB** |
| **Tamaño del paquete** | 50 MB (zip comprimido) o 250 MB (descomprimido). Hasta **10 GB** con container images |
| **Variables de entorno** | Máximo 4 KB en total |
| **Concurrencia** | 1,000 ejecuciones simultáneas por región (soft limit, incrementable) |
| **Modelo de precio** | Por número de invocaciones + duración (GB-segundo). Free tier: 1M requests + 400,000 GB-s/mes |

### Concurrencia

| Tipo | Descripción |
|------|-------------|
| **Unreserved Concurrency** | Pool compartido de concurrencia para todas las funciones de la cuenta |
| **Reserved Concurrency** | Reserva un número fijo de ejecuciones concurrentes para una función (sin coste extra). Limita la concurrencia máxima de esa función |
| **Provisioned Concurrency** | Pre-inicializa un número de entornos de ejecución para **eliminar cold starts**. Tiene coste adicional |

- **Cold Start**: Cuando Lambda debe inicializar un nuevo entorno de ejecución (descarga código, inicia runtime). Puede añadir latencia (ms a segundos, según runtime y tamaño del paquete).
- **Warm Start**: Reutiliza un entorno de ejecución existente. Mucho más rápido.

### Lambda Layers

- Paquetes de código o datos adicionales que se montan en `/opt` del entorno de ejecución.
- Permiten compartir librerías, SDKs, o dependencias entre funciones sin incluirlas en cada paquete.
- Máximo **5 layers** por función.
- Tamaño total (función + layers) no puede exceder 250 MB (descomprimido).

### Lambda y VPC

- Por defecto, Lambda se ejecuta **fuera de tu VPC** (en la VPC de AWS).
- Para acceder a recursos en tu VPC (RDS, ElastiCache, EC2): configura Lambda con una VPC, subnets y SGs.
- Lambda crea ENIs (Hyperplane ENIs) en las subnets especificadas.
- Para acceder a Internet desde Lambda en VPC: necesitas un **NAT Gateway** en una subnet pública.
- Para acceder a servicios AWS desde Lambda en VPC sin Internet: usa **VPC Endpoints**.

### Lambda Destinations

- Configuran a dónde enviar el resultado de una invocación (exitosa o fallida).
- Destinos soportados: SQS, SNS, Lambda, EventBridge.
- Alternativa recomendada a DLQ (Dead Letter Queue) para invocaciones asíncronas.
- **On Success**: Envía el resultado de la ejecución exitosa a un destino.
- **On Failure**: Envía información del error a un destino (similar a DLQ pero más flexible).

### Event Source Mappings

Lambda puede consumir eventos de servicios como SQS, Kinesis, DynamoDB Streams y otros sin intermediarios.

| Fuente | Tipo de lectura | Particularidades |
|--------|----------------|------------------|
| **SQS / SQS FIFO** | Polling (long polling) | Batch size configurable. Para FIFO: respeta el orden |
| **Kinesis Data Streams** | Polling del shard | Lee por shard. Soporta paralelización por shard |
| **DynamoDB Streams** | Polling del shard | Lee cambios en la tabla. Soporta paralelización |
| **Amazon MQ / MSK** | Polling | Consume mensajes del broker |

### Invocation Types

| Tipo | Descripción | Reintentos | Ejemplo |
|------|-------------|-----------|---------|
| **Synchronous** | Espera la respuesta | No (el caller maneja) | API Gateway, ALB, CloudFront |
| **Asynchronous** | No espera respuesta | 2 reintentos automáticos | S3 events, SNS, EventBridge, CloudWatch Events |
| **Event Source Mapping** | Lambda hace polling | Depende de la fuente | SQS, Kinesis, DynamoDB Streams |

---

## ECS vs EKS vs Fargate

### Amazon ECS (Elastic Container Service)

- Servicio de orquestación de contenedores **propio de AWS**.
- Ejecuta contenedores Docker en un **cluster**.
- Tipos de lanzamiento:
  - **EC2 Launch Type**: Tú gestionas las instancias EC2 del cluster.
  - **Fargate Launch Type**: AWS gestiona la infraestructura (serverless).
- Conceptos:
  - **Task Definition**: Plantilla JSON que describe los contenedores (imagen, CPU, memoria, puertos, volúmenes).
  - **Task**: Instancia en ejecución de una Task Definition.
  - **Service**: Mantiene un número deseado de Tasks corriendo y las registra en un Load Balancer.
  - **Cluster**: Agrupación lógica de tasks o services.

### Amazon EKS (Elastic Kubernetes Service)

- Servicio gestionado de **Kubernetes** en AWS.
- Compatible con el ecosistema Kubernetes (herramientas, plugins, operadores existentes).
- Tipos de nodos:
  - **Managed Node Groups**: AWS gestiona los nodos EC2.
  - **Self-managed nodes**: Tú gestionas los nodos EC2.
  - **Fargate**: Serverless (sin nodos que gestionar).
- El **control plane** (API server, etcd) es gestionado por AWS y distribuido en múltiples AZs.

### AWS Fargate

- Motor de cómputo **serverless** para contenedores.
- Funciona con **ECS** y **EKS**.
- No necesitas aprovisionar ni gestionar servidores.
- Pagas por los recursos (vCPU + memoria) que tus contenedores consumen.

### Tabla comparativa

| Característica | ECS (EC2) | ECS (Fargate) | EKS (EC2) | EKS (Fargate) |
|---------------|-----------|---------------|-----------|---------------|
| **Orquestador** | ECS (AWS nativo) | ECS (AWS nativo) | Kubernetes | Kubernetes |
| **Infraestructura** | Tú gestionas EC2 | Serverless | Tú gestionas EC2 | Serverless |
| **Portabilidad** | AWS lock-in | AWS lock-in | Multi-cloud/on-prem | AWS + K8s compatible |
| **Coste** | EC2 instances | Por vCPU + memoria del task | EC2 + EKS fee ($0.10/h) | vCPU + memoria + EKS fee |
| **Complejidad** | Baja | Muy baja | Alta (Kubernetes) | Media |
| **Escalado** | Service Auto Scaling + EC2 ASG | Service Auto Scaling | HPA/VPA + Cluster Autoscaler | HPA/VPA |
| **Acceso al SO** | Sí | No | Sí | No |
| **GPUs** | Sí | No | Sí | No |
| **Volúmenes persistentes** | EBS, EFS, FSx | EFS | EBS, EFS, FSx | EFS |
| **Ideal para** | Apps AWS-first, simples | Serverless containers sin K8s | Equipos con experiencia K8s | K8s serverless |

> **Tip para el examen:** Si la pregunta dice "Kubernetes" o "portabilidad multi-cloud" o "equipo con experiencia Kubernetes" -> EKS. Si dice "contenedores sin gestionar servidores" -> Fargate. Si dice "contenedores simples en AWS" -> ECS.

---

## Elastic Beanstalk

AWS Elastic Beanstalk es un servicio **PaaS** que facilita el despliegue y gestión de aplicaciones web, abstrayendo la infraestructura subyacente.

### Conceptos

| Concepto | Descripción |
|----------|-------------|
| **Application** | Colección lógica de componentes (environments, versions, configurations) |
| **Application Version** | Iteración específica del código de tu app (almacenada en S3) |
| **Environment** | Colección de recursos AWS que ejecutan una version de la app |
| **Environment Tier** | Web Server (HTTP requests) o Worker (procesa tareas de SQS) |

### Plataformas soportadas

- Go, Java, .NET, Node.js, PHP, Python, Ruby, Packer Builder, Docker (single/multi-container), Preconfigured Docker.

### Deployment Strategies

| Estrategia | Descripción | Downtime | Tiempo deploy | Rollback | Coste |
|-----------|-------------|----------|---------------|----------|-------|
| **All at Once** | Despliega en todas las instancias simultáneamente | **Sí** | Rápido | Re-deploy manual | Sin coste extra |
| **Rolling** | Despliega en batches. Cada batch se actualiza y vuelve a servicio | No (pero capacidad reducida) | Medio | Re-deploy manual | Sin coste extra |
| **Rolling with Additional Batch** | Como Rolling, pero lanza un batch extra primero para mantener capacidad completa | No | Medio-largo | Re-deploy manual | Coste del batch extra (temporal) |
| **Immutable** | Lanza instancias nuevas en un nuevo ASG, verifica health, y luego mueve al ASG original | No | Largo | Rápido (terminar nuevas instancias) | Coste doble (temporal) |
| **Traffic Splitting** | Como Immutable pero envía un % del tráfico a las nuevas instancias (canary) | No | Largo | Rápido | Coste doble (temporal) |
| **Blue/Green** | Crea un environment nuevo completo y cambia DNS (swap URL) | No | Largo | Swap URL de vuelta | Coste del environment extra |

### Diferencias clave entre estrategias

```
All at Once:      [v1,v1,v1,v1] -> [v2,v2,v2,v2]   (downtime momentáneo)

Rolling:          [v1,v1,v1,v1] -> [v2,v1,v1,v1] -> [v2,v2,v1,v1] -> [v2,v2,v2,v2]

Rolling+Batch:    [v1,v1,v1,v1] + [v2] -> [v2,v1,v1,v1,v2] -> ... -> [v2,v2,v2,v2]

Immutable:        [v1,v1,v1,v1] + nuevo ASG[v2,v2,v2,v2] -> merge -> [v2,v2,v2,v2]

Blue/Green:       env-blue[v1] | env-green[v2] -> swap URL -> env-green[v2] activo
```

### Beanstalk con Docker

- **Single Docker**: Una sola instancia con un contenedor Docker. No necesita ECS.
- **Multi-Docker**: Múltiples contenedores por instancia. Usa **ECS** bajo el capó. Requiere un `Dockerrun.aws.json` (v2).

> **Tip para el examen:** Si preguntan por "despliegue más rápido" -> All at Once (pero tiene downtime). Si preguntan "sin downtime y rollback rápido" -> Immutable o Blue/Green. Rolling with Additional Batch si quieres mantener capacidad completa sin coste doble prolongado.

---

## AWS Batch

AWS Batch permite ejecutar **trabajos de procesamiento por lotes** (batch jobs) a cualquier escala de forma eficiente.

### Conceptos

| Concepto | Descripción |
|----------|-------------|
| **Job** | Unidad de trabajo que se envía a AWS Batch (shell script, contenedor Docker) |
| **Job Definition** | Plantilla que define cómo ejecutar un job (imagen Docker, vCPU, memoria, variables de entorno, IAM role) |
| **Job Queue** | Cola donde se envían los jobs. Asociada a uno o más Compute Environments con prioridades |
| **Compute Environment** | Recursos de cómputo que ejecutan los jobs. Managed (AWS gestiona EC2/Spot) o Unmanaged (tú gestionas) |

### Batch vs Lambda

| Característica | AWS Batch | AWS Lambda |
|---------------|-----------|------------|
| **Duración** | Sin límite | Máximo 15 minutos |
| **Runtime** | Cualquier (contenedor Docker) | Runtimes soportados |
| **Almacenamiento** | Volúmenes EBS montados | 10 GB en /tmp |
| **Servidor** | EC2 (gestionadas por Batch) o Fargate | Serverless |
| **Inicio** | Depende (puede tardar en aprovisionar EC2) | Rápido (cold start: segundos) |
| **Caso de uso** | Procesamiento largo, intensivo en recursos | Procesamiento corto, event-driven |

> **Tip para el examen:** Si el procesamiento dura más de 15 minutos o necesita más de 10 GB de disco, no puede ser Lambda. Usa **AWS Batch**. Batch es ideal para ETL masivos, rendering de video, simulaciones científicas.

---

## AWS Outposts, Wavelength y Local Zones

### AWS Outposts

- Racks de hardware de AWS instalados en tu **data center on-premises**.
- Ejecutan los mismos servicios de AWS con las mismas APIs, herramientas y el mismo control plane.
- **Servicios disponibles**: EC2, EBS, S3 (Outposts), ECS, EKS, RDS, EMR.
- Los datos pueden residir **localmente** en el Outpost.
- El **control plane** sigue operando desde la Región de AWS (necesita conectividad).
- Caso de uso: Residencia de datos local, baja latencia a sistemas on-premises, procesamiento local.

### AWS Wavelength

- Infraestructura AWS embebida en las **redes 5G de teleoperadores**.
- Las **Wavelength Zones** están dentro del data center del operador de telecomunicaciones.
- Proporciona latencia de **un dígito de milisegundos** desde dispositivos 5G.
- Servicios disponibles: EC2, EBS, VPC, ECS, EKS, Lambda.
- Caso de uso: Aplicaciones de realidad aumentada, gaming, streaming en tiempo real, IoT desde dispositivos 5G.
- Las instancias en Wavelength Zones se conectan a la Región padre a través de la red del carrier.

### AWS Local Zones

- Extensiones de una Región de AWS colocadas **cerca de grandes ciudades**.
- Proporcionan cómputo, almacenamiento y otros servicios con baja latencia.
- Se conectan a la Región padre a través de la red dedicada de AWS.
- Servicios disponibles: EC2, EBS, Amazon FSx, ELB, Amazon ECS, etc.
- Caso de uso: Aplicaciones sensibles a latencia (gaming, media/entertainment, live streaming) en ciudades donde no hay una Región de AWS cercana.

### Comparación

| Característica | Outposts | Wavelength | Local Zones |
|---------------|----------|------------|-------------|
| **Ubicación** | Tu data center | Red del operador 5G | Cerca de grandes ciudades |
| **Latencia** | Mínima a tu infra on-prem | Ultra baja desde 5G | Baja desde la ciudad |
| **Hardware** | Racks de AWS en tus instalaciones | Infraestructura AWS en el operador | Data centers de AWS |
| **Gestión** | AWS mantiene el hardware | AWS mantiene todo | AWS mantiene todo |
| **Conectividad** | Via red al data center de la Región AWS | Via red del carrier a la Región | Via red AWS a la Región |
| **Caso de uso** | Residencia de datos, legacy on-prem | Apps 5G en tiempo real | Apps sensibles a latencia en ciudades |

---

## Compute Exam Tips

### EC2

- Conocer las familias: **C** (Compute), **R** (RAM/Memory), **I/D/H** (Storage), **P/G** (GPU/Accelerated), **M/T** (General).
- **T instances** son burstable. Si agotan créditos en modo `standard`, rendimiento se degrada. En `unlimited`, se cobra extra.
- Naming: `m5a.xlarge` -> m=familia, 5=generación, a=AMD, xlarge=tamaño.

### Purchasing

- **On-Demand**: Sin compromiso. Para cargas impredecibles.
- **Reserved**: 1-3 años. Hasta 72% descuento. Para cargas estables.
- **Savings Plans**: Más flexibles que RI. Compromiso en $/hora.
- **Spot**: Hasta 90% descuento. Puede interrumpirse. Para cargas tolerantes a fallos.
- **Dedicated Hosts**: Para licencias BYOL (por socket/core).
- **Capacity Reservations**: Garantizar capacidad en AZ. Sin descuento.

### Placement Groups

- **Cluster**: Mismo rack, baja latencia (HPC). No puede abarcar AZs.
- **Spread**: Hardware diferente, max 7 instancias/AZ. Alta disponibilidad.
- **Partition**: Racks separados por partición. Big data distribuido (Kafka, HDFS).

### Networking

- **ENI**: Interfaz de red básica. Movible entre instancias para failover.
- **ENA**: Enhanced Networking (100 Gbps). Sin coste extra.
- **EFA**: Para HPC y ML distribuido. OS-bypass (solo Linux).

### AMIs y Bootstrap

- Las AMIs son regionales. Se pueden copiar cross-region.
- **User Data** se ejecuta una sola vez al primer boot. Corre como root.
- **IMDSv2** es más seguro (contra SSRF). Se accede con token.

### Auto Scaling

- Usar **Launch Templates** (no Launch Configurations).
- **Target Tracking**: La más simple ("mantén CPU al 50%").
- **Predictive Scaling**: ML para anticipar patrones.
- **Cooldown**: Evita escalados prematuros (default 300s).
- **Warm Pools**: Instancias pre-inicializadas para arranque rápido.

### Lambda

- **15 minutos** de timeout máximo. Si necesitas más, usa Batch, ECS o Step Functions.
- **10 GB** de almacenamiento efímero en /tmp.
- **Provisioned Concurrency** elimina cold starts (con coste).
- En VPC: necesita NAT Gateway para acceder a Internet, o VPC Endpoints para servicios AWS.
- **Destinations**: Reemplazo moderno de DLQ para invocaciones asíncronas.
- Pago por número de invocaciones + duración en GB-s.

### Contenedores

- **ECS**: Orquestador nativo de AWS. Simple. Para equipos AWS-first.
- **EKS**: Kubernetes gestionado. Para equipos con experiencia K8s o requisitos de portabilidad.
- **Fargate**: Serverless para contenedores. Sin gestionar infraestructura. Funciona con ECS y EKS.
- Si la pregunta dice "sin gestionar servidores" para contenedores -> **Fargate**.
- Si dice "Kubernetes" -> **EKS**.

### Beanstalk

- **All at Once**: Rápido pero con downtime.
- **Rolling**: Sin downtime pero capacidad reducida.
- **Rolling with Additional Batch**: Capacidad completa durante deploy.
- **Immutable**: Rollback rápido, instancias nuevas.
- **Blue/Green**: Environments separados, swap URL.
- Beanstalk crea y gestiona los recursos (EC2, ALB, ASG, RDS, etc.) pero tú tienes control total sobre ellos.

### Batch

- Para procesamiento largo (sin límite de tiempo, a diferencia de los 15 min de Lambda).
- Puede usar **Spot Instances** para reducir costes.
- Usa contenedores Docker.
- AWS gestiona la infraestructura de cómputo (Managed Compute Environment).

### Edge Computing

- **Outposts** = AWS en tu data center (residencia de datos, latencia a on-prem).
- **Wavelength** = AWS en redes 5G (latencia ultra baja desde dispositivos 5G).
- **Local Zones** = AWS cerca de ciudades (latencia baja para aplicaciones en ciudades sin Región cercana).
