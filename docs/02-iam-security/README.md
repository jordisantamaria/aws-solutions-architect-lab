# IAM y Seguridad en AWS

## Tabla de Contenidos

- [IAM Fundamentals](#iam-fundamentals)
- [Tipos de Políticas IAM](#tipos-de-políticas-iam)
- [Lógica de Evaluación de Políticas](#lógica-de-evaluación-de-políticas)
- [IAM Best Practices](#iam-best-practices)
- [AWS Organizations](#aws-organizations)
- [AWS Control Tower](#aws-control-tower)
- [AWS RAM (Resource Access Manager)](#aws-ram-resource-access-manager)
- [STS y AssumeRole](#sts-y-assumerole)
- [AWS IAM Identity Center (SSO)](#aws-iam-identity-center-sso)
- [AWS KMS](#aws-kms)
- [Secrets Manager vs Parameter Store](#secrets-manager-vs-parameter-store)
- [AWS CloudHSM](#aws-cloudhsm)
- [AWS WAF, Shield y Shield Advanced](#aws-waf-shield-y-shield-advanced)
- [Amazon Cognito](#amazon-cognito)
- [AWS Directory Service (Active Directory)](#aws-directory-service-active-directory)
- [Servicios de Detección y Seguridad](#servicios-de-detección-y-seguridad)
- [AWS Certificate Manager (ACM)](#aws-certificate-manager-acm)
- [Security Exam Tips](#security-exam-tips)

---

## IAM Fundamentals

IAM (Identity and Access Management) es un servicio **global** (no regional) que controla quién puede hacer qué en tu cuenta de AWS.

### Componentes principales

#### Users (Usuarios)

- Representan una persona o aplicación que interactúa con AWS.
- Pueden tener credenciales de consola (usuario/contraseña) y/o credenciales de acceso programático (Access Key ID + Secret Access Key).
- Un usuario nuevo **no tiene ningún permiso** por defecto (implicit deny).
- Límite: 5,000 usuarios IAM por cuenta.

#### Groups (Grupos)

- Colección de usuarios IAM.
- Permiten asignar políticas a múltiples usuarios de una sola vez.
- Un usuario puede pertenecer a **múltiples grupos** (máximo 10).
- Los grupos **no pueden contener otros grupos** (no anidamiento).
- No existe un "grupo por defecto" que incluya a todos los usuarios.
- Los grupos **no son identidades** (no puedes referenciar un grupo en una resource-based policy como principal).

#### Roles

- Identidad IAM con permisos, pero **sin credenciales a largo plazo**.
- Se "asumen" temporalmente por usuarios, aplicaciones o servicios de AWS.
- Casos de uso principales:
  - **EC2 Instance Role**: Dar permisos a una instancia EC2 para acceder a otros servicios.
  - **Cross-account access**: Permitir que una cuenta externa acceda a recursos de tu cuenta.
  - **Service Role**: Permitir que un servicio AWS (Lambda, ECS) acceda a otros recursos.
  - **Federación**: Usuarios externos (AD, SAML, OIDC) que asumen un rol.

#### Policies (Políticas)

- Documentos JSON que definen permisos.
- Estructura de una política:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowS3Read",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::my-bucket",
        "arn:aws:s3:::my-bucket/*"
      ],
      "Condition": {
        "IpAddress": {
          "aws:SourceIp": "192.168.1.0/24"
        }
      }
    }
  ]
}
```

- **Version**: Siempre usar `"2012-10-17"` (versión actual).
- **Effect**: `Allow` o `Deny`.
- **Action**: Las acciones de API permitidas o denegadas.
- **Resource**: Los recursos afectados (ARN).
- **Condition** (opcional): Condiciones que deben cumplirse.

---

## Tipos de Políticas IAM

| Tipo de Política | Adjunta a | Descripción | Ejemplo |
|-----------------|-----------|-------------|---------|
| **Identity-based (basada en identidad)** | Users, Groups, Roles | Define qué puede hacer la identidad | Política que permite leer S3 adjunta a un rol |
| **Resource-based (basada en recurso)** | Recursos (S3, SQS, KMS, etc.) | Define quién puede acceder al recurso | Bucket policy de S3, Key policy de KMS |
| **Permission Boundary** | Users, Roles | Límite máximo de permisos que una identidad puede tener | Limitar a un desarrollador a solo servicios de us-east-1 |
| **SCP (Service Control Policy)** | AWS Organization (OU o cuenta) | Límite máximo de permisos para toda la cuenta/OU | Prohibir crear recursos fuera de EU |
| **Session Policy** | Sesiones de STS | Limita permisos de una sesión temporal de AssumeRole | Restringir acceso durante una sesión federada |
| **ACL (Access Control List)** | Recursos (S3, VPC) | Control de acceso cross-account sin formato JSON policy | S3 ACL (legacy, no recomendado) |

### Identity-based Policies: Managed vs Inline

| Tipo | Descripción | Recomendación |
|------|-------------|---------------|
| **AWS Managed** | Creadas y mantenidas por AWS | Usar para permisos comunes (ReadOnlyAccess, etc.) |
| **Customer Managed** | Creadas por ti, reutilizables | Recomendado para políticas personalizadas |
| **Inline** | Embebida directamente en un usuario, grupo o rol | Solo para relación estricta 1:1, no recomendado generalmente |

### Permission Boundaries

- No otorgan permisos por sí solas; solo **limitan** los permisos máximos.
- Los permisos efectivos son la **intersección** entre la identity-based policy y la permission boundary.
- Caso de uso: Permitir a desarrolladores crear roles IAM pero asegurando que nunca puedan exceder ciertos permisos.
- Solo aplican a usuarios y roles (no a grupos).

---

## Lógica de Evaluación de Políticas

El orden de evaluación de políticas en AWS sigue esta lógica:

```
1. Explicit Deny en cualquier política  -->  DENY (siempre gana)
        |
        v (si no hay explicit deny)
2. SCP permite la acción?  -->  si NO --> DENY
        |
        v (si SCP permite)
3. Resource-based policy permite (con Principal)?  -->  si SÍ --> ALLOW
        |
        v (si no hay resource-based o no aplica)
4. Permission Boundary permite?  -->  si NO --> DENY
        |
        v (si Permission Boundary permite)
5. Session Policy permite?  -->  si NO --> DENY
        |
        v (si Session Policy permite)
6. Identity-based policy permite?  -->  si SÍ --> ALLOW
        |
        v (si ninguna política permite)
7. DENY implícito (default)
```

### Regla de oro

> **Explicit Deny > Explicit Allow > Implicit Deny (default)**

### Evaluación cross-account

Cuando un principal de la Cuenta A intenta acceder a un recurso de la Cuenta B:
- La Cuenta A debe tener una **identity-based policy** que permita la acción.
- La Cuenta B debe tener una **resource-based policy** que permita al principal de la Cuenta A.
- **Ambas** deben permitir; cualquiera que deniegue prevalece.

> **Excepción:** Si el recurso de Cuenta B tiene una resource-based policy que especifica el principal de Cuenta A directamente, y es misma-cuenta (no cross-account), no se necesita identity-based policy.

---

## IAM Best Practices

1. **No usar la cuenta root** para tareas diarias. Protegerla con MFA de hardware.
2. **Crear usuarios IAM individuales** - No compartir credenciales.
3. **Usar grupos** para asignar permisos.
4. **Principio de menor privilegio (Least Privilege)** - Dar solo los permisos necesarios.
5. **Habilitar MFA** para todos los usuarios, especialmente los privilegiados.
6. **Usar roles** en lugar de access keys para aplicaciones en EC2/Lambda/ECS.
7. **Rotar credenciales** regularmente (access keys).
8. **Usar políticas de contraseña** fuertes (longitud mínima, complejidad, rotación).
9. **Usar IAM Access Analyzer** para identificar recursos compartidos externamente.
10. **Monitorizar con CloudTrail** todas las acciones de IAM.
11. **Nunca embeber access keys** en código. Usar roles o Secrets Manager.
12. **Usar Permission Boundaries** para delegar la gestión de IAM de forma segura.

---

## AWS Organizations

AWS Organizations permite gestionar múltiples cuentas AWS centralmente.

### Conceptos clave

- **Management Account** (antes "Master Account"): La cuenta raíz de la organización. No le aplican los SCPs.
- **Member Accounts**: Las cuentas que pertenecen a la organización.
- **Organizational Units (OUs)**: Agrupaciones lógicas de cuentas (pueden anidarse).
- **Root**: El contenedor superior de la organización (contiene todas las OUs y cuentas).

### Service Control Policies (SCPs)

- Definen el **máximo de permisos** disponibles para las cuentas de una OU o cuenta individual.
- **No otorgan permisos**, solo los restringen.
- No aplican a la Management Account.
- Aplican a **todos los usuarios y roles** de la cuenta (incluido el root de la cuenta).
- No aplican a service-linked roles.
- Deben tener un `Allow` explícito (por defecto, si usas "deny list strategy", la SCP `FullAWSAccess` está adjunta).

### Estrategias de SCP

| Estrategia | Descripción | Uso |
|-----------|-------------|-----|
| **Deny List** (default) | `FullAWSAccess` adjunta + SCPs de deny explícito | Bloquear servicios/acciones específicas |
| **Allow List** | Quitar `FullAWSAccess` + SCPs de allow explícito | Solo permitir servicios específicos (más restrictivo) |

### Consolidated Billing (Facturación consolidada)

- Una sola factura para todas las cuentas de la organización.
- **Descuentos por volumen** se agregan entre cuentas (ej: S3, EC2).
- Las **Reserved Instances** se comparten entre cuentas de la organización (a menos que se desactive).
- Permite rastrear costes por cuenta individual con AWS Cost Explorer.

---

## AWS Control Tower

Servicio para configurar y gobernar un **entorno multi-cuenta seguro** basado en mejores prácticas. Se construye sobre AWS Organizations.

### Qué problema resuelve

Configurar un entorno multi-cuenta manualmente requiere: crear cuentas, configurar SSO, aplicar SCPs, configurar logging centralizado, etc. **Control Tower automatiza todo esto**.

### Componentes principales

| Componente | Descripción |
|-----------|-------------|
| **Landing Zone** | Entorno multi-cuenta pre-configurado con mejores prácticas. Incluye cuentas de logging, audit, y la estructura de OUs |
| **Account Factory** | Provisión automatizada de nuevas cuentas AWS con configuración estandarizada. Usa AWS Service Catalog bajo el capó |
| **Guardrails (Controls)** | Reglas de gobernanza aplicadas a las OUs. Pueden ser preventivas (SCP) o detectivas (AWS Config Rules) |
| **Dashboard** | Vista centralizada del estado de compliance de todas las cuentas y guardrails |

### Tipos de Guardrails

| Tipo | Mecanismo | Ejemplo |
|------|-----------|---------|
| **Preventive** | SCP (Service Control Policy) | "No permitir eliminar CloudTrail logs" |
| **Detective** | AWS Config Rules | "Detectar si un bucket S3 es público" |
| **Proactive** | CloudFormation Hooks | "Bloquear despliegue de recursos no conformes antes de crearlos" |

### Niveles de Guardrails

| Nivel | Descripción |
|-------|-------------|
| **Mandatory** | Siempre habilitados. No se pueden desactivar (ej: prohibir cambios en la cuenta de logging) |
| **Strongly Recommended** | Basados en mejores prácticas de AWS (ej: habilitar cifrado en EBS) |
| **Elective** | Opcionales, para requisitos específicos de la empresa |

### Estructura de Landing Zone

```
Management Account (root)
├── Security OU
│   ├── Log Archive Account      → Almacena CloudTrail y Config logs de TODAS las cuentas
│   └── Audit Account            → Acceso cross-account para auditoría y compliance
├── Sandbox OU
│   └── Dev accounts             → Para experimentación con guardrails relajados
├── Production OU
│   └── Prod accounts            → Guardrails estrictos
└── Guardrails aplicados por OU
```

### Control Tower vs Organizations

| Característica | Organizations (solo) | Control Tower |
|---------------|---------------------|---------------|
| **Crear cuentas** | Manual o API | Account Factory (automatizado, estandarizado) |
| **Guardrails** | SCPs manuales | Guardrails predefinidos (preventivos + detectivos) |
| **Logging centralizado** | Configurar manualmente | Pre-configurado (Log Archive Account) |
| **Dashboard de compliance** | No | Sí |
| **Best practices automáticas** | No | Sí (Landing Zone) |

> **Tip para el examen:** Si la pregunta menciona "configurar entorno multi-cuenta con mejores prácticas", "landing zone", "gobernanza multi-cuenta automatizada", "Account Factory" → **Control Tower**. Si solo necesitas agrupar cuentas y aplicar SCPs manualmente → **Organizations**. Control Tower usa Organizations bajo el capó.

---

## AWS RAM (Resource Access Manager)

Servicio para **compartir recursos AWS entre cuentas** de forma segura, sin necesidad de crear duplicados.

### Recursos que se pueden compartir

| Recurso | Caso de uso |
|---------|------------|
| **VPC Subnets** | Cuentas diferentes lanzan recursos en subnets compartidas de una VPC central |
| **Transit Gateway** | Compartir un Transit Gateway entre cuentas sin que cada una cree el suyo |
| **Route 53 Resolver Rules** | Compartir reglas de resolución DNS |
| **License Manager** | Compartir configuraciones de licencias |
| **Aurora DB Cluster** | Compartir un cluster Aurora entre cuentas |
| **AWS CodeBuild Projects** | Compartir proyectos de build |
| **EC2 (Dedicated Hosts, Capacity Reservations)** | Compartir hosts dedicados |

### Caso de uso más común: VPC Subnet Sharing

```
Cuenta A (Network Account): Crea la VPC y las subnets
    │
    ├── Comparte subnet-private-1 via RAM → Cuenta B
    ├── Comparte subnet-private-2 via RAM → Cuenta C
    │
    ▼
Cuenta B: Lanza EC2/RDS/Lambda en subnet-private-1 (de la VPC de Cuenta A)
Cuenta C: Lanza EC2/RDS/Lambda en subnet-private-2 (de la VPC de Cuenta A)
```

- Los recursos de cada cuenta están **aislados** (cada cuenta gestiona sus security groups, instancias, etc.).
- La VPC y las subnets las **gestiona solo la cuenta propietaria**.
- Reduce la complejidad de VPC peering entre muchas cuentas.

### RAM con AWS Organizations

- Si las cuentas están en la misma Organization, RAM puede compartir automáticamente sin invitaciones.
- Si no están en la misma Organization, se envía una invitación que la otra cuenta debe aceptar.

### RAM vs otras alternativas

| Necesidad | Solución |
|-----------|---------|
| "Compartir una subnet entre cuentas" | **RAM** |
| "Compartir un Transit Gateway entre cuentas" | **RAM** |
| "Acceder a recursos de otra cuenta via API" | **STS AssumeRole (cross-account)** |
| "Compartir un bucket S3 con otra cuenta" | **S3 Bucket Policy** (no necesitas RAM) |
| "Compartir una AMI con otra cuenta" | **AMI Sharing** (no necesitas RAM) |

> **Tip para el examen:** Si la pregunta menciona "compartir VPC subnets entre cuentas", "compartir Transit Gateway entre cuentas", "compartir recursos entre cuentas de una Organization" → **RAM**. No confundir con cross-account IAM roles (STS AssumeRole), que es para acceder a APIs, no para compartir recursos de red.

---

## STS y AssumeRole

AWS Security Token Service (STS) es un servicio global que permite obtener **credenciales temporales** y de privilegio limitado.

### Operaciones principales de STS

| Operación | Descripción | Caso de uso |
|-----------|-------------|-------------|
| **AssumeRole** | Asumir un rol IAM (misma o diferente cuenta) | Cross-account access, roles de servicio |
| **AssumeRoleWithSAML** | Asumir rol con autenticación SAML 2.0 | Federación con Active Directory / IdP corporativo |
| **AssumeRoleWithWebIdentity** | Asumir rol con token de IdP web (Google, Facebook, Amazon) | Apps móviles (aunque se recomienda Cognito) |
| **GetSessionToken** | Obtener credenciales temporales para usuario IAM | Acceso programático con MFA |
| **GetFederationToken** | Credenciales temporales para un usuario federado | Proxy federado personalizado |

### Cross-Account Access con AssumeRole

**Escenario**: Un usuario de la Cuenta A necesita acceder a un bucket S3 en la Cuenta B.

1. **Cuenta B**: Crear un rol IAM con una **trust policy** que permita a la Cuenta A asumir el rol.
2. **Cuenta B**: El rol tiene una **permission policy** que permite acceso al bucket S3.
3. **Cuenta A**: El usuario tiene una policy que permite ejecutar `sts:AssumeRole` sobre el ARN del rol de Cuenta B.
4. El usuario llama a `sts:AssumeRole` y recibe credenciales temporales.
5. Usa esas credenciales para acceder al bucket S3 de Cuenta B.

### Credenciales temporales

- Incluyen: Access Key ID, Secret Access Key y **Session Token**.
- Duración configurable (15 minutos a 12 horas según el caso).
- No se pueden revocar individualmente, pero el rol puede tener su policy modificada.

### Federation + IAM Policy Variables (acceso per-user a S3)

Escenario típico del examen: 1000+ empleados de una empresa con AD corporativo necesitan acceso cada uno a su propia carpeta en S3, con SSO.

**No creas 1000 IAM users.** Usas federation + un solo IAM Role con policy variables:

```
Empleado ──► AD corporativo (SSO)
                 │
                 ▼
         Federation proxy / IdP (SAML 2.0)
                 │
                 ▼
         STS: AssumeRoleWithSAML → credenciales temporales
                 │
                 ▼
         IAM Role con policy variable → acceso solo a su carpeta en S3
```

**La policy usa `${aws:userid}` que se reemplaza automáticamente** por la identidad del usuario federado:

```json
{
  "Effect": "Allow",
  "Action": ["s3:GetObject", "s3:PutObject"],
  "Resource": "arn:aws:s3:::empresa-docs/${aws:userid}/*"
}
```

Cuando Juan se autentica, `${aws:userid}` se resuelve a `juan` → solo puede acceder a `s3://empresa-docs/juan/*`. María ve solo `maria/*`. **Un solo Role, una sola policy, miles de usuarios.**

**Variables de policy disponibles:**

| Variable | Se reemplaza por | Ejemplo |
|---|---|---|
| `${aws:userid}` | ID del usuario (o role-id:session-name en federation) | `AROA12345:juan` |
| `${aws:username}` | Nombre del usuario IAM | `juan` |
| `${aws:PrincipalTag/department}` | Tag de la sesión federada | `ingenieria` |
| `${s3:prefix}` | Prefijo solicitado en la operación S3 | `home/juan/` |

> **Tip para el examen:** Si la pregunta dice "miles de usuarios corporativos + SSO + carpeta individual en S3" → **Federation (SAML/IdP) + STS + IAM Role con policy variables**. Nunca crear un IAM user por empleado.

---

## AWS IAM Identity Center (SSO)

Anteriormente llamado **AWS Single Sign-On (SSO)**, es el servicio recomendado para gestionar acceso de personas a múltiples cuentas de AWS y aplicaciones de negocio.

### Características

- **Un único punto de acceso** para todas las cuentas de la organización y apps SAML 2.0.
- Se integra con **AWS Organizations** para gestión centralizada.
- **Identity Sources** soportados:
  - Identity Center directory (built-in).
  - Active Directory (AWS Managed AD o AD Connector).
  - Proveedores SAML 2.0 externos (Okta, Azure AD, etc.).
- **Permission Sets**: Colecciones de políticas que definen el acceso a una cuenta AWS.
- Proporciona un **portal web** donde los usuarios ven todas las cuentas y roles disponibles.

### Flujo de acceso

1. Usuario accede al portal de IAM Identity Center.
2. Se autentica contra el Identity Source configurado.
3. Ve las cuentas AWS y Permission Sets asignados.
4. Selecciona cuenta + Permission Set y obtiene credenciales temporales de STS.

> **Tip para el examen:** Si preguntan cómo dar acceso centralizado a múltiples cuentas AWS a empleados corporativos, la respuesta es **IAM Identity Center**.

---

## AWS KMS

AWS Key Management Service (KMS) es un servicio gestionado para crear y controlar las claves de cifrado utilizadas para proteger tus datos.

### Tipos de claves

| Tipo | Descripción | Rotación | Coste |
|------|-------------|----------|-------|
| **AWS Owned Keys** | AWS las gestiona internamente (SSE-S3) | Automática (varía) | Gratis |
| **AWS Managed Keys** | AWS las crea y gestiona por ti (aws/service-name) | Automática cada ~1 año | Gratis (pero cobran por uso) |
| **Customer Managed Keys (CMK)** | Tú las creas, gestionas y controlas | Automática (opcional, cada ~1 año) o manual | $1/mes + $0.03 por 10,000 solicitudes |

### Envelope Encryption (Cifrado de sobre)

KMS puede cifrar datos de hasta **4 KB** directamente. Para datos más grandes, se usa **envelope encryption**:

1. Llamas a KMS `GenerateDataKey` API.
2. KMS devuelve una **Data Key en texto plano** + una **copia cifrada** de la Data Key.
3. Usas la Data Key en texto plano para cifrar tus datos (client-side).
4. Almacenas la Data Key cifrada junto con los datos cifrados.
5. Descartas la Data Key en texto plano de memoria.
6. Para descifrar: envías la Data Key cifrada a KMS (`Decrypt`), recibes la Data Key en texto plano y descifras los datos.

> **Por qué envelope encryption?** Evita enviar grandes volúmenes de datos a KMS (límite 4 KB). Solo envías la clave, no los datos.

### Key Policies

- Toda CMK **debe** tener una key policy (no hay default global).
- La **default key policy** permite a la cuenta root (y por ende a los usuarios IAM con permisos) gestionar la clave.
- Puedes crear **custom key policies** para definir quién puede administrar y quién puede usar la clave.
- Se combinan con IAM policies para controlar acceso a la clave.

### Key Rotation

| Tipo de clave | Rotación automática | Periodo |
|--------------|-------------------|---------|
| AWS Managed Key | Obligatoria | Cada ~1 año |
| Customer Managed Key (simétrica) | Opcional (habilitada manualmente) | Cada ~1 año |
| Customer Managed Key (asimétrica) | No soportada | Manual |
| Imported Key Material | No soportada | Manual |

- Cuando se rota automáticamente, KMS mantiene las versiones antiguas de la clave para descifrar datos anteriores.
- El Key ID no cambia al rotar automáticamente.
- La rotación manual crea una nueva clave y requiere actualizar alias.

### Multi-Region Keys

- Réplicas de una clave KMS en múltiples regiones.
- Mismo material de clave (key material) en todas las réplicas.
- Datos cifrados en una región pueden descifrarse en otra.
- Caso de uso: cifrado client-side de datos que se replican entre regiones (DynamoDB Global Tables, Aurora Global).

---

## Secrets Manager vs Parameter Store

| Característica | AWS Secrets Manager | AWS Systems Manager Parameter Store |
|---------------|--------------------|------------------------------------|
| **Propósito principal** | Gestión de secretos (credenciales BD, API keys) | Almacén de configuración y secretos |
| **Rotación automática** | Sí (integración nativa con Lambda para RDS, Redshift, DocumentDB) | No (puedes implementarla tú con Lambda + EventBridge) |
| **Cifrado** | Siempre cifrado con KMS | Opcional (SecureString usa KMS) |
| **Versionado** | Sí | Sí |
| **Cross-account access** | Sí (via resource-based policy) | No directamente (necesitas capa adicional) |
| **Tipos de datos** | Texto/binario | String, StringList, SecureString |
| **Jerarquía** | No | Sí (paths: /dev/db/password) |
| **Coste** | $0.40 por secreto/mes + $0.05 por 10,000 llamadas API | Gratis (Standard) o $0.05 por parámetro avanzado/mes |
| **Tamaño máximo** | 64 KB | 4 KB (Standard) o 8 KB (Advanced) |
| **Throughput** | Alto (sin límite práctico) | Standard: 40 TPS / Advanced: hasta 10,000 TPS |
| **Integración con CloudFormation** | Sí (dynamic reference) | Sí (dynamic reference) |

> **Tip para el examen:** Si la pregunta menciona **rotación automática de credenciales de base de datos**, la respuesta es **Secrets Manager**. Si es solo almacenamiento de configuración, Parameter Store es más económico.

---

## AWS CloudHSM

CloudHSM proporciona módulos de seguridad de hardware (HSM) dedicados en la nube de AWS.

### CloudHSM vs KMS

| Característica | KMS | CloudHSM |
|---------------|-----|----------|
| **Tipo de HSM** | Multi-tenant (compartido) | Single-tenant (dedicado) |
| **Gestión de claves** | AWS gestiona el hardware y el software | Tú gestionas las claves; AWS gestiona el hardware |
| **Estándar criptográfico** | FIPS 140-2 Level 2 (algunos Level 3) | FIPS 140-2 Level 3 |
| **Disponibilidad** | Altamente disponible por defecto | Debes desplegar en múltiples AZs manualmente |
| **Integración AWS** | Integración nativa con casi todos los servicios | Integración limitada; funciona como custom key store para KMS |
| **Precio** | Pago por uso | ~$1.50/hora por HSM (mínimo 2 para HA) |
| **Acceso** | Via API de KMS | Tú controlas las claves; AWS no puede acceder |
| **Algoritmos** | Simétricos y asimétricos | Simétricos, asimétricos y hashing |
| **Casos de uso** | Cifrado general, integración servicios AWS | Compliance regulatorio estricto (FIPS 140-2 L3), SSL/TLS offloading, PKI |

### Custom Key Store (KMS + CloudHSM)

Un custom key store conecta KMS con tu CloudHSM cluster. Obtienes **lo mejor de ambos mundos**:

- **De KMS**: integración nativa con servicios AWS (S3, EBS, RDS, etc.).
- **De CloudHSM**: control total sobre el hardware donde vive el material de clave.

```
Sin custom key store:                    Con custom key store:
App → KMS → HSM compartido de AWS        App → KMS → Tu CloudHSM dedicado
(fácil pero sin control total)           (fácil + control total)
```

**Capacidades exclusivas del custom key store:**
- **Eliminar material de clave inmediatamente** de AWS (imposible con claves KMS normales, que tienen periodo de espera de 7-30 días).
- **Auditar uso de claves en los logs de CloudHSM**, independientemente de CloudTrail.
- El material de clave es **non-extractable**: nunca sale del HSM en texto plano.

### Tipos de KMS Keys (para el examen)

| Tipo | Quién la controla | Rotación | Puedes borrarla | Ejemplo |
|---|---|---|---|---|
| **AWS Owned Key** | AWS completamente | AWS decide | No | Cifrado por defecto de S3 (SSE-S3) |
| **AWS Managed Key** | AWS la gestiona, tú la usas | Automática (~1 año) | No | `aws/s3`, `aws/ebs`, `aws/rds` |
| **Customer Managed Key** | Tú la controlas | Opcional | Sí (7-30 días espera) | Claves que tú creas en KMS |
| **Customer Managed Key en Custom Key Store** | Tú la controlas + control del HSM | Opcional | Sí (inmediato, borrando del HSM) | Claves en KMS respaldadas por CloudHSM |

> **Tip para el examen:**
> - **FIPS 140-2 Level 3** o **single-tenant HSM** o **control total de las claves** → **CloudHSM**.
> - **Integración fácil con servicios AWS + control total + eliminar material inmediatamente** → **KMS con custom key store (CloudHSM)**.
> - **Auditar uso de claves independientemente de CloudTrail** → **Custom key store** (los logs de CloudHSM son independientes).

---

## AWS WAF, Shield y Shield Advanced

### AWS WAF (Web Application Firewall)

- Protege aplicaciones web contra exploits web comunes (capa 7).
- Se despliega en: **ALB, API Gateway, CloudFront, AppSync, Cognito User Pool**.
- Define **Web ACLs** con reglas que permiten, bloquean o cuentan solicitudes.
- Puede filtrar basado en:
  - **IP addresses** (IP sets).
  - **País de origen** (geo-match).
  - **Tamaño de la solicitud**.
  - **Strings/regex** en headers, body, URI.
  - **SQL injection** y **Cross-Site Scripting (XSS)** detection.
  - **Rate-based rules** para protección contra DDoS a nivel de aplicación.
- **AWS Managed Rules**: Conjuntos de reglas pre-configuradas mantenidas por AWS o marketplace.

### AWS Shield

| Característica | Shield Standard | Shield Advanced |
|---------------|----------------|-----------------|
| **Coste** | Gratis (incluido automáticamente) | $3,000/mes por organización + costes de uso |
| **Protección** | Ataques DDoS capa 3/4 comunes | Ataques DDoS sofisticados capa 3/4/7 |
| **Protege** | Todos los recursos AWS automáticamente | EC2, ELB, CloudFront, Global Accelerator, Route 53 |
| **Visibilidad** | Básica | Diagnósticos en tiempo real, métricas detalladas |
| **DDoS Response Team (DRT)** | No | Sí, 24/7 |
| **Protección de costes** | No | Sí (créditos por escalado DDoS involuntario) |
| **WAF incluido** | No | Sí (WAF sin coste adicional para recursos protegidos) |

### Arquitectura de protección típica

```
Internet -> CloudFront (Shield + WAF) -> ALB (Shield + WAF) -> EC2 (Security Groups)
```

---

## Amazon Cognito

Amazon Cognito proporciona autenticación, autorización y gestión de usuarios para aplicaciones web y móviles.

### User Pools vs Identity Pools

| Característica | Cognito User Pools | Cognito Identity Pools |
|---------------|-------------------|----------------------|
| **Propósito** | Autenticación (sign-up, sign-in) | Autorización (acceso a servicios AWS) |
| **Output** | JSON Web Tokens (JWT) | Credenciales temporales de AWS (STS) |
| **Funcionalidad** | Directorio de usuarios, login social, MFA, password recovery | Federar identidades y mapearlas a IAM roles |
| **Proveedores de identidad** | Local users, Google, Facebook, Apple, SAML, OIDC | Cognito User Pools, Google, Facebook, SAML, OIDC, custom |
| **Caso de uso** | Login para tu aplicación web/móvil | Dar acceso directo a servicios AWS (S3, DynamoDB) desde el cliente |
| **Integración con ALB** | Sí (autenticación en ALB) | No directamente |
| **Guest access** | No | Sí (usuarios no autenticados pueden tener un rol IAM limitado) |

### Flujo combinado típico

1. El usuario se autentica con **User Pool** y recibe un **JWT token**.
2. El JWT se intercambia con **Identity Pool** por **credenciales temporales de AWS**.
3. Con esas credenciales, el cliente accede directamente a servicios AWS (S3, API Gateway, etc.).

> **Tip para el examen:** User Pools = autenticación (quién eres). Identity Pools = autorización (qué puedes hacer en AWS). Muchas preguntas intentan confundirte entre ambos.

---

## AWS Directory Service (Active Directory)

### Qué es Active Directory

**Active Directory (AD)** es el sistema de Microsoft para gestionar identidades en una organización. Es la "base de datos de empleados" que controla autenticación (quién eres) y autorización (a qué tienes acceso) en entornos Windows.

```
Active Directory (on-premises típico)
├── Usuarios: juan@empresa.com, maria@empresa.com
├── Grupos: Ingeniería, RRHH, Finanzas
├── Permisos: Ingeniería → acceso a \\servidor\codigo
│             RRHH → acceso a \\servidor\nominas
└── Políticas: Contraseña mínimo 12 caracteres, bloqueo tras 3 intentos
```

Cuando un empleado hace login en su PC Windows, el PC consulta al AD: "¿existe este usuario y es correcta su contraseña?". Una vez autenticado, AD determina a qué carpetas compartidas, aplicaciones e impresoras tiene acceso.

### AWS Directory Service

Las empresas que migran a AWS no quieren recrear miles de usuarios en IAM. AWS Directory Service ofrece tres formas de usar Active Directory en la nube:

| Tipo | Qué es | AD on-premises? | Caso de uso |
|---|---|---|---|
| **AWS Managed Microsoft AD** | AD completo gestionado por AWS. Soporta trust bidireccional con AD on-premises | Opcional (funciona standalone o conectado) | FSx for Windows, RDS SQL Server, WorkSpaces, SSO, entornos híbridos |
| **AD Connector** | Proxy que redirige todas las peticiones al AD on-premises. No almacena datos en AWS | **Requerido** (sin AD on-premises no funciona) | Empresas que quieren usar su AD existente sin replicar datos en AWS |
| **Simple AD** | AD básico standalone basado en Samba. Sin conexión a AD on-premises | No soportado | Empresas pequeñas sin AD existente que necesitan funcionalidad AD básica |

```
AWS Managed Microsoft AD:
  Usuarios AWS  ──►  AWS Managed AD  ◄──  trust  ──►  AD on-premises
                     (AD completo)                     (usuarios corporativos)
                     Usuarios de ambos lados se ven mutuamente

AD Connector:
  Usuarios AWS  ──►  AD Connector  ──────────────────►  AD on-premises
                     (solo proxy)                        (todo vive aquí)

Simple AD:
  Usuarios AWS  ──►  Simple AD
                     (standalone, básico)
```

### Integración con servicios AWS

| Servicio | Cómo usa AD |
|---|---|
| **FSx for Windows File Server** | Se "une" (join) al dominio AD. Los usuarios acceden con sus credenciales de empresa |
| **RDS for SQL Server** | Autenticación Windows integrada via Managed AD |
| **Amazon WorkSpaces** | Escritorios virtuales con login de AD corporativo |
| **IAM Identity Center (SSO)** | Login único con credenciales de AD para la consola AWS y apps |
| **Amazon EC2 Windows** | Las instancias pueden unirse al dominio AD |

> **Tip para el examen:**
> - "SharePoint / Windows file share + Active Directory en AWS" → **FSx for Windows File Server + AWS Managed Microsoft AD** (no EFS, que es solo Linux).
> - "Usar AD on-premises existente sin almacenar datos de directorio en AWS" → **AD Connector**.
> - "AD gestionado en la nube con trust a on-premises" → **AWS Managed Microsoft AD**.
> - "AD básico sin conexión on-premises, presupuesto bajo" → **Simple AD**.

---

## Servicios de Detección y Seguridad

### Amazon GuardDuty

- **Detección inteligente de amenazas** usando ML, anomalías y threat intelligence.
- Analiza: **VPC Flow Logs, CloudTrail Logs, DNS Logs, EKS Audit Logs, S3 Data Events**.
- No necesitas habilitar Flow Logs o CloudTrail manualmente; GuardDuty los analiza independientemente.
- Genera **findings** clasificados por severidad.
- Puede activar notificaciones via **EventBridge** y remediar automáticamente con Lambda.
- **Delegated Administrator**: En Organizations, una cuenta miembro puede administrar GuardDuty para toda la organización.

### Amazon Inspector

- **Evaluación automática de vulnerabilidades** en:
  - **EC2 instances**: Vulnerabilidades de red y del SO (necesita SSM Agent).
  - **Container images en ECR**: Vulnerabilidades en imágenes Docker.
  - **Lambda functions**: Vulnerabilidades en código y dependencias.
- Genera un **risk score** para priorizar remediaciones.
- Se ejecuta automáticamente cuando se detectan cambios (nuevo deploy, nueva CVE publicada).

### Amazon Macie

- Usa ML y pattern matching para **descubrir y proteger datos sensibles en S3**.
- Detecta: PII (Personally Identifiable Information), datos financieros, credenciales, etc.
- Genera **findings** cuando se detecta información sensible.
- Se integra con EventBridge para automatizar remediaciones.

### Amazon Detective

- **Investiga y analiza** la causa raíz de hallazgos de seguridad.
- Ingiere datos de **GuardDuty, VPC Flow Logs, CloudTrail, EKS**.
- Crea **visualizaciones gráficas** para entender relaciones entre recursos y actividades.
- No detecta amenazas (eso lo hace GuardDuty); solo ayuda a **investigarlas**.

### Resumen de servicios de seguridad

| Servicio | Función principal |
|----------|------------------|
| **GuardDuty** | Detección de amenazas (ML + threat intelligence) |
| **Inspector** | Evaluación de vulnerabilidades (EC2, ECR, Lambda) |
| **Macie** | Descubrimiento de datos sensibles en S3 |
| **Detective** | Investigación de causa raíz de hallazgos de seguridad |
| **Security Hub** | Panel centralizado que agrega findings de todos los anteriores |

---

## AWS Certificate Manager (ACM)

- Servicio para **aprovisionar, gestionar y desplegar certificados SSL/TLS** públicos y privados.
- Los certificados públicos emitidos por ACM son **gratuitos**.
- **Renovación automática** de certificados emitidos por ACM.
- Se integra con: **ELB (ALB/NLB), CloudFront, API Gateway, Elastic Beanstalk**.
- **No se puede usar directamente con EC2** (debes configurar SSL/TLS manualmente en la instancia).
- Los certificados de ACM son **regionales**. Para usarlos con CloudFront, deben estar en **us-east-1**.
- Puedes importar certificados externos (pero pierdes la renovación automática).

> **Tip para el examen:** Si necesitas SSL/TLS para ALB o CloudFront, usa ACM (gratis y renovación automática). Si la pregunta dice "certificado en us-east-1 para CloudFront", es comportamiento normal de ACM.

---

## Security Exam Tips

### IAM

- Las **IAM policies** se evalúan como: Explicit Deny > Explicit Allow > Implicit Deny.
- La cuenta **root** no puede ser restringida por IAM policies, pero sí por **SCPs** de Organizations (excepto la Management Account).
- Las **access keys** son para acceso programático; usuario/contraseña para la consola.
- **Roles** son la forma recomendada de dar permisos a servicios AWS (no access keys).
- **Permission Boundaries** limitan el máximo de permisos, no otorgan permisos.
- **"Miles de usuarios corporativos + SSO + carpeta per-user en S3"** → Federation + STS + IAM Role con policy variables (`${aws:userid}`). Nunca crear un IAM user por empleado.

### Organizations y SCPs

- SCPs no aplican a la **Management Account**.
- SCPs no aplican a **service-linked roles**.
- SCPs afectan a **todos los usuarios y roles** de la cuenta, incluido el root de la cuenta member.

### Control Tower

- **"Configurar entorno multi-cuenta con best practices"** → Control Tower.
- **"Landing Zone"** → Control Tower.
- **"Account Factory"** → Control Tower (provisión automatizada de cuentas).
- **Guardrails preventivos** = SCPs. **Guardrails detectivos** = Config Rules.
- Control Tower usa Organizations bajo el capó, pero automatiza toda la configuración.

### RAM (Resource Access Manager)

- **"Compartir subnets entre cuentas"** → RAM.
- **"Compartir Transit Gateway entre cuentas"** → RAM.
- No confundir con cross-account roles (STS AssumeRole) que es para acceso a APIs.
- En Organizations, RAM comparte sin invitaciones. Fuera, requiere aceptar invitación.

### Cifrado

- **KMS** para la mayoría de escenarios de cifrado. Multi-tenant.
- **CloudHSM** cuando necesitas FIPS 140-2 Level 3 o control total de claves.
- **Envelope encryption** para datos mayores a 4 KB.
- **Multi-Region Keys** para descifrar datos replicados entre regiones.
- SSE-S3 usa **AWS Owned Keys**. SSE-KMS usa **AWS Managed** o **Customer Managed Keys**. SSE-C = el cliente proporciona la clave.

### Secrets y Configuración

- **Secrets Manager** = rotación automática de credenciales de BD. Más caro.
- **Parameter Store** = configuración general y secretos simples. Más barato. Jerarquía con paths.

### Protección Web

- **WAF** = capa 7 (HTTP/HTTPS). Reglas contra SQL injection, XSS, rate limiting.
- **Shield Standard** = gratis, DDoS capa 3/4 básico.
- **Shield Advanced** = DDoS avanzado + DRT + protección de costes.
- WAF se despliega en ALB, CloudFront, API Gateway (no en NLB ni EC2 directamente).

### Cognito

- **User Pools** = autenticación (JWT).
- **Identity Pools** = credenciales temporales de AWS.
- Para dar acceso directo a S3 desde una app móvil: User Pool + Identity Pool.
- ALB puede autenticar contra Cognito User Pools o proveedores OIDC.

### Active Directory

- **"Migrar Windows workloads con Active Directory"** → AWS Managed Microsoft AD (+ FSx for Windows para file shares).
- **"Usar AD on-premises sin replicar en AWS"** → AD Connector.
- **"Windows file share + AD"** → FSx for Windows (no EFS). EFS = solo Linux/NFS.
- **AWS Managed AD** soporta trust bidireccional con AD on-premises. AD Connector solo redirige.

### Detección

- **GuardDuty** detecta amenazas analizando logs.
- **Inspector** escanea vulnerabilidades en EC2, ECR y Lambda.
- **Macie** detecta datos sensibles (PII) en S3.
- **Detective** investiga hallazgos de seguridad (no detecta).
- Si preguntan "descubrir datos sensibles en S3" -> Macie.
- Si preguntan "detectar comportamiento sospechoso o amenazas" -> GuardDuty.
- Si preguntan "escanear vulnerabilidades de software" -> Inspector.
