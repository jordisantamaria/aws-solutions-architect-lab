# Fundamentos de Cloud Computing y AWS

## Tabla de Contenidos

- [Qué es Cloud Computing](#qué-es-cloud-computing)
- [AWS Global Infrastructure](#aws-global-infrastructure)
- [Cómo elegir una Región](#cómo-elegir-una-región)
- [AWS Well-Architected Framework](#aws-well-architected-framework)
- [Shared Responsibility Model](#shared-responsibility-model)
- [AWS Support Plans](#aws-support-plans)
- [Pricing Fundamentals](#pricing-fundamentals)
- [Key Points para el Examen](#key-points-para-el-examen)

---

## Qué es Cloud Computing

### Definición NIST

El National Institute of Standards and Technology (NIST) define cloud computing como un modelo que permite el acceso ubicuo, conveniente y bajo demanda a un conjunto compartido de recursos informáticos configurables (redes, servidores, almacenamiento, aplicaciones y servicios) que pueden ser rápidamente aprovisionados y liberados con un esfuerzo mínimo de gestión o interacción del proveedor de servicios.

### Cinco características esenciales (NIST)

1. **Autoservicio bajo demanda** - El usuario aprovisiona recursos sin interacción humana con el proveedor.
2. **Acceso amplio a la red** - Los recursos están disponibles a través de la red mediante mecanismos estándar.
3. **Pool de recursos compartido** - Los recursos del proveedor se agrupan para servir a múltiples consumidores (multi-tenant).
4. **Elasticidad rápida** - Los recursos pueden aprovisionarse y liberarse elásticamente, a veces de forma automática.
5. **Servicio medido** - El uso de recursos se monitoriza, controla y se reporta de forma transparente.

### Modelos de Servicio

| Modelo | Descripción | Tú gestionas | AWS gestiona | Ejemplo AWS |
|--------|-------------|---------------|--------------|-------------|
| **IaaS** (Infrastructure as a Service) | Infraestructura básica virtualizada | SO, apps, datos, middleware, runtime | Hardware, red, virtualización | EC2, VPC, EBS |
| **PaaS** (Platform as a Service) | Plataforma para desarrollar y desplegar apps | Código de aplicación y datos | SO, middleware, runtime, infraestructura | Elastic Beanstalk, RDS, Lambda |
| **SaaS** (Software as a Service) | Aplicación completa gestionada | Solo uso y configuración | Todo lo demás | Amazon WorkMail, Amazon Chime |

### Modelos de Despliegue

| Modelo | Descripción | Caso de uso |
|--------|-------------|-------------|
| **Cloud Público** | Recursos propiedad del proveedor cloud, entregados por internet | Startups, aplicaciones web escalables |
| **Cloud Privado** | Infraestructura cloud exclusiva de una organización | Regulaciones estrictas, control total |
| **Cloud Híbrido** | Combinación de cloud público y privado/on-premises | Migración gradual, datos sensibles on-prem |

---

## AWS Global Infrastructure

### Regions (Regiones)

- Una **Región** es un área geográfica que contiene múltiples Availability Zones.
- Cada Región está completamente aislada de las demás para lograr la máxima tolerancia a fallos.
- La mayoría de los servicios de AWS son **regionales** (los datos no se replican automáticamente entre regiones).
- Actualmente hay más de 30 regiones a nivel global.

### Availability Zones (AZs)

- Cada Región tiene **mínimo 2 AZs** (generalmente 3, algunas tienen hasta 6).
- Cada AZ es uno o más data centers discretos con energía, red y conectividad redundantes.
- Las AZs dentro de una Región están conectadas con redes de **baja latencia, alto throughput y alta redundancia**.
- Están físicamente separadas (distancia significativa) para proteger contra desastres locales.
- Se identifican con un código de región + letra (ej: `eu-west-1a`, `eu-west-1b`).

> **Importante para el examen:** Las letras de AZ se mapean de forma distinta por cuenta. La AZ `us-east-1a` de tu cuenta puede no ser el mismo data center que `us-east-1a` de otra cuenta. Usa los **AZ IDs** (ej: `use1-az1`) para identificar de forma consistente.

### Edge Locations

- Son puntos de presencia (PoP) distribuidos mundialmente (más de 400+).
- Usados por **CloudFront** (CDN) y **Route 53** (DNS).
- Permiten servir contenido con baja latencia a los usuarios finales.
- También usados por **AWS WAF** y **AWS Shield** para protección DDoS.
- Los **Regional Edge Caches** son un nivel intermedio entre el Origin y las Edge Locations.

### Local Zones

- Extensiones de una Región que colocan servicios de cómputo, almacenamiento y base de datos más cerca de grandes centros de población.
- Proporcionan latencia de un solo dígito de milisegundos para aplicaciones sensibles a la latencia.
- Ejemplo: `us-east-1-bos-1a` (Boston Local Zone de us-east-1).
- Ideal para gaming, streaming en tiempo real, machine learning inference.

### AWS Wavelength

- Infraestructura AWS embebida dentro de las redes 5G de operadores de telecomunicaciones.
- Latencia ultra baja para aplicaciones móviles.
- Caso de uso: aplicaciones que necesitan latencia de un solo dígito de milisegundos desde dispositivos 5G.

### AWS Outposts

- Hardware de AWS instalado en tu propio data center on-premises.
- Ofrece los mismos servicios, APIs y herramientas de AWS en tu infraestructura.
- Para cargas de trabajo que requieren baja latencia al sistema on-premises o residencia de datos local.

---

## Cómo elegir una Región

Al seleccionar una Región de AWS, considera estos cuatro factores (en orden de prioridad habitual):

| Factor | Descripción | Ejemplo |
|--------|-------------|---------|
| **Compliance / Cumplimiento normativo** | Requisitos legales sobre dónde deben residir los datos | GDPR exige datos de ciudadanos UE en la UE; datos del gobierno francés deben estar en Francia |
| **Latencia / Proximidad a usuarios** | Elegir la región más cercana a los usuarios finales | App para usuarios en España -> `eu-west-1` (Irlanda) o `eu-south-2` (España) |
| **Servicios disponibles** | No todos los servicios están disponibles en todas las regiones | Nuevos servicios suelen lanzarse primero en `us-east-1` |
| **Coste** | Los precios varían entre regiones | São Paulo suele ser más caro que Virginia |

> **Tip para el examen:** Si una pregunta menciona requisitos de compliance o regulación, **siempre** prioriza la región que cumple esos requisitos, incluso si no es la más barata o cercana.

---

## AWS Well-Architected Framework

El Well-Architected Framework proporciona un enfoque consistente para evaluar arquitecturas y orientaciones para implementar diseños que escalen con el tiempo. Consta de **6 pilares**:

### 1. Excelencia Operativa (Operational Excellence)

- **Objetivo:** Ejecutar y monitorizar sistemas para entregar valor de negocio y mejorar continuamente procesos y procedimientos.
- **Principios clave:**
  - Realizar operaciones como código (IaC).
  - Hacer cambios frecuentes, pequeños y reversibles.
  - Refinar procedimientos operativos frecuentemente.
  - Anticipar fallos y aprender de todos los fallos operacionales.
- **Servicios clave:** CloudFormation, AWS Config, CloudWatch, CloudTrail, X-Ray.

### 2. Seguridad (Security)

- **Objetivo:** Proteger datos, sistemas y activos mediante evaluaciones de riesgo y estrategias de mitigación.
- **Principios clave:**
  - Implementar una base de identidad sólida (least privilege).
  - Habilitar trazabilidad.
  - Aplicar seguridad en todas las capas.
  - Automatizar las mejores prácticas de seguridad.
  - Proteger datos en tránsito y en reposo.
  - Mantener a las personas alejadas de los datos.
  - Prepararse para eventos de seguridad.
- **Servicios clave:** IAM, KMS, CloudTrail, GuardDuty, WAF, Shield, Macie.

### 3. Fiabilidad (Reliability)

- **Objetivo:** Asegurar que un sistema pueda recuperarse de fallos de infraestructura o servicio, adquirir dinámicamente recursos para satisfacer la demanda y mitigar disrupciones.
- **Principios clave:**
  - Probar procedimientos de recuperación automáticamente.
  - Recuperarse automáticamente de fallos.
  - Escalar horizontalmente para aumentar disponibilidad.
  - Dejar de adivinar capacidad.
  - Gestionar el cambio a través de automatización.
- **Servicios clave:** Auto Scaling, CloudWatch, Route 53, S3, RDS Multi-AZ, Backup.

### 4. Eficiencia del Rendimiento (Performance Efficiency)

- **Objetivo:** Usar los recursos informáticos de forma eficiente para satisfacer los requisitos del sistema y mantener esa eficiencia a medida que la demanda cambia y las tecnologías evolucionan.
- **Principios clave:**
  - Democratizar tecnologías avanzadas (usar servicios gestionados).
  - Ir global en minutos.
  - Usar arquitecturas serverless.
  - Experimentar con más frecuencia.
  - Tener afinidad mecánica (usar la tecnología adecuada para cada caso).
- **Servicios clave:** Auto Scaling, Lambda, ECS/EKS, ElastiCache, CloudFront, Global Accelerator.

### 5. Optimización de Costes (Cost Optimization)

- **Objetivo:** Ejecutar sistemas para entregar valor de negocio al coste más bajo posible.
- **Principios clave:**
  - Implementar Cloud Financial Management.
  - Adoptar un modelo de consumo (pagar solo por lo que usas).
  - Medir la eficiencia general.
  - Dejar de gastar dinero en trabajo indiferenciado (usar servicios gestionados).
  - Analizar y atribuir gastos.
- **Servicios clave:** Cost Explorer, Budgets, Reserved Instances, Savings Plans, S3 Intelligent-Tiering, Trusted Advisor.

### 6. Sostenibilidad (Sustainability)

- **Objetivo:** Minimizar el impacto ambiental de la ejecución de cargas de trabajo en la nube.
- **Principios clave:**
  - Comprender el impacto.
  - Establecer objetivos de sostenibilidad.
  - Maximizar la utilización.
  - Anticipar y adoptar nuevas ofertas de hardware/software más eficientes.
  - Usar servicios gestionados.
  - Reducir el impacto posterior de las cargas de trabajo en la nube.
- **Servicios clave:** EC2 Auto Scaling (right-sizing), Graviton instances, S3 lifecycle policies, Lambda.

---

## Shared Responsibility Model

El modelo de responsabilidad compartida define qué gestiona AWS y qué gestionas tú como cliente. Es uno de los conceptos **más preguntados** en el examen.

### Regla general

- **AWS es responsable de la seguridad "DE" la nube** (infraestructura).
- **El cliente es responsable de la seguridad "EN" la nube** (datos, configuración).

### Desglose detallado

| Capa | AWS gestiona | El cliente gestiona |
|------|-------------|-------------------|
| **Infraestructura física** | Data centers, hardware, red global, energía, refrigeración | - |
| **Infraestructura de red** | Red física, switches, routers | Configuración de Security Groups, NACLs, Route Tables |
| **Virtualización** | Hipervisor, aislamiento entre instancias | - |
| **Sistema Operativo** | SO del host (hipervisor) | SO del guest (parches, actualizaciones en EC2) |
| **Aplicaciones** | Servicios gestionados (RDS engine, Lambda runtime) | Código de aplicación, configuración de aplicaciones |
| **Datos** | Durabilidad del almacenamiento (S3 11 9s) | Cifrado de datos, clasificación, backups, permisos de acceso |
| **Identidad** | Infraestructura de IAM | Gestión de usuarios, MFA, políticas, rotación de claves |

### Ejemplos por servicio

| Servicio | Responsabilidad de AWS | Responsabilidad del cliente |
|----------|----------------------|---------------------------|
| **EC2** | Hardware, hipervisor, red física | Parches SO, firewall (SGs), IAM roles, cifrado datos |
| **RDS** | Hardware, SO, parches de DB engine, backups automáticos | Security Groups, políticas IAM, cifrado datos, gestión usuarios DB |
| **S3** | Infraestructura, durabilidad, disponibilidad | Bucket policies, ACLs, cifrado, versionado, lifecycle |
| **Lambda** | Todo lo de infraestructura + runtime + parches | Código de función, IAM roles, configuración de VPC |

> **Tip para el examen:** Cuanto más "gestionado" es el servicio, más responsabilidades asume AWS. Lambda/Fargate = AWS gestiona casi todo. EC2 = tú gestionas el SO y aplicación.

---

## AWS Support Plans

| Característica | Basic | Developer | Business | Enterprise On-Ramp | Enterprise |
|---------------|-------|-----------|----------|-------------------|------------|
| **Coste** | Gratis | Desde $29/mes | Desde $100/mes | Desde $5,500/mes | Desde $15,000/mes |
| **Trusted Advisor** | 7 checks básicos | 7 checks básicos | Todos los checks | Todos los checks | Todos los checks |
| **Soporte técnico** | No | 1 contacto, horario laboral | Contactos ilimitados, 24/7 | Contactos ilimitados, 24/7 | Contactos ilimitados, 24/7 |
| **Severidad General** | - | < 24h laborables | < 24h | < 24h | < 24h |
| **Severidad Sistema afectado** | - | < 12h laborables | < 12h | < 12h | < 12h |
| **Severidad Sistema producción afectado** | - | - | < 4h | < 4h | < 4h |
| **Severidad Sistema producción caído** | - | - | < 1h | < 1h | < 1h |
| **Severidad Business-critical caído** | - | - | - | < 30 min | < 15 min |
| **Technical Account Manager (TAM)** | No | No | No | Pool de TAMs | TAM designado |
| **Concierge Support Team** | No | No | No | No | Sí |
| **Infrastructure Event Management** | No | No | Por coste adicional | 1 por año incluido | Incluido |
| **Well-Architected Reviews** | No | No | No | Sí | Sí |
| **API de AWS Support** | No | No | Sí | Sí | Sí |

> **Tip para el examen:** Si preguntan sobre "TAM" o "Technical Account Manager", la respuesta es Enterprise. Si preguntan por "todos los checks de Trusted Advisor", es Business o superior.

---

## Pricing Fundamentals

### Modelos de compra para EC2

| Modelo | Descripción | Descuento vs On-Demand | Compromiso | Ideal para |
|--------|-------------|----------------------|------------|------------|
| **On-Demand** | Paga por hora o segundo sin compromiso | 0% (precio base) | Ninguno | Cargas impredecibles, desarrollo, pruebas |
| **Reserved Instances (RI)** | Reserva de capacidad por 1 o 3 años | Hasta ~72% | 1 o 3 años | Cargas estables y predecibles (bases de datos) |
| **Savings Plans** | Compromiso de gasto por hora en $/h | Hasta ~72% | 1 o 3 años | Flexibilidad entre tipos/regiones/servicios |
| **Spot Instances** | Capacidad sobrante de AWS al mejor precio | Hasta ~90% | Ninguno (puede interrumpirse) | Cargas tolerantes a fallos (batch, CI/CD, HPC) |
| **Dedicated Hosts** | Servidor físico dedicado exclusivamente | Varía | Ninguno u On-Demand o Reservado | Licencias BYOL, compliance |
| **Dedicated Instances** | Instancia en hardware dedicado a tu cuenta | Varía | Ninguno | Aislamiento a nivel de hardware |
| **Capacity Reservations** | Reserva de capacidad en una AZ específica | 0% (pagas On-Demand) | Ninguno | Garantizar capacidad para eventos |

### Tipos de Reserved Instances

| Tipo | Flexibilidad | Descuento |
|------|-------------|-----------|
| **Standard RI** | Tipo de instancia fijo | Mayor descuento (hasta ~72%) |
| **Convertible RI** | Puedes cambiar tipo de instancia | Menor descuento (hasta ~54%) |

### Opciones de pago para RI

| Opción | Descripción | Descuento |
|--------|-------------|-----------|
| **All Upfront** | Pago total adelantado | Mayor descuento |
| **Partial Upfront** | Pago parcial adelantado + mensual | Descuento medio |
| **No Upfront** | Sin pago adelantado, solo mensual | Menor descuento |

### Savings Plans - Tipos

| Tipo | Cobertura | Flexibilidad |
|------|-----------|-------------|
| **Compute Savings Plans** | EC2, Lambda, Fargate | Máxima flexibilidad (cualquier región, familia, SO, tenancy) |
| **EC2 Instance Savings Plans** | Solo EC2 | Fijo a familia de instancia y región, flexible en SO/tenancy/tamaño |
| **SageMaker Savings Plans** | Solo SageMaker | Flexible en tipo de instancia, región y componente |

### Principios generales de pricing en AWS

1. **Paga solo por lo que usas** - Sin costes iniciales (excepto RI upfront).
2. **Paga menos al usar más** - Descuentos por volumen (ej: S3 storage tiers).
3. **Paga menos al reservar** - Compromisos a largo plazo tienen descuento.
4. **Transferencia de datos** - Inbound es gratis. Outbound tiene coste (inter-region > inter-AZ > intra-AZ). Intra-AZ con IP privada es gratis.

---

## Key Points para el Examen

### Cloud Fundamentals
- Conocer los 5 atributos de cloud computing según NIST.
- Diferenciar IaaS, PaaS y SaaS con ejemplos concretos de servicios AWS.
- Entender que cloud híbrido = on-premises + cloud público.

### Global Infrastructure
- Región > AZ > Data Center. Mínimo 2 AZs por región.
- Edge Locations son para CloudFront y Route 53 (no confundir con AZs).
- Local Zones = baja latencia a ciudades específicas.
- Wavelength = latencia ultra baja en redes 5G.

### Well-Architected Framework
- Memorizar los 6 pilares y sus principios clave.
- Preguntas frecuentes sobre cuál pilar aplica a un escenario dado.
- Sostenibilidad fue el pilar más reciente en añadirse (diciembre 2021).

### Shared Responsibility Model
- "Seguridad DE la nube" (AWS) vs "Seguridad EN la nube" (cliente).
- Si el examen pregunta quién parchea el SO de una instancia EC2 -> cliente.
- Si pregunta quién parchea el motor de base de datos en RDS -> AWS.
- Cifrado de datos es **siempre** responsabilidad del cliente (aunque AWS proporciona las herramientas).

### Support Plans
- TAM = solo Enterprise.
- Trusted Advisor completo = Business o superior.
- Respuesta en 15 minutos para business-critical = solo Enterprise.
- Concierge = solo Enterprise.

### Pricing
- Spot puede dar hasta 90% de descuento pero puede interrumpirse con 2 minutos de aviso.
- Reserved Instances: 1 o 3 años, Standard no cambia tipo, Convertible sí.
- Savings Plans: más flexibles que RI, compromiso en $/hora.
- Data transfer entre AZs tiene coste. Usar IP privada dentro de la misma AZ es gratis.
- Dedicated Hosts es necesario para licencias BYOL (Bring Your Own License).
