# Career Plan: Top Engineer en Japón

## Objetivo

Posicionarme como AI Infrastructure Engineer de alto valor innegable en Japón, con credenciales objetivas que no dependan de marketing ni opiniones subjetivas.

**Rol objetivo**: el que pone AI en producción con infra segura y escalable. No data scientist, no ML researcher. El que construye la carretera, no el que conduce el coche.

## Las 5 piezas del perfil innegable

| # | Qué | Por qué es innegable | Estado |
|---|---|---|---|
| 1 | **AWS Certs (SAA → SAP → SCS → AIF)** | Examen objetivo, pasas o no | [ ] SAA / [ ] SAP / [ ] SCS / [ ] AIF |
| 2 | **GitHub con proyectos reales** | Código público, verificable | [ ] Terraform+Bedrock module |
| 3 | **Artículos técnicos en Zenn (japonés)** | Demuestra conocimiento + idioma | [ ] Primer artículo |
| 4 | **Speaker en JAWS-UG** | Red de contactos + visibilidad | [ ] Primera charla |
| 5 | **Especialización: AWS + GenAI infra** | Poca competencia | En progreso |

## Timeline

### Mes 1-2: Fundamentos
- [ ] Aprobar SAA-C03
- [ ] Completar este repo (docs + labs)
- [ ] Empezar a asistir a JAWS-UG como asistente

### Mes 3-4: Diferenciación
- [ ] Aprobar SAP-C02
- [ ] Crear proyecto público: Terraform module para Bedrock + API Gateway + Lambda
- [ ] Primer artículo en Zenn: "Bedrock + Terraform: LLMアプリを本番環境にデプロイする方法"

### Mes 5-6: Visibilidad + Seguridad
- [ ] Aprobar SCS-C02 (Security Specialty)
- [ ] Primera charla en JAWS-UG (LT de 10-15 min sobre el proyecto Bedrock)
- [ ] Buscar trabajo GAFA / freelance premium con este perfil

### Mes 7-8: GenAI cert
- [ ] Aprobar AIF-C01 (AI Practitioner) — alineado con GenAI, no requiere ML clásico
- [ ] Segundo proyecto público en GitHub

### Mes 9+: Consolidación
- [ ] Entrar en GAFA (Amazon ideal) o freelance premium
- [ ] Seguir contribuyendo en JAWS-UG regularmente
- [ ] Publicar en Zenn 1x/mes

## Ruta de certificaciones AWS

```
SAA-C03 (Solutions Architect Associate)    ← Fundamentos
    ↓
SAP-C02 (Solutions Architect Professional) ← Credibilidad seria
    ↓
SCS-C02 (Security Specialty)              ← Seguridad = $$$ en Japón
    ↓
AIF-C01 (AI Practitioner)                 ← GenAI sin necesitar ML clásico
```

### Por qué NO MLS-C01 (ML Specialty)

MLS-C01 requiere ML clásico profundo (XGBoost, feature engineering, CNNs, estadística, métricas como AUC-ROC/F1, regularización L1/L2). Saber usar LLMs no es suficiente para aprobar.

**AIF-C01 es mejor opción** porque:
- Enfocado en GenAI y servicios managed (Bedrock, etc.)
- Alineado con el rol de AI infra engineer
- No requiere ser data scientist

**MLS-C01 solo si**: genuinamente te interesa aprender ML clásico (2-3 meses extra de estudio con Andrew Ng en Coursera).

### Por qué NO multi-cloud

- AWS ~50% market share en Japón
- Profundidad > amplitud (siempre)
- El que tiene SAA+SAP+SCS vale más que el que tiene 3 clouds a nivel associate
- Solo considerar GCP después de consolidar AWS

## Experiencia actual: startup infra como fortaleza

### Lo que tengo
- Empresa propia manteniendo infra AWS para startups
- Experiencia diseñando infra desde cero con presupuesto limitado
- Terraform en producción real
- Tomar todas las decisiones de arquitectura solo

### Lo que parece debilidad pero no lo es
| Mi preocupación | La realidad |
|---|---|
| "No he manejado millones de usuarios" | En entrevistas evalúan si SABES diseñar para escala, no si lo has hecho |
| "Solo startups pequeñas" | Cost optimization con poco presupuesto es un skill muy valorado (20% del SAA-C03) |
| "Lo hago todo solo" | Full-stack infra engineer > especialista que solo toca un componente |

### Cómo compensar la falta de escala real
1. **Terraform labs con escenarios de escala** → Multi-AZ, ASG, Aurora replicas, CloudFront, SQS
2. **SAP-C02** → demuestra que sabes diseñar para escala aunque no lo hayas operado
3. **Artículos en Zenn** sobre arquitectura a escala (no necesitas tráfico real, necesitas demostrar que lo entiendes)
4. **System design practice** → la entrevista de GAFA es exactamente "diseña para escala sin haberlo hecho"

## Especialización: AWS + GenAI Infrastructure

### El posicionamiento

```
"Te monto la infra para que tu equipo de AI pueda usar
 Bedrock/SageMaker en producción, con seguridad,
 escalabilidad y coste optimizado"
```

NO es: "Te entreno un modelo de regresión logística"

### Stack técnico a dominar

| Servicio | Para qué |
|---|---|
| **Bedrock** | LLMs gestionados (Claude, Titan) — el core |
| **SageMaker endpoints** | Deployment de modelos custom |
| **ECS/EKS con GPU** | Containers para ML workloads |
| **API Gateway + Lambda** | Serving y orquestación |
| **Terraform** | IaC para todo lo anterior |
| **IAM + VPC + KMS** | Seguridad de la infra AI |
| **CloudWatch + X-Ray** | Observabilidad |

### Por qué funciona en Japón

- Las empresas japonesas están invirtiendo fuerte en AI
- No encuentran gente que sepa ponerlo en producción
- Un extranjero con japonés + AI infra skills es extremadamente raro
- La demanda de "deploy LLM en producción" es 10x mayor que "entrenar XGBoost"

### ML clásico vs GenAI infra — Mercado real

| Skill | Demanda | Salario típico |
|---|---|---|
| Entrenar XGBoost/sklearn | Media | Data scientist: 10-15M |
| Teoría de CNNs/RNNs | Baja | Researcher: variable |
| **Desplegar LLMs en producción** | **Muy alta** | **AI Infra: 18-30M** |
| **Bedrock + Terraform + seguridad** | **Muy alta** | **Muy pocos lo hacen** |

## Visibilidad: la pieza que convierte 15M en 25M+

### Por qué la visibilidad es obligatoria

```
Certs + Portfolio + Visibilidad = 24-30M JPY
Certs + Portfolio - Visibilidad = 14-18M JPY (techo)
```

No es marketing. Es que las personas que pagan salarios altos **sepan que existes**. Sin visibilidad, compites por precio a través de agentes con otros 50 candidatos.

### Cómo funciona en la práctica

```
Sin visibilidad:
  → Buscas en agente → te ponen en lista con 50 candidatos
  → Compites por CV → el agente se lleva 25%
  → Cobras 1.2-1.5M/mes

Con visibilidad:
  → Das charla en JAWS-UG sobre Bedrock + Terraform
  → CTO de empresa X te habla después: "necesitamos exactamente esto"
  → Negociación directa, sin agente
  → Cobras 2M+/mes
```

Los freelancers que cobran 2M+/mes no buscan trabajo. El trabajo les busca a ellos. Y eso pasa porque:
1. Alguien les vio en un meetup
2. Alguien leyó su artículo
3. Un ex-compañero les recomendó
4. Un cliente anterior les refirió a otro

### Mínimo viable de visibilidad

| Acción | Frecuencia | Impacto |
|---|---|---|
| **JAWS-UG** charla | 1 cada 2-3 meses | Contacto directo con hiring managers |
| **Zenn** artículo | 1 al mes | Recruiters te encuentran por keywords |
| **LinkedIn** actualizado (inglés) | Mantener al día | Recruiters inbound |

### Zenn (dev.to japonés)

Ideas de artículos:
- [ ] "Bedrock + Terraform: LLMアプリを本番環境にデプロイする方法"
- [ ] "AWS SageMaker vs Bedrock: いつどちらを使うべきか"
- [ ] "Terraform で作る本番グレードの AWS インフラ"
- [ ] "SAA-C03 合格体験記" (experiencia aprobando el examen)
- [ ] "Claude Code で Terraform モジュールを作る方法"
- [ ] "1億リクエストに耐えるサーバーレスアーキテクチャ" (arquitectura serverless a escala)

### JAWS-UG (Japan AWS User Group)

- Buscar eventos en **connpass.com** → "JAWS-UG"
- Chapters: JAWS-UG Tokyo, JAWS-UG AI/ML, JAWS-UG Beginner
- Primero asistir 2-3 veces, después proponer Lightning Talk

Charla ejemplo:
```
Título: "Bedrock + Terraform: LLMアプリを本番環境にデプロイする方法"
Contenido: Arquitectura + Terraform module + demo en vivo + costes reales
Duración: 15 min
Dónde: JAWS-UG Tokyo o JAWS-UG AI/ML chapter
```

## Entrar en GAFA

### Vías de entrada (por efectividad)

1. **Referral** — un empleado te recomienda internamente (la mejor vía)
2. **Aplicar directo** — careers page de cada empresa, filtrar por Tokyo
3. **LinkedIn inbound** — perfil optimizado en inglés, "Open to Work" para recruiters
4. **Meetups** — conocer gente de GAFA en JAWS-UG → pedir referral

**No depender de agentes** para GAFA. Los agentes funcionan para empresas japonesas y consultoras, no para GAFA.

### Preparación para entrevistas GAFA

| Área | Recurso | Tiempo |
|---|---|---|
| Coding | LeetCode (150 problemas top) | 2-3 meses, 1h/día |
| System Design | "Designing Data-Intensive Applications", Alex Xu | 1-2 meses |
| Behavioral | Amazon Leadership Principles | 2 semanas |

**Amazon es la puerta más fácil**: más volumen de contratación en Tokyo, valoran AWS certs, oficina grande en Meguro.

### GAFA — La realidad

**Lo bueno**: evalúan por output real, no antigüedad. IC senior (Staff/Principal) cobra igual que PM senior.

**Lo que no te cuentan**: PIP culture (te echan si no rindes), stack ranking en Amazon, política interna existe (hay que hacer visible tu impacto), layoffs posibles.

**No es destino, es trampolín**: 2-3 años para branding + ahorro + red de contactos → después freelance con "ex-Amazon" en el CV.

## Salario esperado por fase

| Fase | Perfil | Rango salarial |
|---|---|---|
| Ahora | Sin certs, sin visibilidad | 8-12M JPY |
| Post SAA+SAP + portfolio | Certs + GitHub | 14-18M JPY |
| Post visibilidad | Certs + JAWS-UG + Zenn + SCS | 18-22M JPY |
| GAFA (2-3 años) | Amazon/Google IC | 25-35M JPY |
| Freelance post-GAFA | Brand personal + red + clientes directos | 24-30M JPY (con libertad) |
| Freelance + SaaS propio | Romper el techo | 30M+ JPY (sin límite teórico) |

### Freelance: con y sin agente

| | Con agente | Sin agente (directo) |
|---|---|---|
| Cliente paga | 2M/mes | 2M/mes |
| Tú cobras | ~1.5M/mes | **2M/mes** |

Sin agente necesitas red de contactos propia (JAWS-UG, ex-GAFA network).

### Romper el techo de freelance

Freelance tiene techo matemático (horas × tarifa ≈ 30M max). Para superarlo:
- SaaS/producto propio que escale sin tu tiempo
- Combinar: freelance 3 días/semana + producto propio 2 días

## Decisiones estratégicas

| Decisión | Elegir | No elegir |
|---|---|---|
| Track | **IC** (Individual Contributor) | PM (mismo salario, más política) |
| Cloud | **Deep AWS** | Multi-cloud (dispersa foco) |
| ML | **GenAI infra** (Bedrock, deploy) | ML clásico (data science) |
| Empresa | **GAFA como trampolín** (2-3 años) | GAFA como destino permanente |
| Después | **Freelance premium** + producto propio | Quedarse en corporate |

## Lo que NO hacer

- ~~Kaggle~~ → valor diluido por AI, perfil data scientist, no infra
- ~~OSS PRs random~~ → fácil con Claude Code, todos lo hacen
- ~~Multi-cloud~~ → dispersa el foco
- ~~MLS-C01 sin interés real en ML~~ → AIF-C01 es mejor opción
- ~~MBA / máster~~ → no necesario para IC track
- ~~Marketing en LinkedIn~~ → el perfil habla solo con certs + GitHub + charlas
- ~~Depender de agentes para GAFA~~ → referral + aplicación directa

## Recursos

### Certificaciones
- Este repo: `aws-solutions-architect-lab/`
- Exámenes de práctica: Tutorials Dojo, WhizLabs

### Comunidad
- connpass.com → JAWS-UG eventos
- Zenn.dev → publicar artículos técnicos

### Repos relacionados
- `ai-engineering-lab` → modelos ML, base para proyecto Bedrock
- `llm-playbook` → aplicaciones LLM, contenido para charlas
