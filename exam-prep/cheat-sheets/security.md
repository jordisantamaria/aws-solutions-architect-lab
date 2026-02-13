# Security - Cheat Sheet Rápido

## Lógica de Evaluación de Políticas IAM

```
                         ┌───────────────────────┐
                         │  ¿Hay un DENY         │
                         │  explícito?            │
                         └───────┬───────────────┘
                                 │
                    ┌────────────┼────────────┐
                    │ SÍ                      │ NO
                    ▼                         ▼
            ┌──────────────┐      ┌─────────────────────┐
            │  DENEGADO    │      │ ¿Hay un ALLOW       │
            │  (siempre)   │      │  explícito?          │
            └──────────────┘      └───────┬─────────────┘
                                          │
                             ┌────────────┼────────────┐
                             │ SÍ                      │ NO
                             ▼                         ▼
                     ┌──────────────┐         ┌──────────────┐
                     │  PERMITIDO   │         │  DENEGADO    │
                     │              │         │  (implícito) │
                     └──────────────┘         └──────────────┘
```

### Orden de evaluación completo

```
1. Deny explícito en cualquier política       → DENY (fin)
2. SCP de Organizations (si aplica)           → Si no hay ALLOW → DENY
3. Resource-based policy                      → ALLOW? (puede permitir cross-account)
4. Identity-based policy                      → ALLOW?
5. Permissions boundary (si aplica)           → Limita el máximo
6. Session policy (si aplica)                 → Limita la sesión
7. Si nada permite explícitamente             → DENY implícito
```

> **Reglas clave examen:**
> - **Deny explícito SIEMPRE gana** sobre cualquier Allow.
> - **Todo está denegado por defecto** (implicit deny) hasta que se permita explícitamente.
> - **SCP** no otorga permisos, solo limita el máximo (guarda de seguridad).
> - **Permissions Boundary** limita los permisos máximos que puede tener un usuario/rol.
> - **Cross-account:** Necesita permiso en AMBOS lados (resource policy + identity policy).

---

## Cifrado At Rest vs In Transit

### Cifrado en Reposo (At Rest)

| Servicio | Cifrado por defecto | Opciones |
|----------|-------------------|----------|
| **S3** | **Sí** (SSE-S3 desde 2023) | SSE-S3, SSE-KMS, SSE-C, Client-Side |
| **EBS** | Opcional (se puede forzar por cuenta) | AES-256 con KMS (aws/ebs o CMK) |
| **RDS** | Opcional (al crear) | KMS. **No se puede activar después de crear** — crear snapshot, copiar cifrada, restaurar |
| **Aurora** | Opcional (al crear) | KMS. Misma restricción que RDS |
| **DynamoDB** | **Sí** (siempre cifrado) | AWS owned key, AWS managed key (aws/dynamodb), o CMK |
| **EFS** | Opcional (al crear) | KMS |
| **Redshift** | Opcional | KMS o CloudHSM |
| **ElastiCache** | Opcional | At-rest encryption con KMS |
| **Lambda** | **Sí** (variables de entorno) | KMS para variables de entorno |
| **SQS** | Opcional | SSE con KMS |
| **Kinesis** | Opcional | KMS server-side encryption |

### Cifrado en Tránsito (In Transit)

| Método | Servicio/Uso |
|--------|-------------|
| **TLS/SSL (HTTPS)** | Todos los endpoints de API de AWS. ALB/NLB terminan SSL. ACM para certificados |
| **VPN IPSec** | Site-to-Site VPN — cifrado automático en los túneles |
| **VPN sobre Direct Connect** | DX no cifra por defecto; añadir VPN IPSec encima para cifrado |
| **SSL en base de datos** | Forzar SSL en RDS con `rds.force_ssl = 1` (PostgreSQL) o parámetros similares |
| **Redis AUTH + TLS** | ElastiCache in-transit encryption |

> **Clave examen:** "Cifrar datos en tránsito sobre Direct Connect" → **VPN sobre DX** (DX por sí solo NO cifra).

---

## KMS vs CloudHSM vs Secrets Manager vs Parameter Store

| Característica | KMS | CloudHSM | Secrets Manager | Parameter Store |
|---------------|-----|----------|-----------------|----------------|
| **Tipo** | Gestión de claves | Hardware Security Module | Gestión de secretos | Almacén de configuración |
| **Gestión** | AWS gestiona hardware | **Tú gestionas** el HSM | AWS gestionado | AWS gestionado |
| **Modelo** | Shared tenancy | **Single-tenant** dedicado | N/A | N/A |
| **Claves** | Simétricas y asimétricas | Simétricas y asimétricas | N/A | N/A |
| **FIPS 140-2** | Level 2 | **Level 3** | Usa KMS internamente | Usa KMS internamente |
| **Integración AWS** | Nativa (S3, EBS, RDS, etc.) | Vía KMS custom key store | Rotación automática nativa | Manual / Lambda para rotación |
| **Rotación** | Automática (anual) para CMKs | Manual | **Automática** (configurable: días) | Lambda custom (no nativo) |
| **Costo** | $1/clave/mes + API calls | ~$1.50/hora/HSM | $0.40/secreto/mes + API | Gratis (standard) / $0.05 avanzado |
| **Caso de uso** | Cifrado general de servicios AWS | Compliance estricto, control total del HSM | Credenciales BD, API keys con rotación | Config de apps, parámetros, valores simples |

> **Reglas examen:**
> - "Cifrado de servicios AWS" → **KMS**
> - "Compliance FIPS 140-2 **Level 3**" o "HSM dedicado" → **CloudHSM**
> - "Rotar credenciales de base de datos automáticamente" → **Secrets Manager**
> - "Almacenar configuración de la aplicación" → **Parameter Store** (más económico)
> - "Secreto + rotación automática" → **Secrets Manager** (no Parameter Store)

---

## WAF vs Shield vs Shield Advanced

| Característica | WAF | Shield Standard | Shield Advanced |
|---------------|-----|----------------|-----------------|
| **Tipo** | Web Application Firewall | Protección DDoS básica | Protección DDoS avanzada |
| **Capa** | Layer 7 (HTTP/HTTPS) | Layer 3/4 | Layer 3/4 **y** Layer 7 |
| **Costo** | Por reglas y requests | **Gratis** (incluido) | $3,000/mes + datos |
| **Protección** | SQL injection, XSS, geo-blocking, rate limiting, IP block | SYN flood, UDP reflection, DNS amplification | Todo de Standard + ataques sofisticados DDoS |
| **Recursos protegidos** | ALB, API Gateway, CloudFront, AppSync, Cognito | Todos los recursos AWS | CloudFront, ALB, NLB, Elastic IP, Global Accelerator |
| **Response Team** | No | No | **Sí** — AWS DDoS Response Team (DRT) 24/7 |
| **Protección de costos** | No | No | **Sí** — crédito por scaling causado por DDoS |
| **Visibilidad** | Logs, métricas | Métricas básicas | Métricas avanzadas, dashboards en tiempo real |

> **Reglas examen:**
> - "Bloquear SQL injection o XSS" → **WAF**
> - "Protección DDoS Layer 3/4 básica" → **Shield Standard** (gratis, siempre activo)
> - "Protección DDoS avanzada con equipo de respuesta" → **Shield Advanced**
> - "Rate limiting de IPs" → **WAF** (rate-based rules)
> - "Geo-blocking (bloquear países)" → **WAF** o **CloudFront geo restriction**

---

## Cognito: User Pools vs Identity Pools

| Característica | Cognito User Pools | Cognito Identity Pools |
|---------------|-------------------|----------------------|
| **Función** | **Autenticación** (quién eres) | **Autorización** (qué puedes hacer en AWS) |
| **Resultado** | Token JWT (ID token, Access token) | **Credenciales AWS temporales** (STS) |
| **Flujo** | Sign-up, sign-in, MFA, password recovery | Federar identidad → obtener IAM role temporal |
| **Proveedores** | Username/password, SAML, OIDC, social (Google, Facebook, Apple) | User Pools, SAML, OIDC, social, **identidades no autenticadas** |
| **Caso de uso** | Login de aplicación web/mobile, gestión de usuarios | Acceso directo a servicios AWS (S3, DynamoDB) desde app |
| **Integración** | ALB, API Gateway, Lambda | IAM roles, S3, DynamoDB, cualquier servicio AWS |

```
Flujo típico combinado:

  Usuario ──→ Cognito User Pool ──→ JWT Token
                                        │
                                        ▼
                              Cognito Identity Pool ──→ Credenciales AWS (IAM Role)
                                                              │
                                                              ▼
                                                    S3, DynamoDB, etc.
```

> **Clave examen:**
> - "Autenticación de usuarios en la app" → **User Pool**
> - "Dar acceso temporal a servicios AWS a usuarios" → **Identity Pool**
> - "Login con Google/Facebook en tu app" → **User Pool** (como proveedor social)
> - "Acceso a S3 desde mobile app" → **Identity Pool** (credenciales temporales)
> - ALB puede integrar **User Pool** directamente para autenticación.

---

## Servicios de Seguridad AWS

| Servicio | Descripción (1 línea) |
|----------|----------------------|
| **GuardDuty** | Detección inteligente de amenazas analizando CloudTrail, VPC Flow Logs, DNS logs y S3 data events con ML |
| **Inspector** | Evaluación automatizada de vulnerabilidades en **EC2, ECR images y Lambda** — escaneo continuo de CVEs |
| **Macie** | Descubrimiento y protección de **datos sensibles (PII)** en S3 usando ML — detecta datos expuestos |
| **Detective** | Investigación y análisis de la **causa raíz** de hallazgos de seguridad — correlaciona datos de GuardDuty, CloudTrail, VPC Flow Logs |
| **Security Hub** | Panel centralizado de seguridad — agrega hallazgos de GuardDuty, Inspector, Macie, Firewall Manager, etc. |
| **CloudTrail** | Registra **todas las llamadas API** en tu cuenta AWS — auditoría, compliance, investigación forense |
| **Config** | Evalúa la **configuración** de recursos AWS contra reglas — detecta desviaciones de compliance |
| **Firewall Manager** | Gestión centralizada de WAF, Shield Advanced, Security Groups, NACLs a nivel de **AWS Organizations** |
| **IAM Access Analyzer** | Identifica recursos compartidos externamente y valida políticas IAM — detecta acceso público no intencionado |
| **Audit Manager** | Automatiza recopilación de evidencia para auditorías de compliance (SOC2, PCI-DSS, HIPAA, etc.) |

```
Flujo típico de seguridad:

  CloudTrail (registra APIs) ──→ GuardDuty (detecta amenazas) ──→ Security Hub (centraliza)
                                                                        │
  Inspector (vulnerabilidades)  ──→ Security Hub ◄────── Macie (datos sensibles en S3)
                                         │
                                         ▼
                                 EventBridge ──→ SNS / Lambda (remediación automática)
```

> **Reglas examen:**
> - "Detectar amenazas en la cuenta" → **GuardDuty**
> - "Escanear vulnerabilidades en EC2/Lambda" → **Inspector**
> - "Encontrar PII en S3" → **Macie**
> - "Investigar causa raíz de un incidente" → **Detective**
> - "Centralizar hallazgos de seguridad" → **Security Hub**
> - "Auditar llamadas API" → **CloudTrail**
> - "Evaluar compliance de configuración" → **Config**

---

## Resumen de Decisiones Rápidas - Security

```
PREGUNTA DEL EXAMEN                                    → RESPUESTA
────────────────────────────────────────────────────────────────────
"Cifrado de servicios AWS general"                      → KMS
"HSM dedicado / FIPS 140-2 Level 3"                     → CloudHSM
"Rotar credenciales de BD automáticamente"              → Secrets Manager
"Almacenar config/parámetros de la app"                 → Parameter Store
"Bloquear SQL injection / XSS"                          → WAF
"Protección DDoS con equipo de respuesta"               → Shield Advanced
"Login de usuarios en app web/mobile"                   → Cognito User Pools
"Acceso temporal a S3 desde app mobile"                 → Cognito Identity Pools
"Detectar amenazas con ML"                              → GuardDuty
"Encontrar datos sensibles en S3"                       → Macie
"Escanear vulnerabilidades en EC2"                      → Inspector
"Centralizar hallazgos de seguridad"                    → Security Hub
"Auditar todas las llamadas API"                        → CloudTrail
"Cross-account access"                                  → IAM Role + Resource Policy
"Limitar permisos máximos de un usuario"                → Permissions Boundary
"Limitar permisos de toda una cuenta/OU"                → SCP (Organizations)
```
