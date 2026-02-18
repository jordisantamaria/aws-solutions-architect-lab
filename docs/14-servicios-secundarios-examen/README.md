# Servicios Secundarios del Examen SAA-C03

Servicios que aparecen en preguntas del examen como opciones correctas o distractores. No necesitan sección entera pero necesitas saber qué hacen para elegir o descartar.

---

## Marketing y Comunicación

### Amazon Pinpoint
**Plataforma de marketing multicanal**

- Envío masivo de SMS, email, push notifications, voice
- Journeys: flujos de marketing automatizados (usuario se registra → email día 1 → SMS día 3 → ...)
- Campañas segmentadas por comportamiento del usuario
- Two-way SMS: recibir respuestas de los usuarios
- Integración con Kinesis para análisis de eventos en tiempo real

```
Casos de uso:
  - Campaña de marketing por SMS a suscriptores
  - Email de bienvenida automatizado
  - Notificaciones push segmentadas
  - Recoger respuestas SMS y analizarlas
```

**Para el examen:**
```
"Marketing campaign SMS/email/push"          → Pinpoint
"Multi-engagement campaign"                   → Pinpoint
"Two-way SMS (enviar y recibir respuestas)"  → Pinpoint
"Enviar una notificación simple/alerta"      → SNS (no Pinpoint)
```

**Pinpoint vs SNS:**
```
Pinpoint: marketing (campañas, journeys, segmentación, analytics)
SNS:      notificaciones simples (alertas, triggers, pub/sub)

"Avisar al admin que el servidor se cayó"     → SNS
"Enviar oferta de Black Friday a 50k users"   → Pinpoint
```

---

### Amazon Connect
**Contact center (call center) en la nube**

- Central telefónica virtual completa
- IVR (menú telefónico interactivo)
- Routing de llamadas a agentes
- Chat en tiempo real
- Integración con Lex (chatbots) para self-service
- Contact flows: flujos de llamada configurables
- Grabación de llamadas
- Analytics de rendimiento de agentes

```
Casos de uso:
  - Call center de atención al cliente
  - Sistema telefónico automatizado (IVR)
  - Soporte técnico con chat + llamadas
  - Chatbot telefónico (Connect + Lex)
```

**Para el examen:**
```
"Call center", "contact center"              → Amazon Connect
"IVR", "menú telefónico"                    → Amazon Connect
"Routing de llamadas a agentes"             → Amazon Connect
"Enviar SMS a clientes" (sin call center)   → Pinpoint o SNS (NO Connect)
```

**Connect vs Pinpoint:**
```
Connect:  atención al cliente (el cliente te llama/escribe)
Pinpoint: marketing (tú envías mensajes al cliente)
```

---

### Amazon SES (Simple Email Service)
**Servicio de envío de email transaccional y marketing**

- Envío de emails a escala (miles por segundo)
- Email transaccional (confirmación de registro, recibos, etc.)
- Email marketing masivo
- Gestión de bounces y quejas
- Email receiving (recibir emails y procesarlos con Lambda/S3)

**Para el examen:**
```
"Enviar emails transaccionales a escala"     → SES
"Email marketing masivo"                      → SES o Pinpoint
"Recibir emails y procesarlos"               → SES (email receiving)
```

**SES vs Pinpoint vs SNS:**
```
SES:      email a escala (transaccional + marketing)
Pinpoint: marketing multicanal (email + SMS + push + journeys)
SNS:      notificaciones (email simple, SMS simple, pub/sub)
```

---

## Governance y Compliance

### AWS Service Catalog
**Catálogo de productos IT aprobados**

- El equipo de infra crea "productos" (templates de CloudFormation)
- Los developers solo pueden lanzar productos del catálogo
- Control centralizado de qué se puede desplegar
- Versiones, permisos, restricciones de lanzamiento
- Portfolios: agrupaciones de productos por equipo/departamento

```
Ejemplo:
  IT crea 3 productos aprobados:
    - "Web server" (EC2 + ALB + ASG pre-configurado)
    - "Base de datos" (RDS con cifrado y backups)
    - "Data pipeline" (Glue + S3 + Athena)

  Developer quiere un servidor → elige del catálogo → se lanza con config aprobada
  No puede crear EC2 random sin cifrado ni tags
```

**Para el examen:**
```
"Catálogo de productos IT aprobados"              → Service Catalog
"Restringir qué recursos pueden lanzar los devs"  → Service Catalog
"Estandarizar despliegues"                         → Service Catalog
"Governance de qué se puede crear"                 → Service Catalog
```

**Service Catalog vs Control Tower:**
```
Service Catalog: controla QUÉ RECURSOS se pueden crear
Control Tower:   controla QUÉ CUENTAS se crean y cómo se gobiernan
```

---

### AWS Audit Manager
**Automatizar auditorías de compliance**

- Recolecta evidencia automáticamente de tus recursos AWS
- Frameworks pre-construidos (GDPR, HIPAA, PCI-DSS, SOC 2, etc.)
- Genera reportes para auditores
- Mapea controles a recursos

```
Para el examen:
  "Automatizar recolección de evidencia para auditorías" → Audit Manager
  "Preparar informes de compliance"                      → Audit Manager
```

---

### AWS Artifact
**Documentos de compliance de AWS**

- Descarga certificaciones de AWS (ISO 27001, SOC 1/2/3, PCI, HIPAA)
- Agreements (BAA para HIPAA, DPA para GDPR)
- No es un servicio activo, es un portal de documentos

```
Para el examen:
  "Descargar certificaciones de compliance de AWS"     → Artifact
  "BAA agreement para HIPAA"                            → Artifact
  "Demostrar que AWS cumple ISO 27001"                  → Artifact
```

---

## Almacenamiento y Análisis

### S3 Storage Lens
**Dashboard de análisis de todos tus S3 buckets**

- Vista global de todos tus buckets (multi-cuenta, multi-región)
- Métricas: tamaño, número de objetos, costes
- Análisis de configuración: versioning, cifrado, acceso público
- Recomendaciones de optimización de costes
- Dashboard gratuito con métricas básicas, avanzado de pago

```
Lo que responde:
  - "¿Cuántos buckets tengo y cuánto almacenan?"
  - "¿Cuáles NO tienen versioning activado?"
  - "¿Cuáles NO tienen cifrado?"
  - "¿Dónde puedo ahorrar dinero en S3?"
```

**Para el examen:**
```
"Analizar estado de todos los S3 buckets"              → S3 Storage Lens
"¿Qué buckets no tienen versioning?"                   → S3 Storage Lens
"Dashboard de métricas de S3 multi-cuenta"             → S3 Storage Lens
"¿Quién accedió a qué objeto?"                        → CloudTrail Data Events (NO Storage Lens)
```

**Storage Lens vs otros servicios de análisis:**
```
Storage Lens:     "¿Cómo ESTÁN mis buckets?"      (estado actual, configuración)
CloudTrail:       "¿Qué PASÓ?"                     (log de acciones)
AWS Config:       "¿Cumple la regla?"               (compliance de recursos)
IAM Access Analyzer: "¿Quién TIENE acceso?"         (permisos)
```

---

## Seguridad adicional

### Amazon Macie
**Descubrir y proteger datos sensibles en S3**

- Escanea S3 buscando PII (nombres, emails, tarjetas de crédito, SSN)
- Machine learning para detectar datos sensibles
- Alertas cuando encuentra datos expuestos
- Integración con Security Hub

```
Para el examen:
  "Detectar PII en S3"                                → Macie
  "Datos sensibles expuestos en S3"                    → Macie
  "Cumplir GDPR detectando datos personales en S3"     → Macie
```

---

### AWS Network Firewall
**Firewall managed para VPC**

- Inspección de tráfico a nivel de red (Layer 3-7)
- Filtrado por IP, puerto, protocolo, dominio
- Detección de intrusiones (IDS/IPS)
- Reglas stateful y stateless

**Para el examen:**
```
"Inspección profunda de tráfico de red"     → Network Firewall
"IDS/IPS en AWS"                             → Network Firewall
"Filtrar tráfico por dominio"                → Network Firewall
"Bloquear requests HTTP maliciosos"          → WAF (no Network Firewall)
```

**Network Firewall vs WAF vs Security Groups:**
```
Security Groups:   reglas básicas IP/puerto por instancia (Layer 4)
Network Firewall:  inspección profunda de toda la VPC (Layer 3-7)
WAF:               protección de apps web HTTP/HTTPS (Layer 7)
```

---

## Transferencia de datos

### AWS Transfer Family
**Servidores SFTP/FTPS/FTP managed que guardan en S3**

- Clientes externos suben ficheros por SFTP → van a S3 automáticamente
- No gestionas servidor FTP
- Compatible con clientes FTP existentes

```
Para el examen:
  "SFTP", "FTP", "FTPS" + "S3"              → Transfer Family
  "Clientes externos suben ficheros"         → Transfer Family
  "Migrar servidor FTP a AWS"                → Transfer Family
```

**Transfer Family vs DataSync vs Storage Gateway:**
```
Transfer Family:   terceros suben ficheros por SFTP → S3
DataSync:          mover datos de on-premise a AWS (migración)
Storage Gateway:   puente continuo on-premise ↔ AWS
```

---

## Integración de aplicaciones

### Amazon AppFlow
**Integración de datos entre SaaS y AWS sin código**

- Conecta Salesforce, Slack, SAP, Google Analytics, etc. con S3, Redshift, etc.
- Transferencias programadas o por eventos
- Transformaciones básicas (filtrar, mapear campos)
- Sin escribir código

```
Para el examen:
  "Integrar Salesforce con S3"                → AppFlow
  "Transferir datos de SaaS a AWS sin código"  → AppFlow
```

---

### AWS Glue DataBrew
**Preparación de datos visual sin código**

- Limpiar, normalizar, transformar datos
- Interfaz visual (no necesitas Spark/código)
- Recetas de transformación reutilizables

```
Para el examen:
  "ETL sin código", "data preparation visual"  → Glue DataBrew
  "ETL con código (Spark)"                      → Glue ETL
```

---

## Compute adicional

### AWS Wavelength
**Compute en el edge de redes 5G**

- EC2/ECS en data centers de operadoras telecom
- Ultra-baja latencia para apps móviles
- Gaming, AR/VR, video streaming en tiempo real

```
Para el examen:
  "Ultra-baja latencia para dispositivos 5G"   → Wavelength
  "Edge computing en red móvil"                 → Wavelength
```

---

### AWS Outposts
**Infraestructura AWS en tu data center**

- Rack físico de AWS en tu oficina/data center
- Mismas APIs de AWS (EC2, EBS, S3, RDS, EKS)
- Para cuando necesitas AWS pero con data residency on-premise

```
Para el examen:
  "AWS en tu propio data center"                → Outposts
  "Data residency on-premise con APIs AWS"      → Outposts
  "Latencia ultra-baja a sistemas on-premise"   → Outposts
```

---

### AWS Local Zones
**Extensión de una región AWS más cerca de usuarios**

- Mini data centers de AWS en ciudades específicas
- Para latencia baja sin montar Outposts
- Mismos servicios pero más cerca geográficamente

```
Para el examen:
  "Baja latencia en una ciudad específica"      → Local Zones
  "AWS más cerca de los usuarios finales"       → Local Zones o CloudFront
  "AWS en tu propio hardware"                   → Outposts (NO Local Zones)
```

---

## Machine Learning adicional

### Amazon Augmented AI (A2I)
**Revisión humana de predicciones de ML**

- Cuando un modelo ML no está seguro, pasa a revisión humana
- Workflows de revisión con personas
- Integración con Textract, Rekognition, SageMaker

```
Para el examen:
  "Revisión humana de predicciones ML"          → A2I
  "Human in the loop"                            → A2I
```

---

## Cheat sheet: servicios que se confunden

### Servicios de comunicación
```
SNS:      notificaciones simples (alerta, trigger)
SES:      email a escala (transaccional, marketing)
Pinpoint: marketing multicanal (SMS + email + push + journeys)
Connect:  call center (llamadas + chat de soporte)
```

### Servicios de análisis de estado
```
CloudTrail:         ¿Qué PASÓ? (log de acciones)
AWS Config:         ¿CUMPLE la regla? (compliance)
Storage Lens:       ¿Cómo ESTÁN mis S3? (métricas y config)
IAM Access Analyzer: ¿Quién TIENE acceso? (permisos)
Trusted Advisor:    ¿Qué puedo MEJORAR? (recomendaciones)
Security Hub:       ¿Cuál es mi POSTURA de seguridad? (dashboard)
```

### Servicios de protección
```
Security Groups:    firewall por instancia (IP/puerto)
NACLs:              firewall por subnet (stateless)
WAF:                protección HTTP/HTTPS (SQL injection, XSS)
Shield:             protección DDoS
Network Firewall:   inspección profunda de tráfico VPC
GuardDuty:          detección de amenazas (análisis inteligente)
Inspector:          escaneo de vulnerabilidades (EC2, containers)
Macie:              detección de datos sensibles en S3
```

### Servicios de transferencia
```
DataSync:           mover datos on-premise → AWS (migración)
Storage Gateway:    puente continuo on-premise ↔ AWS
Transfer Family:    SFTP/FTP → S3 (terceros suben ficheros)
Snow Family:        migración física (TB/PB en dispositivo)
DMS:                migrar bases de datos
MGN:                migrar servidores (lift & shift)
```

### Servicios de governance
```
Organizations:      agrupar cuentas, billing, SCPs
Control Tower:      Landing Zone, Account Factory, guardrails
RAM:                compartir recursos entre cuentas
Service Catalog:    catálogo de productos IT aprobados
Artifact:           documentos de compliance de AWS
Audit Manager:      automatizar recolección de evidencia
```

### Servicios de edge/ubicación
```
CloudFront:         CDN global (caché de contenido)
Global Accelerator: routing optimizado a nivel de red
Wavelength:         compute en red 5G
Outposts:           AWS en tu data center (tu hardware)
Local Zones:        AWS más cerca de una ciudad (hardware AWS)
```
