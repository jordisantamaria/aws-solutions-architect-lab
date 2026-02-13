# Preguntas de Práctica - AWS Solutions Architect Associate (SAA-C03)

## Información del Examen

| Dato | Detalle |
|------|---------|
| **Código del examen** | SAA-C03 |
| **Número de preguntas** | 65 preguntas (50 puntuadas + 15 no puntuadas) |
| **Duración** | 130 minutos |
| **Puntuación** | 100 - 1,000 puntos |
| **Puntuación para aprobar** | **720 puntos** |
| **Formato** | Multiple choice (1 respuesta) y multiple response (2+ respuestas) |
| **Idiomas** | Inglés, japonés, coreano, chino simplificado, y más |
| **Costo** | $150 USD |
| **Validez** | 3 años |

> **Nota:** Las 15 preguntas no puntuadas se usan para evaluar nuevas preguntas para futuros exámenes. No puedes saber cuáles son, así que responde todas con el mismo esfuerzo.

---

## Dominios del Examen y Pesos

| Dominio | Peso | Preguntas aprox. |
|---------|------|-----------------|
| **Dominio 1:** Diseñar arquitecturas seguras | **30%** | ~20 preguntas |
| **Dominio 2:** Diseñar arquitecturas resilientes | **26%** | ~17 preguntas |
| **Dominio 3:** Diseñar arquitecturas de alto rendimiento | **24%** | ~16 preguntas |
| **Dominio 4:** Diseñar arquitecturas optimizadas en costo | **20%** | ~13 preguntas |

---

## Tipos de Preguntas

### 1. Single Answer (Respuesta única)
- Se presenta un escenario y **4 opciones** (A, B, C, D)
- Solo **1 respuesta** es correcta
- La mayoría de preguntas son de este tipo

### 2. Multiple Answer (Respuesta múltiple)
- Se presenta un escenario y **5-6 opciones**
- Debes seleccionar **2 o 3 respuestas** correctas (se indica en el enunciado)
- Ejemplo: "Selecciona DOS respuestas que cumplan el requisito"
- Debes acertar TODAS las opciones correctas para obtener el punto

---

## Estrategia para Responder

### Antes del examen
1. **Lee la guía oficial** del examen (Exam Guide) de AWS
2. **Practica con exámenes simulados** de fuentes confiables
3. **Repasa los cheat sheets** de esta carpeta la noche anterior
4. Duerme bien la noche anterior

### Durante el examen

#### Paso 1: Lee la pregunta completa
- Lee **primero la última línea** de la pregunta (lo que realmente piden)
- Luego lee el escenario completo
- Identifica las **keywords clave** que limitan las opciones

#### Paso 2: Busca keywords restrictivas
Las keywords más comunes y lo que implican:

| Keyword | Significado |
|---------|------------|
| **"Most cost-effective"** | La opción más barata que cumpla requisitos |
| **"Least operational overhead"** | Servicios gestionados/serverless |
| **"Highest availability"** | Multi-AZ, multi-region, redundancia |
| **"Minimum downtime"** | Blue/green, rolling, failover automático |
| **"Most secure"** | Principio de mínimo privilegio, cifrado, VPC privada |
| **"Fastest"** | Caching, CDN, read replicas, mayor instancia |
| **"Simplest / easiest"** | Menor complejidad, servicios gestionados |
| **"Durable"** | S3 (11 nueves), Multi-AZ, backups |
| **"Decouple"** | SQS, SNS, EventBridge |
| **"Serverless"** | Lambda, Fargate, DynamoDB, S3, API Gateway |
| **"Real-time"** | Kinesis, WebSocket, ElastiCache |

#### Paso 3: Elimina las opciones incorrectas
- Elimina opciones que **no existen** en AWS o usan servicios mal
- Elimina opciones que **cumplen pero son innecesariamente complejas**
- Elimina opciones que **no satisfacen un requisito clave** del escenario

#### Paso 4: Entre las opciones restantes
- Si dos opciones parecen correctas, la que tiene **menos pasos** suele ser la respuesta
- AWS prefiere **servicios gestionados** sobre soluciones custom
- AWS prefiere **serverless** cuando es posible
- Si piden "cost-effective", el servicio más simple suele ganar

#### Paso 5: Marca y avanza
- Si no estás seguro, marca la pregunta y sigue adelante
- Vuelve a las preguntas marcadas al final
- **No dejes preguntas sin responder** (no hay penalización)

---

## Errores Comunes a Evitar

1. **No leer todas las opciones** — A veces la opción D es mejor que la B
2. **Elegir la opción "más completa"** — A veces menos es más
3. **Ignorar las restricciones del escenario** — "On-prem" o "existing Oracle DB" cambia todo
4. **Confundir HA con DR** — Multi-AZ es HA, cross-region es DR
5. **Olvidar costos de transferencia de datos** — Cross-region y salida a internet cuestan dinero
6. **Asumir que todo es serverless** — A veces la pregunta requiere EC2 explícitamente
7. **No considerar los límites** — Lambda tiene límite de 15 min, SQS FIFO tiene límite de 3,000 msg/s

---

## Recursos para Práctica

### Exámenes de práctica oficiales de AWS
- **AWS Skill Builder** — Exámenes de práctica oficiales (gratuitos y de pago)
  - URL: [https://explore.skillbuilder.aws/learn/signin](https://explore.skillbuilder.aws/learn/signin)
  - Incluye un examen de práctica gratuito de 20 preguntas
  - Examen completo oficial: $20 USD

### Otros recursos recomendados
- **AWS Whitepapers** relevantes:
  - Well-Architected Framework
  - Architecting for the Cloud: Best Practices
  - Disaster Recovery
  - Security Best Practices
- **AWS FAQs** de los servicios principales (S3, EC2, RDS, Lambda, VPC)
- **AWS re:Invent videos** sobre arquitectura

---

## Estructura de las Preguntas de Práctica

Cada pregunta en esta carpeta sigue el formato:

```
## Pregunta X

[Escenario basado en un caso real]

A) Opción A
B) Opción B
C) Opción C
D) Opción D

<details>
<summary>Ver respuesta</summary>

**Respuesta: X**

[Explicación detallada de por qué es correcta y por qué las demás no]

**Servicio/concepto clave:** [Servicio AWS principal]
</details>
```

---

## Archivos de Preguntas por Dominio

| Archivo | Dominio | Preguntas |
|---------|---------|-----------|
| [domain-1-secure-architectures.md](./domain-1-secure-architectures.md) | Diseñar arquitecturas seguras | 15 preguntas |
| [domain-2-resilient-architectures.md](./domain-2-resilient-architectures.md) | Diseñar arquitecturas resilientes | 15 preguntas |
| [domain-3-high-performing-architectures.md](./domain-3-high-performing-architectures.md) | Diseñar arquitecturas de alto rendimiento | 15 preguntas |
| [domain-4-cost-optimized-architectures.md](./domain-4-cost-optimized-architectures.md) | Diseñar arquitecturas optimizadas en costo | 15 preguntas |

**Total: 60 preguntas de práctica**

> **Consejo:** Intenta responder cada pregunta ANTES de ver la respuesta. Marca las que falles y repásalas de nuevo en unos días.
