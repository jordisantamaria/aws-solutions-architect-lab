# Compute - Cheat Sheet Rápido

## Tipos de Instancia EC2

| Familia | Prefijo | Descripción rápida |
|---------|---------|---------------------|
| **General Purpose** | `t3, t3a, m5, m6i` | Equilibrio CPU/memoria — webs, microservicios, entornos de desarrollo |
| **Compute Optimized** | `c5, c6i, c7g` | Alta CPU — batch processing, modelado científico, gaming servers |
| **Memory Optimized** | `r5, r6i, x1, z1d` | Alta memoria — bases de datos in-memory, caches grandes, SAP HANA |
| **Storage Optimized** | `i3, i4i, d2, h1` | Alto I/O secuencial o aleatorio — data warehouses, HDFS, Elasticsearch |
| **Accelerated Computing** | `p4, p5, g5, inf1, trn1` | GPU/FPGA — machine learning, renderizado 3D, transcoding de vídeo |
| **HPC Optimized** | `hpc6a, hpc7g` | Alto rendimiento computacional — simulaciones, dinámica de fluidos |

> **Truco para el examen:** La letra inicial indica la familia: **T**urbo(burstable), **M**emoria+CPU, **C**ompute, **R**AM, **I**/O, **P**rocesamiento paralelo (GPU).

---

## Modelos de Precio EC2

| Modelo | Descuento vs On-Demand | Compromiso | Interrupción | Caso de uso |
|--------|----------------------|------------|-------------|-------------|
| **On-Demand** | 0% (precio base) | Ninguno | No | Cargas impredecibles, pruebas, desarrollo |
| **Reserved (RI)** | Hasta **72%** | 1 o 3 años | No | Cargas estables y predecibles (producción) |
| **Savings Plans** | Hasta **72%** | 1 o 3 años ($/hr) | No | Flexibilidad entre familias, regiones o servicios |
| **Spot Instances** | Hasta **90%** | Ninguno | **Sí** (2 min aviso) | Batch, CI/CD, procesamiento tolerante a fallos |
| **Dedicated Hosts** | Variable | Opcional | No | Licencias por socket/core, compliance estricto |
| **Dedicated Instances** | Variable | Ninguno | No | Hardware dedicado sin gestionar el host |
| **Capacity Reservations** | 0% | Ninguno (pago On-Demand) | No | Garantizar capacidad en una AZ específica |

> **Clave examen:** Si preguntan "menor costo" + "puede interrumpirse" = **Spot**. Si es "menor costo" + "carga estable" = **Reserved/Savings Plans**.

---

## Límites de AWS Lambda

| Parámetro | Límite |
|-----------|--------|
| **Memoria** | 128 MB — 10,240 MB (10 GB) |
| **Timeout máximo** | 15 minutos (900 segundos) |
| **Tamaño paquete (zip, directo)** | 50 MB comprimido / 250 MB descomprimido |
| **Tamaño con capas (layers)** | 250 MB descomprimido total |
| **Container image** | 10 GB |
| **Concurrencia por región** | 1,000 (default, se puede aumentar) |
| **Concurrencia reservada** | Configurable por función |
| **Almacenamiento efímero `/tmp`** | 512 MB — 10,240 MB |
| **Variables de entorno** | 4 KB total |
| **Payload síncrono** | 6 MB |
| **Payload asíncrono** | 256 KB |

> **Truco examen:** Si el proceso dura más de 15 min → **NO** usar Lambda. Considerar ECS/Fargate, Batch o Step Functions.

---

## ECS vs EKS vs Fargate

| Servicio | Cuándo usarlo |
|----------|--------------|
| **ECS** | Orquestación de contenedores sencilla, integración nativa con AWS, no necesitas Kubernetes |
| **EKS** | Ya usas Kubernetes, necesitas portabilidad multi-cloud, o tu equipo domina K8s |
| **Fargate** | No quieres gestionar servidores/instancias subyacentes — serverless para contenedores (funciona con ECS o EKS) |

```
¿Contenedores?
  ├── ¿Necesitas Kubernetes? ──→ SÍ ──→ EKS
  │                            └─ NO ──→ ECS
  └── ¿Quieres gestionar la infraestructura (EC2)?
       ├── SÍ ──→ EC2 Launch Type
       └── NO ──→ Fargate Launch Type
```

---

## Políticas de Auto Scaling

| Tipo de Política | Descripción | Ejemplo |
|-----------------|-------------|---------|
| **Target Tracking** | Mantiene una métrica en un valor objetivo — la más simple y recomendada | "Mantener CPU al 50%" |
| **Step Scaling** | Acciones escalonadas según el tamaño de la alarma | CPU > 60% → +1, CPU > 80% → +3 |
| **Simple Scaling** | Una acción por alarma, espera cooldown antes de otra acción | CPU > 70% → +1 (cooldown 300s) |
| **Scheduled Scaling** | Escalar en horarios predefinidos | "Lunes a viernes a las 8:00 → mín 10 instancias" |
| **Predictive Scaling** | Usa ML para predecir tráfico futuro y pre-escalar | Patrones recurrentes diarios/semanales |

> **Clave examen:** **Target Tracking** es la respuesta por defecto cuando preguntan la forma "más sencilla" de escalar. **Predictive** cuando mencionan patrones predecibles. **Scheduled** para eventos conocidos.

### Conceptos clave de Auto Scaling

- **Cooldown period:** Tiempo de espera tras una acción de escalado (default 300s)
- **Warm-up time:** Tiempo que una instancia nueva necesita antes de contribuir a métricas
- **Desired capacity:** Número actual de instancias deseadas
- **Min/Max capacity:** Límites del grupo

---

## Tipos de Despliegue en Elastic Beanstalk

| Tipo | Downtime | Velocidad | Rollback | Costo extra | Descripción |
|------|----------|-----------|----------|-------------|-------------|
| **All at once** | **Sí** | Más rápido | Re-deploy manual | No | Despliega en todas las instancias simultáneamente |
| **Rolling** | No (parcial) | Medio | Re-deploy manual | No | Despliega en batches — algunas instancias temporalmente con versión anterior |
| **Rolling with additional batch** | No | Medio-lento | Re-deploy manual | **Sí** (instancias extra) | Lanza batch extra antes de actualizar — mantiene capacidad completa |
| **Immutable** | No | Lento | Terminar nuevas | **Sí** (doble temporal) | Crea instancias nuevas en nuevo ASG, swap si healthy |
| **Traffic splitting** | No | Lento | Redirigir tráfico | **Sí** (doble temporal) | Canary: envía % de tráfico a nueva versión |
| **Blue/Green** | No | Medio | Swap URL | **Sí** (entorno duplicado) | Dos entornos Beanstalk, swap CNAME cuando listo |

> **Clave examen:** "Sin downtime + menor riesgo" = **Immutable** o **Blue/Green**. "Sin costo extra" = **Rolling**. "Más rápido" = **All at once**.

---

## Resumen de Decisiones Rápidas - Compute

```
PREGUNTA DEL EXAMEN                          → RESPUESTA
─────────────────────────────────────────────────────────
"Menor costo posible, tolera interrupciones"  → Spot Instances
"Carga estable, menor costo a largo plazo"    → Reserved / Savings Plans
"Ejecutar código sin gestionar servidores"    → Lambda (< 15 min) o Fargate
"Contenedores sin gestionar infraestructura"  → Fargate
"Despliegue más simple para desarrolladores"  → Elastic Beanstalk
"Escalar automáticamente basado en demanda"   → Auto Scaling + Target Tracking
"Procesamiento batch a gran escala"           → AWS Batch (+ Spot)
"GPU para machine learning"                   → EC2 P/G instances o SageMaker
```
