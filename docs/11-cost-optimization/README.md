# 11 - Optimización de Costes en AWS

## Tabla de Contenidos

- [EC2 Pricing Deep Dive](#ec2-pricing-deep-dive)
- [Cuándo Usar Cada Modelo de Precio](#cuándo-usar-cada-modelo-de-precio)
- [S3 Cost Optimization](#s3-cost-optimization)
- [Costes de Transferencia de Datos](#costes-de-transferencia-de-datos)
- [AWS Cost Explorer](#aws-cost-explorer)
- [AWS Budgets](#aws-budgets)
- [AWS Cost and Usage Report (CUR)](#aws-cost-and-usage-report-cur)
- [AWS Compute Optimizer](#aws-compute-optimizer)
- [Rightsizing](#rightsizing)
- [Savings Plans vs Reserved Instances](#savings-plans-vs-reserved-instances)
- [Estrategias Spot](#estrategias-spot)
- [AWS Organizations: Facturación Consolidada](#aws-organizations-facturación-consolidada)
- [Estrategia de Tagging para Asignación de Costes](#estrategia-de-tagging-para-asignación-de-costes)
- [Tips para el Examen](#tips-para-el-examen)

---

## EC2 Pricing Deep Dive

### Modelos de precio

#### 1. On-Demand

- **Pago por uso:** Se cobra por segundo (mínimo 60 segundos) para Linux, por hora para Windows.
- **Sin compromiso:** Se puede iniciar y detener en cualquier momento.
- **Precio más alto** por hora, pero máxima flexibilidad.
- **Caso de uso:** Cargas de trabajo impredecibles, desarrollo/testing, aplicaciones de corta duración.

#### 2. Reserved Instances (RI)

| Característica | Standard RI | Convertible RI |
|---|---|---|
| **Descuento** | Hasta ~72% vs On-Demand | Hasta ~66% vs On-Demand |
| **Plazo** | 1 o 3 años | 1 o 3 años |
| **Cambiar tipo de instancia** | No (misma familia, se puede cambiar tamaño en la misma familia con Instance Size Flexibility) | Sí (se puede cambiar familia, SO, tenancy, etc.) |
| **Vender en Marketplace** | Sí | No |
| **Pago** | All Upfront / Partial Upfront / No Upfront | All Upfront / Partial Upfront / No Upfront |
| **Descuento máximo** | All Upfront + 3 años | All Upfront + 3 años |

**Opciones de pago y descuento relativo:**

| Opción de pago | Descuento relativo |
|---|---|
| **All Upfront** | Mayor descuento (todo por adelantado) |
| **Partial Upfront** | Descuento intermedio (parte adelantada + mensualidad reducida) |
| **No Upfront** | Menor descuento (sin pago inicial, mensualidad fija) |

#### 3. Savings Plans

| Tipo | Descripción | Flexibilidad | Descuento |
|---|---|---|---|
| **Compute Savings Plans** | Compromiso de gasto por hora ($/hora) aplicable a EC2, Fargate y Lambda | Máxima: cualquier familia, región, SO, tenancy | Hasta ~66% |
| **EC2 Instance Savings Plans** | Compromiso de gasto por hora para una familia de instancias en una región específica | Media: familia y región fijas, flexible en tamaño, SO, tenancy | Hasta ~72% |
| **SageMaker Savings Plans** | Compromiso de gasto por hora para SageMaker | Específico para ML | Hasta ~64% |

#### 4. Spot Instances

- **Descuento:** Hasta ~90% vs On-Demand.
- **Riesgo:** AWS puede recuperar la instancia con **2 minutos de aviso** cuando necesita la capacidad.
- **Precio variable:** El precio Spot fluctúa según la oferta/demanda de capacidad EC2.
- **Caso de uso:** Cargas de trabajo tolerantes a interrupciones (batch processing, CI/CD, análisis de datos, renderizado).
- **No usar para:** Bases de datos, aplicaciones stateful críticas, cargas que no pueden tolerar interrupciones.

#### 5. Dedicated

| Tipo | Descripción | Caso de uso |
|---|---|---|
| **Dedicated Instances** | Instancias en hardware dedicado a tu cuenta, pero sin control sobre la colocación | Requisitos de compliance que prohíben multi-tenancy |
| **Dedicated Hosts** | Servidor físico completo dedicado a tu cuenta con control de colocación y visibilidad de sockets/cores | Licencias de software vinculadas a hardware (BYOL), compliance estricto |

**Diferencia clave:** Dedicated Hosts dan visibilidad y control del servidor físico (necesario para licencias por socket/core). Dedicated Instances solo garantizan hardware dedicado.

---

## Cuándo Usar Cada Modelo de Precio

### Tabla de decisión

| Pregunta | Respuesta | Modelo recomendado |
|---|---|---|
| Carga de trabajo impredecible, corta duración | Sí | **On-Demand** |
| Carga estable, conocida, 1-3 años | Sí, y sé la familia de instancia | **EC2 Instance Savings Plan** o **Standard RI** |
| Carga estable, puede cambiar de tipo de instancia | Sí | **Compute Savings Plan** o **Convertible RI** |
| Tolerante a interrupciones, flexible | Sí | **Spot** |
| Necesita máximo descuento sin riesgo | Sí | **Standard RI 3 años All Upfront** |
| Licencias BYOL por socket/core | Sí | **Dedicated Host** |
| Compliance de hardware dedicado | Sí | **Dedicated Instance** o **Dedicated Host** |
| Usa EC2 + Fargate + Lambda | Sí | **Compute Savings Plan** |
| Solo usa EC2 en una familia específica | Sí | **EC2 Instance Savings Plan** |

### Diagrama de decisión

```
¿Carga predecible a largo plazo?
  │
  ├── SÍ ──► ¿Necesitas flexibilidad de tipo de instancia?
  │            ├── SÍ ──► Compute Savings Plan / Convertible RI
  │            └── NO ──► EC2 Instance Savings Plan / Standard RI
  │
  └── NO ──► ¿Tolerante a interrupciones?
               ├── SÍ ──► Spot Instances
               └── NO ──► On-Demand
```

---

## S3 Cost Optimization

### Clases de almacenamiento S3 (de mayor a menor coste por GB)

| Clase | Coste almacenamiento | Coste acceso | Disponibilidad | Duración mínima | Caso de uso |
|---|---|---|---|---|---|
| **S3 Standard** | Alto | Bajo | 99.99% | Ninguna | Datos accedidos frecuentemente |
| **S3 Intelligent-Tiering** | Variable (auto) | Monitoreo por objeto | 99.9% | 30 días | Patrones de acceso impredecibles |
| **S3 Standard-IA** | Medio-bajo | Medio | 99.9% | 30 días | Datos accedidos < 1 vez/mes |
| **S3 One Zone-IA** | Bajo | Medio | 99.5% (1 AZ) | 30 días | Datos recreables, acceso infrecuente |
| **S3 Glacier Instant Retrieval** | Muy bajo | Alto | 99.9% | 90 días | Archivos con acceso inmediato trimestral |
| **S3 Glacier Flexible Retrieval** | Muy bajo | Alto + coste retrieval | 99.99% | 90 días | Archivos con acceso en minutos-horas |
| **S3 Glacier Deep Archive** | Mínimo | Muy alto + coste retrieval | 99.99% | 180 días | Archivos regulatorios, acceso en 12-48 horas |

### Lifecycle Policies

Reglas automáticas para mover objetos entre clases de almacenamiento o eliminarlos.

```
Ejemplo de Lifecycle Policy:

Día 0:     S3 Standard (datos calientes)
     │
Día 30:    S3 Standard-IA (acceso menos frecuente)
     │
Día 90:    S3 Glacier Instant Retrieval
     │
Día 180:   S3 Glacier Flexible Retrieval
     │
Día 365:   S3 Glacier Deep Archive
     │
Día 730:   Eliminar objeto
```

**Tipos de reglas:**
- **Transition actions:** Mover objetos a otra clase de almacenamiento.
- **Expiration actions:** Eliminar objetos o versiones antiguas.

### S3 Storage Class Analysis

- Analiza los patrones de acceso de los objetos en un bucket.
- Proporciona recomendaciones sobre cuándo mover objetos a una clase de almacenamiento menos costosa.
- Los datos de análisis se actualizan diariamente.
- Solo recomienda movimientos de Standard a Standard-IA (no analiza otros tiers).
- Útil para definir lifecycle policies basadas en datos reales.

### S3 Intelligent-Tiering

Mueve objetos automáticamente entre tiers según los patrones de acceso. No tiene coste por retrieval.

| Tier | Acceso | Activación |
|---|---|---|
| **Frequent Access** | Accedido regularmente | Default |
| **Infrequent Access** | No accedido en 30 días | Automática |
| **Archive Instant Access** | No accedido en 90 días | Automática |
| **Archive Access** | No accedido en 90+ días | Opcional (configurar) |
| **Deep Archive Access** | No accedido en 180+ días | Opcional (configurar) |

> **Punto clave para el examen:** Si la pregunta dice "patrones de acceso impredecibles" y quiere minimizar costes, la respuesta es **S3 Intelligent-Tiering**.

---

## Costes de Transferencia de Datos

### Reglas de transferencia de datos

| Tipo de transferencia | Coste |
|---|---|
| **Datos entrantes (ingress) a AWS** | Gratis |
| **Datos entre servicios en la misma AZ** | Gratis (usando IP privada) |
| **Datos entre AZs en la misma región** | ~$0.01/GB por dirección |
| **Datos entre regiones** | ~$0.02/GB (varía por región) |
| **Datos hacia Internet (egress)** | ~$0.09/GB (primeros 10 TB), decrece con volumen |
| **Datos a través de VPC Peering (misma región)** | ~$0.01/GB por dirección |
| **Datos a través de VPC Peering (inter-región)** | ~$0.02/GB por dirección |
| **Datos a través de NAT Gateway** | ~$0.045/GB procesados |
| **Datos con CloudFront** | Menor que egress directo de EC2/S3 |

### Estrategias para reducir costes de transferencia

```
Estrategia 1: VPC Endpoints (eliminar tráfico por Internet)
  EC2 ──► VPC Gateway Endpoint ──► S3        (gratis, sin coste de NAT)
  EC2 ──► VPC Interface Endpoint ──► DynamoDB (coste por endpoint < coste NAT)

Estrategia 2: Misma AZ
  EC2 (AZ-a) ──► RDS (AZ-a)  = gratis (IP privada)
  EC2 (AZ-a) ──► RDS (AZ-b)  = ~$0.01/GB (cross-AZ)

Estrategia 3: CloudFront
  Usuarios ──► CloudFront ──► S3/EC2  (egress de CloudFront es más barato que directamente desde S3/EC2)

Estrategia 4: Compresión
  Comprimir datos antes de transferir reduce el volumen facturado
```

### VPC Endpoints para ahorrar

| Tipo de Endpoint | Servicios | Coste |
|---|---|---|
| **Gateway Endpoint** | S3, DynamoDB | Gratis (sin coste por el endpoint ni por datos) |
| **Interface Endpoint** | Todos los demás servicios AWS | ~$0.01/hora por AZ + ~$0.01/GB procesado |

> **Punto clave para el examen:** Los **Gateway Endpoints para S3 y DynamoDB son gratuitos** y eliminan el coste de NAT Gateway. Siempre considerar como optimización de costes.

---

## AWS Cost Explorer

Herramienta visual para analizar y gestionar los costes y uso de AWS a lo largo del tiempo.

### Funcionalidades principales

| Funcionalidad | Descripción |
|---|---|
| **Visualización** | Gráficos de costes por servicio, cuenta, región, tag, etc. |
| **Filtros** | Filtrar por servicio, tipo de instancia, región, tag, tipo de coste, etc. |
| **Agrupación** | Agrupar costes por múltiples dimensiones simultáneamente |
| **Forecasting** | Predicción de costes futuros (hasta 12 meses) basada en tendencias históricas |
| **Granularidad** | Datos mensuales, diarios u horarios |
| **Datos históricos** | Hasta 12 meses de datos históricos |

### Rightsizing Recommendations

Cost Explorer incluye recomendaciones de rightsizing para EC2:

- Identifica instancias **infrautilizadas** (CPU < 40% de media en 14 días).
- Sugiere cambiar a un tipo de instancia más pequeño o a Graviton.
- Muestra el **ahorro estimado** si se implementa la recomendación.
- Basado en datos de CloudWatch (CPU, red).
- Funciona mejor con el agente de CloudWatch instalado (para datos de memoria).

> **Punto clave para el examen:** Cost Explorer es para **visualizar y analizar** costes. AWS Budgets es para **alertar** cuando se acercan o superan presupuestos.

---

## AWS Budgets

Servicio para establecer presupuestos personalizados y recibir alertas cuando los costes o el uso se acercan o exceden los límites establecidos.

### Tipos de presupuesto

| Tipo | Qué monitorea | Ejemplo |
|---|---|---|
| **Cost Budget** | Coste monetario total | Alertar si el gasto mensual supera $10,000 |
| **Usage Budget** | Uso de un servicio específico | Alertar si las horas de EC2 superan 1,000 horas |
| **Reservation Budget** | Utilización de RIs o Savings Plans | Alertar si la utilización de RIs baja del 80% |
| **Savings Plans Budget** | Utilización y cobertura de Savings Plans | Alertar si la cobertura baja del 70% |

### Alertas

- Se pueden configurar **hasta 5 alertas** por presupuesto.
- Umbrales configurables: porcentaje del presupuesto o cantidad absoluta.
- Alertar sobre **actual** (coste real) o **forecasted** (coste proyectado).
- Notificaciones por **email** y/o **SNS topic**.

### Acciones automáticas (Budget Actions)

Cuando se supera un umbral, se puede ejecutar automáticamente:

| Acción | Descripción |
|---|---|
| **IAM Policy** | Aplicar una política IAM que restrinja el lanzamiento de nuevos recursos |
| **SCP** | Aplicar una Service Control Policy en AWS Organizations |
| **Target EC2/RDS** | Detener instancias EC2 o RDS específicas |

```
Ejemplo de Budget con acciones:

Budget: $5,000/mes
  │
  ├── Alerta 1: Al 80% ($4,000) → Email al equipo
  │
  ├── Alerta 2: Al 100% ($5,000) → SNS + Email
  │
  └── Alerta 3: Al 110% ($5,500) → Aplicar IAM Policy
                                    que deniega ec2:RunInstances
```

---

## AWS Cost and Usage Report (CUR)

El **informe más detallado y completo** de costes y uso de AWS.

### Características

| Característica | Detalle |
|---|---|
| **Granularidad** | Horaria, diaria o mensual |
| **Detalle** | Línea por línea de cada recurso y operación facturada |
| **Formato** | CSV/Parquet almacenado en un bucket S3 |
| **Integración** | Athena (consultas SQL), QuickSight (dashboards), Redshift (análisis) |
| **Tamaño** | Puede ser muy grande (GBs para cuentas complejas) |
| **Columnas** | Incluye IDs de recurso, tags, precios, descuentos, amortización de RI, etc. |

### Flujo de trabajo típico

```
CUR (generado automáticamente)
     │
     ▼
S3 Bucket (almacena CSVs/Parquet)
     │
     ├──► Athena (consultas SQL ad-hoc)
     │
     ├──► QuickSight (dashboards visuales)
     │
     └──► Redshift (análisis complejos, joins con datos de negocio)
```

> **Punto clave para el examen:** CUR es la respuesta cuando necesitas el **máximo detalle** de facturación, análisis personalizado con SQL, o integración con herramientas de BI.

---

## AWS Compute Optimizer

Servicio de ML que analiza métricas de uso y recomienda el tipo de recurso óptimo.

### Recursos analizados

| Recurso | Qué recomienda | Datos usados |
|---|---|---|
| **EC2** | Tipo de instancia óptimo, sobre/infra-provisionado | CloudWatch: CPU, memoria (con agente), red, disco |
| **ASG** | Configuración óptima del grupo | Métricas de utilización de las instancias |
| **EBS** | Tipo y tamaño de volumen óptimo | IOPS, throughput, latencia |
| **Lambda** | Tamaño de memoria óptimo | Duración de invocación, memoria usada |
| **ECS on Fargate** | CPU y memoria óptimos para tasks | Métricas de utilización de containers |
| **Licencias** | Optimización de licencias de software | Uso de vCPUs para licencias vinculadas |

### Cómo funciona

- Analiza al menos **14 días** de métricas de CloudWatch (idealmente 30+ días).
- Usa modelos de ML para predecir el rendimiento con diferentes configuraciones.
- Clasifica cada recurso como: **Over-provisioned**, **Under-provisioned** o **Optimized**.
- Proporciona hasta 3 recomendaciones alternativas con ahorro estimado.

### Compute Optimizer vs Cost Explorer Rightsizing

| Característica | Compute Optimizer | Cost Explorer Rightsizing |
|---|---|---|
| **Alcance** | EC2, ASG, EBS, Lambda, ECS Fargate | Solo EC2 |
| **Análisis** | ML avanzado con múltiples métricas | Basado en utilización de CPU |
| **Recomendaciones** | Hasta 3 alternativas con predicción de rendimiento | 1 recomendación de tipo de instancia |
| **Coste** | Gratis (Enhanced con coste para datos de 3 meses) | Incluido en Cost Explorer |

---

## Rightsizing

Proceso de ajustar el tamaño y tipo de las instancias para que coincidan con la carga de trabajo real, eliminando el desperdicio.

### Cómo identificar instancias over-provisioned

| Señal | Métrica | Umbral típico |
|---|---|---|
| CPU infrautilizada | CloudWatch CPUUtilization | < 40% de media en 14 días |
| Memoria infrautilizada | CloudWatch (agente) Memory% | < 40% de media |
| Red infrautilizada | CloudWatch NetworkIn/Out | Muy por debajo del límite del tipo de instancia |
| Disco infrautilizado | CloudWatch EBSReadOps/WriteOps | IOPS/throughput mucho menor al provisionado |

### Proceso de rightsizing

```
1. Recopilar métricas (CloudWatch, agente CloudWatch para memoria)
         │
2. Analizar con Compute Optimizer o Cost Explorer
         │
3. Identificar instancias over-provisioned
         │
4. Evaluar recomendaciones (tipo de instancia más pequeño o Graviton)
         │
5. Probar en entorno de staging/desarrollo
         │
6. Implementar el cambio (redimensionar la instancia)
         │
7. Monitorear post-cambio para asegurar rendimiento adecuado
```

### Tipos de cambio comunes

| Cambio | Ejemplo | Ahorro típico |
|---|---|---|
| **Reducir tamaño** | m5.xlarge → m5.large | ~50% |
| **Cambiar a Graviton** | m5.xlarge → m6g.xlarge | ~20% (mejor precio/rendimiento) |
| **Cambiar familia** | c5.xlarge → t3.xlarge (si no necesita cómputo constante) | Variable |
| **Eliminar instancias idle** | Instancia con CPU < 5% permanentemente | 100% |

> **Punto clave para el examen:** El primer paso para optimizar costes de EC2 es siempre **rightsizing**. Antes de comprar RIs o Savings Plans, asegúrate de que las instancias son del tamaño correcto.

---

## Savings Plans vs Reserved Instances

### Tabla comparativa completa

| Característica | Standard RI | Convertible RI | EC2 Instance SP | Compute SP |
|---|---|---|---|---|
| **Descuento máximo** | ~72% | ~66% | ~72% | ~66% |
| **Compromiso** | Tipo de instancia + región + SO | Tipo de instancia (flexible) | Familia + región ($/hora) | Cualquier cómputo ($/hora) |
| **Plazo** | 1 o 3 años | 1 o 3 años | 1 o 3 años | 1 o 3 años |
| **Cambiar familia de instancia** | No | Sí | No | Sí |
| **Cambiar región** | No | No | No | Sí |
| **Cambiar SO** | No | Sí | Sí | Sí |
| **Cambiar tenancy** | No | Sí | Sí | Sí |
| **Aplica a Fargate/Lambda** | No | No | No | Sí |
| **Vender en Marketplace** | Sí | No | No | No |
| **Instance Size Flexibility** | Sí (Linux, misma familia) | Sí | Sí | Sí |

### Recomendación general

```
¿Usas solo EC2 en una familia específica?
  └── EC2 Instance Savings Plan (reemplaza Standard RI)

¿Usas EC2 + Fargate + Lambda o múltiples familias/regiones?
  └── Compute Savings Plan (reemplaza Convertible RI)

¿Necesitas vender capacidad no utilizada?
  └── Standard RI (único que se vende en Marketplace)
```

> **Punto clave para el examen:** AWS recomienda **Savings Plans sobre Reserved Instances** para la mayoría de casos. Savings Plans ofrecen la misma o mayor flexibilidad con descuentos equivalentes. La excepción es si necesitas vender en el Marketplace (solo Standard RI).

---

## Estrategias Spot

### Spot Fleet

Un **Spot Fleet** es una colección de Spot Instances (y opcionalmente On-Demand) que intenta cumplir con la capacidad objetivo al menor coste.

#### Estrategias de asignación de Spot Fleet

| Estrategia | Descripción | Caso de uso |
|---|---|---|
| **lowestPrice** | Selecciona las instancias del pool con el precio más bajo | Máximo ahorro, cargas tolerantes |
| **diversified** | Distribuye instancias entre múltiples pools | Mejor disponibilidad (reduce riesgo de interrupción masiva) |
| **capacityOptimized** | Selecciona pools con mayor capacidad disponible | Menor probabilidad de interrupción |
| **priceCapacityOptimized** | Combina precio y capacidad disponible (recomendado) | Balance óptimo entre coste y disponibilidad |

### Manejo de interrupciones Spot

Cuando AWS necesita recuperar una instancia Spot, envía un **aviso de 2 minutos**:

```
Opciones de comportamiento ante interrupción:
  │
  ├── Terminate (default): la instancia se termina
  │
  ├── Stop: la instancia se detiene (se puede reiniciar después)
  │
  └── Hibernate: la instancia se hiberna (estado en RAM se guarda)

Detección del aviso:
  ├── EC2 Metadata Service: http://169.254.169.254/latest/meta-data/spot/instance-action
  ├── CloudWatch Events / EventBridge
  └── Rebalance Recommendation (aviso previo al de 2 minutos, no garantizado)
```

### ASG con instancias mixtas (Mixed Instances Policy)

```
Auto Scaling Group:
  ├── Base capacity: 2 instancias On-Demand (siempre disponibles)
  │
  └── Additional capacity: Spot Instances
       ├── Porcentaje On-Demand above base: 20%
       ├── Porcentaje Spot above base: 80%
       │
       └── Instance types (diversificados):
            ├── m5.large
            ├── m5a.large
            ├── m4.large
            └── c5.large

Resultado: Base estable On-Demand + escalado barato con Spot
```

### Mejores prácticas para Spot

1. **Diversificar tipos de instancia y AZs:** Reduce la probabilidad de interrupción simultánea.
2. **Usar capacity-optimized allocation:** AWS selecciona los pools con más capacidad.
3. **Implementar checkpointing:** Guardar progreso regularmente para retomar el trabajo.
4. **Usar Spot Fleet en lugar de Spot individual:** Mayor resiliencia y flexibilidad.
5. **Combinar con On-Demand:** Base estable On-Demand + Spot para escalado.

---

## AWS Organizations: Facturación Consolidada

### Beneficios de la facturación consolidada

| Beneficio | Descripción |
|---|---|
| **Factura única** | Una sola factura para todas las cuentas de la organización |
| **Descuentos por volumen** | El uso de todas las cuentas se agrega para obtener descuentos por volumen (S3, EC2, etc.) |
| **Compartir RIs/Savings Plans** | Las RIs y Savings Plans de una cuenta se aplican automáticamente a instancias elegibles en otras cuentas |
| **Créditos compartidos** | Los créditos de AWS de cualquier cuenta benefician a toda la organización |
| **Precio S3 agrupado** | El almacenamiento S3 de todas las cuentas se suma para alcanzar tiers de precio más bajos |

### Descuentos por volumen - Ejemplo

```
Sin Organizations:
  Cuenta A: 100 TB S3 → Precio del tier 100 TB
  Cuenta B: 100 TB S3 → Precio del tier 100 TB

Con Organizations (consolidado):
  Total: 200 TB S3 → Precio del tier 200 TB (más barato por GB)
  Ambas cuentas se benefician del mejor precio
```

### Compartir Reserved Instances

```
Cuenta A (Management): Compra 10 RIs m5.large
Cuenta B (Desarrollo): Lanza 3 instancias m5.large

Resultado: Las 3 instancias de Cuenta B usan el descuento de RI de Cuenta A automáticamente.

Para desactivar: En la cuenta management, desactivar "RI sharing" para cuentas específicas.
```

> **Punto clave para el examen:** La facturación consolidada en Organizations permite **descuentos por volumen agregado** y **compartir reservas**. Es una forma de optimizar costes sin cambio técnico.

---

## Estrategia de Tagging para Asignación de Costes

### Tags de asignación de costes

Los tags permiten categorizar y rastrear costes de AWS por proyecto, equipo, entorno, etc.

#### Tipos de Cost Allocation Tags

| Tipo | Descripción | Ejemplo |
|---|---|---|
| **AWS-generated** | Tags creados automáticamente por AWS | `aws:createdBy` (quién creó el recurso) |
| **User-defined** | Tags creados por el usuario | `Project`, `Environment`, `Team`, `CostCenter` |

### Activación

Los tags **deben activarse** en la consola de Billing para que aparezcan en los informes de costes:

```
1. Crear los tags en los recursos (Billing → Cost Allocation Tags)
2. Activar los tags como "Cost Allocation Tags" en la consola de Billing
3. Esperar ~24 horas para que aparezcan en los informes
4. Usar en Cost Explorer y CUR para filtrar/agrupar costes
```

### Estrategia de tagging recomendada

| Tag | Propósito | Valores ejemplo |
|---|---|---|
| `Environment` | Separar costes por entorno | production, staging, development |
| `Project` | Asignar costes a proyectos específicos | project-alpha, project-beta |
| `Team` | Asignar costes por equipo | backend, frontend, data, devops |
| `CostCenter` | Vincular con centros de coste contables | CC-001, CC-002 |
| `Owner` | Identificar al responsable | email del propietario |
| `Application` | Agrupar por aplicación | web-app, api, batch-processor |
| `ManagedBy` | Herramienta que gestiona el recurso | terraform, cloudformation, manual |

### Enforcement de tags

| Método | Descripción |
|---|---|
| **AWS Config Rules** | Regla `required-tags` que marca como non-compliant los recursos sin tags obligatorios |
| **SCP (Organizations)** | Denegar la creación de recursos sin tags específicos usando condiciones `aws:RequestTag` |
| **Tag Policies** | Políticas en Organizations que estandarizan los valores permitidos para cada tag |
| **AWS Service Catalog** | Productos pre-configurados con tags obligatorios |

Ejemplo de SCP para forzar tags:
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "RequireProjectTag",
    "Effect": "Deny",
    "Action": "ec2:RunInstances",
    "Resource": "arn:aws:ec2:*:*:instance/*",
    "Condition": {
      "Null": {
        "aws:RequestTag/Project": "true"
      }
    }
  }]
}
```

---

## Tips para el Examen

### Preguntas frecuentes y respuestas rápidas

| Escenario del examen | Respuesta |
|---|---|
| Carga estable 24/7 durante 3 años | **Standard RI All Upfront 3 años** o **EC2 Instance Savings Plan** |
| Carga batch tolerante a interrupciones | **Spot Instances** |
| Patrones de acceso S3 impredecibles | **S3 Intelligent-Tiering** |
| Acceso a S3 desde VPC sin coste de NAT | **VPC Gateway Endpoint para S3** (gratis) |
| Análisis detallado de facturación con SQL | **Cost and Usage Report (CUR) + Athena** |
| Alertar cuando el gasto supere un umbral | **AWS Budgets** |
| Recomendar tipo de instancia EC2 óptimo | **AWS Compute Optimizer** |
| Visualizar costes por servicio/mes | **AWS Cost Explorer** |
| Reducir coste de EC2 + Fargate + Lambda | **Compute Savings Plan** |
| Licencias BYOL por socket | **Dedicated Host** |
| Maximizar descuento EC2 sin riesgo | **Standard RI 3y All Upfront** (~72%) |
| Descuento por volumen S3 entre cuentas | **AWS Organizations facturación consolidada** |
| Asignar costes por proyecto | **Cost Allocation Tags** (activados en Billing) |
| Detener gasto automáticamente si se supera presupuesto | **AWS Budgets Actions** (aplicar IAM policy) |
| Mover datos S3 automáticamente a clases más baratas | **S3 Lifecycle Policies** |
| Reducir coste de transferencia a internet | **CloudFront** (egress más barato) |
| Primer paso para optimizar costes EC2 | **Rightsizing** (antes de comprar RIs) |

### Orden de prioridad para optimizar costes EC2

```
1. Rightsizing  → Asegurar que el tamaño es correcto
2. Savings Plans / RIs  → Compromiso para cargas estables
3. Spot  → Para cargas tolerantes a interrupciones
4. Graviton  → Mejor precio/rendimiento (~20% más barato)
5. Auto Scaling  → Escalar hacia abajo cuando no hay demanda
6. Scheduled scaling  → Apagar en horarios sin uso
```

### Errores comunes a evitar

1. **Comprar RIs antes de hacer rightsizing:** Primero optimiza el tamaño, luego compra reservas.
2. **Usar Gateway Endpoint para servicios que no lo soportan:** Solo S3 y DynamoDB tienen Gateway Endpoint. El resto usa Interface Endpoint (con coste).
3. **Olvidar activar Cost Allocation Tags:** Crear tags no es suficiente; hay que activarlos en Billing para que aparezcan en informes.
4. **Confundir Cost Explorer con Budgets:** Explorer es para analizar, Budgets es para alertar y actuar.
5. **No diversificar tipos de instancia Spot:** Usar solo un tipo de instancia Spot aumenta el riesgo de interrupción.
6. **Ignorar los costes de transferencia entre AZs:** Aunque son pequeños (~$0.01/GB), pueden acumularse con volumen alto. Considerar localidad de datos.
7. **Asumir que Savings Plans aplican a todos los servicios:** Compute Savings Plans aplican a EC2, Fargate y Lambda. No aplican a RDS u otros servicios gestionados.
8. **No considerar Convertible RI o Compute SP cuando la tecnología cambia rápido:** Si en 3 años podrías cambiar de tipo de instancia, la flexibilidad de Convertible RI o Compute SP vale la pena.
