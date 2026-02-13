# Dominio 1: Diseñar Arquitecturas Seguras

## Pregunta 1

Una empresa tiene una aplicación web desplegada en EC2 con un Application Load Balancer. El equipo de seguridad requiere que todo el tráfico HTTP sea redirigido automáticamente a HTTPS. ¿Cuál es la solución más sencilla?

A) Configurar una regla en el Security Group para bloquear el puerto 80
B) Configurar una listener rule en el ALB para redirigir HTTP (puerto 80) a HTTPS (puerto 443)
C) Usar AWS WAF para bloquear requests HTTP
D) Modificar el código de la aplicación para detectar HTTP y redirigir a HTTPS

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

El ALB soporta nativamente reglas de listener que pueden redirigir tráfico HTTP a HTTPS con un status code 301 o 302. Esta es la solución más simple y eficiente. La opción A bloquearía el tráfico en lugar de redirigirlo. La opción C es compleja e innecesaria para una simple redirección. La opción D requiere cambios en código y no es la "más sencilla".

**Servicio/concepto clave:** ALB Listener Rules, HTTPS redirect
</details>

---

## Pregunta 2

Una empresa necesita dar acceso a una aplicación Lambda en la Cuenta A para que escriba en una tabla DynamoDB en la Cuenta B. ¿Cuál es la forma más segura de implementar esto?

A) Crear un usuario IAM en la Cuenta B con credenciales de acceso y almacenarlas como variables de entorno en Lambda
B) Crear un IAM Role en la Cuenta B con permisos DynamoDB y configurar una trust policy que permita a la Cuenta A asumir el rol
C) Hacer la tabla DynamoDB pública con una resource policy permisiva
D) Usar VPC Peering entre ambas cuentas y acceder a DynamoDB a través de la red privada

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

El patrón cross-account en AWS se implementa con IAM Roles y STS AssumeRole. Se crea un rol en la Cuenta B con los permisos necesarios y una trust policy que permita a la Cuenta A (o a un rol específico) asumir ese rol. Lambda en la Cuenta A asume el rol y obtiene credenciales temporales. La opción A usa credenciales a largo plazo (mala práctica). La opción C expone datos. La opción D no resuelve el problema de permisos IAM.

**Servicio/concepto clave:** IAM Cross-Account Roles, STS AssumeRole
</details>

---

## Pregunta 3

Un equipo de desarrollo necesita almacenar las credenciales de conexión a una base de datos RDS. Las credenciales deben rotarse automáticamente cada 30 días sin causar downtime en la aplicación. ¿Cuál es la mejor solución?

A) Almacenar las credenciales en un archivo .env en el código de la aplicación y actualizarlas manualmente
B) Almacenar las credenciales en AWS Systems Manager Parameter Store con rotación manual mediante Lambda
C) Almacenar las credenciales en AWS Secrets Manager con rotación automática habilitada
D) Almacenar las credenciales cifradas en S3 y leerlas al iniciar la aplicación

<details>
<summary>Ver respuesta</summary>

**Respuesta: C**

AWS Secrets Manager ofrece rotación automática nativa para credenciales de bases de datos RDS, Aurora, Redshift y DocumentDB. Solo necesitas habilitar la rotación y configurar el periodo (30 días). Secrets Manager usa una Lambda gestionada por AWS para rotar las credenciales sin downtime. La opción B requiere implementar la rotación manualmente. La opción A es insegura. La opción D no soporta rotación automática.

**Servicio/concepto clave:** AWS Secrets Manager, rotación automática
</details>

---

## Pregunta 4

Una empresa tiene múltiples cuentas AWS bajo AWS Organizations. El equipo de seguridad quiere asegurar que ninguna cuenta pueda lanzar instancias EC2 fuera de las regiones eu-west-1 y eu-central-1. ¿Cuál es el enfoque correcto?

A) Crear una IAM Policy en cada cuenta que deniegue acciones EC2 fuera de esas regiones
B) Crear un Service Control Policy (SCP) en la OU que deniegue todas las acciones EC2 si aws:RequestedRegion no es eu-west-1 o eu-central-1
C) Configurar AWS Config rules en cada cuenta para detectar instancias en regiones no permitidas
D) Usar AWS Firewall Manager para bloquear tráfico desde regiones no aprobadas

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

Las SCPs (Service Control Policies) en AWS Organizations son el mecanismo correcto para limitar acciones a nivel de cuenta u OU. Una SCP con condición `aws:RequestedRegion` puede prevenir que cualquier usuario o rol (excepto el root de la organización) lance recursos fuera de las regiones especificadas. La opción A requiere gestionar políticas individualmente en cada cuenta. La opción C es detectiva, no preventiva. La opción D no aplica a restricciones regionales de servicios.

**Servicio/concepto clave:** AWS Organizations, Service Control Policies (SCP)
</details>

---

## Pregunta 5

Una aplicación en EC2 necesita acceder a objetos cifrados en S3 usando SSE-KMS. La aplicación utiliza un IAM Role. Los desarrolladores reportan errores de "Access Denied" al intentar descargar objetos. El rol tiene permisos s3:GetObject en el bucket. ¿Qué falta?

A) El Security Group de la instancia EC2 no permite tráfico saliente al puerto 443
B) El IAM Role necesita permisos kms:Decrypt sobre la clave KMS usada para cifrar los objetos
C) Se necesita un VPC Endpoint para S3
D) El bucket policy necesita permitir acceso desde la VPC

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

Cuando los objetos en S3 están cifrados con SSE-KMS, el proceso de descarga requiere que el llamante tenga permisos para descifrar con la clave KMS específica. El rol necesita tanto `s3:GetObject` en el bucket como `kms:Decrypt` en la clave KMS. Sin el permiso KMS, S3 no puede descifrar el objeto para entregarlo. Las opciones A, C y D podrían causar otros problemas, pero el escenario indica que el error es de permisos específicamente.

**Servicio/concepto clave:** SSE-KMS, permisos KMS, kms:Decrypt
</details>

---

## Pregunta 6

Una empresa necesita almacenar datos de tarjetas de crédito y cumplir con PCI-DSS. Requieren que las claves de cifrado sean gestionadas en hardware dedicado con certificación FIPS 140-2 Level 3. ¿Qué servicio deben usar?

A) AWS KMS con claves gestionadas por AWS
B) AWS KMS con Customer Managed Keys (CMK)
C) AWS CloudHSM
D) AWS Secrets Manager

<details>
<summary>Ver respuesta</summary>

**Respuesta: C**

AWS CloudHSM proporciona módulos de seguridad de hardware (HSM) dedicados con certificación FIPS 140-2 Level 3. KMS estándar tiene certificación Level 2. CloudHSM ofrece single-tenant HSMs donde el cliente tiene control exclusivo del hardware criptográfico. Es el servicio adecuado cuando compliance requiere FIPS 140-2 Level 3 explícitamente.

**Servicio/concepto clave:** AWS CloudHSM, FIPS 140-2 Level 3
</details>

---

## Pregunta 7

Un arquitecto necesita configurar una VPC para que las instancias en una subnet privada puedan descargar actualizaciones de internet, pero que NO sean accesibles desde internet. ¿Qué componentes son necesarios?

A) Internet Gateway + Public IP en las instancias de la subnet privada
B) NAT Gateway en una subnet pública + ruta en la route table de la subnet privada hacia el NAT Gateway
C) VPC Endpoint Gateway para internet
D) Elastic IP asignada directamente a cada instancia en la subnet privada

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

Un NAT Gateway permite que instancias en subnets privadas inicien conexiones salientes a internet (para actualizaciones, parches, etc.) sin ser accesibles desde internet. El NAT Gateway se coloca en una subnet pública (con ruta al IGW) y la route table de la subnet privada apunta 0.0.0.0/0 al NAT Gateway. Las opciones A y D harían las instancias accesibles desde internet. La opción C no existe para acceso general a internet.

**Servicio/concepto clave:** NAT Gateway, subnets privadas, acceso saliente a internet
</details>

---

## Pregunta 8

Una aplicación web maneja autenticación de usuarios con nombre de usuario y contraseña, y también permite login con Google y Facebook. Los usuarios autenticados necesitan acceder directamente a archivos en un bucket S3 privado. ¿Qué combinación de servicios de AWS es la más adecuada?

A) IAM Users para cada usuario de la aplicación con políticas S3 adjuntas
B) Cognito User Pool para autenticación + Cognito Identity Pool para credenciales AWS temporales de acceso a S3
C) ALB con autenticación OIDC + S3 presigned URLs
D) API Gateway con Lambda Authorizer + S3 presigned URLs

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

Cognito User Pool maneja la autenticación (username/password, Google, Facebook) y emite tokens JWT. Cognito Identity Pool intercambia esos tokens por credenciales AWS temporales (IAM Role) que permiten acceso directo a S3. Esta combinación es el patrón estándar de AWS para dar acceso a servicios AWS desde aplicaciones web/mobile con usuarios autenticados. La opción A no escala y es insegura. Las opciones C y D funcionarían parcialmente pero no dan acceso directo a S3 como pide el escenario.

**Servicio/concepto clave:** Cognito User Pools, Cognito Identity Pools, credenciales temporales
</details>

---

## Pregunta 9

Un equipo de seguridad necesita detectar automáticamente si algún bucket S3 contiene información de identificación personal (PII) como números de seguridad social, números de tarjetas de crédito o direcciones de email. ¿Qué servicio deben usar?

A) Amazon GuardDuty
B) Amazon Inspector
C) Amazon Macie
D) AWS Config

<details>
<summary>Ver respuesta</summary>

**Respuesta: C**

Amazon Macie usa machine learning y pattern matching para descubrir y proteger datos sensibles (PII) almacenados en S3. Puede identificar automáticamente datos como números de seguridad social, tarjetas de crédito, pasaportes, etc. GuardDuty detecta amenazas pero no analiza contenido de datos. Inspector evalúa vulnerabilidades en EC2/Lambda. Config evalúa configuración de recursos, no contenido de datos.

**Servicio/concepto clave:** Amazon Macie, detección de PII en S3
</details>

---

## Pregunta 10

Una empresa tiene una aplicación API Gateway + Lambda que es accesible públicamente. Han recibido ataques de SQL injection y cross-site scripting. ¿Cuál es la mejor solución para proteger la API?

A) Implementar validación de input en el código de Lambda
B) Configurar AWS Shield Advanced en la API
C) Desplegar AWS WAF con reglas managed contra SQL injection y XSS asociado al API Gateway
D) Configurar un Security Group en el API Gateway para filtrar tráfico malicioso

<details>
<summary>Ver respuesta</summary>

**Respuesta: C**

AWS WAF se puede asociar directamente a API Gateway y ofrece reglas managed (AWS Managed Rules) que detectan y bloquean SQL injection, XSS, y otros ataques comunes de la capa de aplicación. Es la solución más directa y completa. La opción A es buena práctica pero no es suficiente por sí sola. La opción B protege contra DDoS, no contra SQLi/XSS. La opción D es incorrecta ya que API Gateway no tiene Security Groups.

**Servicio/concepto clave:** AWS WAF, API Gateway, SQL injection, XSS protection
</details>

---

## Pregunta 11

Una empresa quiere asegurar que todas las instancias EC2 tengan cifrado de volúmenes EBS habilitado en toda la organización. Quieren una solución preventiva, no solo detectiva. ¿Cuál es el mejor enfoque?

A) Usar AWS Config rule para detectar volúmenes sin cifrar y enviar alertas por SNS
B) Habilitar la opción "EBS encryption by default" en cada cuenta y región, y usar SCP para prevenir la deshabilitación
C) Crear una Lambda que escanee volúmenes EBS cada hora y cifre los que no estén cifrados
D) Usar Amazon Inspector para identificar instancias con volúmenes sin cifrar

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

"EBS encryption by default" es una configuración a nivel de cuenta/región que hace que todos los nuevos volúmenes EBS se cifren automáticamente. Combinado con un SCP que prevenga que los administradores de las cuentas deshabiliten esta configuración, se obtiene un control preventivo a nivel organizacional. La opción A es detectiva, no preventiva. Las opciones C y D también son detectivas/reactivas.

**Servicio/concepto clave:** EBS encryption by default, SCP, controles preventivos
</details>

---

## Pregunta 12

Un arquitecto está diseñando una solución donde una aplicación en una VPC debe acceder a S3 sin que el tráfico pase por internet. La solución debe ser la más económica posible. ¿Qué debe implementar?

A) VPC Interface Endpoint para S3 (PrivateLink)
B) VPC Gateway Endpoint para S3
C) NAT Gateway + ruta a internet para acceder a S3
D) AWS Direct Connect dedicado para el tráfico a S3

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

Los VPC Gateway Endpoints para S3 (y DynamoDB) son **gratuitos**. Se configuran como una entrada en la route table de la subnet y el tráfico a S3 se enruta directamente dentro de la red de AWS sin pasar por internet. Los Interface Endpoints (opción A) tienen costo por hora y por GB. El NAT Gateway (opción C) tiene costo y el tráfico saldría a internet. Direct Connect (opción D) es la opción más cara.

**Servicio/concepto clave:** VPC Gateway Endpoint, S3, tráfico privado gratuito
</details>

---

## Pregunta 13

Una empresa necesita centralizar los logs de seguridad de todas sus cuentas AWS en una sola ubicación para auditoría. Necesitan registrar todas las llamadas API en todas las cuentas y regiones, y asegurar que los logs no puedan ser eliminados o modificados. ¿Cuál es la mejor solución?

A) Habilitar CloudTrail en cada cuenta individualmente y enviar logs a S3 buckets locales
B) Crear un Organization Trail en AWS CloudTrail que envíe logs a un bucket S3 centralizado con Object Lock (compliance mode) y una bucket policy que impida eliminación
C) Usar AWS Config en todas las cuentas para registrar cambios de configuración
D) Habilitar VPC Flow Logs en todas las VPCs y centralizarlos en CloudWatch Logs

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

Un Organization Trail en CloudTrail captura automáticamente todos los eventos API en todas las cuentas de la organización y todas las regiones. Enviando los logs a un bucket S3 centralizado en una cuenta de seguridad dedicada, con S3 Object Lock en modo compliance (WORM), los logs no pueden ser eliminados ni siquiera por el root user durante el periodo de retención. La opción A no es centralizada ni previene eliminación. Las opciones C y D capturan datos diferentes a llamadas API.

**Servicio/concepto clave:** CloudTrail Organization Trail, S3 Object Lock (compliance mode)
</details>

---

## Pregunta 14

Una aplicación utiliza un IAM Role con la siguiente policy adjunta. Un desarrollador reporta que no puede realizar la acción `s3:DeleteObject` a pesar de que el usuario tiene una policy separada que permite `s3:*`. ¿Por qué?

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": "s3:DeleteObject",
      "Resource": "arn:aws:s3:::production-bucket/*"
    }
  ]
}
```

A) La policy Allow necesita ser más específica que la policy Deny
B) Un Deny explícito siempre prevalece sobre cualquier Allow, sin importar dónde esté definido
C) Las policies del rol tienen prioridad sobre las policies del usuario
D) Se necesita un Allow explícito en la misma policy que contiene el Deny

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

En la evaluación de políticas IAM, un **Deny explícito siempre gana** sobre cualquier Allow explícito, sin importar cuántas policies de Allow existan o dónde estén definidas. Este es el principio fundamental de IAM: Explicit Deny > Explicit Allow > Implicit Deny. Aunque el desarrollador tenga `s3:*` en otra policy, el Deny explícito en `s3:DeleteObject` prevalece.

**Servicio/concepto clave:** IAM Policy Evaluation Logic, Explicit Deny
</details>

---

## Pregunta 15

Una empresa está migrando su aplicación a AWS y necesita implementar una solución de Web Application Firewall. Requieren protección contra los 10 principales riesgos OWASP, rate limiting para prevenir abusos, y geo-blocking para bloquear tráfico de ciertos países. La aplicación usa CloudFront como CDN. ¿Cuál es la solución más completa?

A) Configurar CloudFront geographic restrictions para el geo-blocking y Security Groups para el rate limiting
B) Desplegar AWS WAF asociado a CloudFront con: AWS Managed Rules para OWASP top 10, rate-based rules para rate limiting, y geo-match conditions para geo-blocking
C) Usar AWS Shield Advanced para toda la protección
D) Implementar un proxy Nginx en EC2 con ModSecurity y reglas custom

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

AWS WAF asociado a CloudFront cubre todos los requisitos: las AWS Managed Rules incluyen conjuntos de reglas contra OWASP top 10 (SQL injection, XSS, etc.), las rate-based rules limitan requests por IP, y las geo-match conditions permiten bloquear tráfico por país. Es la solución nativa de AWS más completa y gestionada. La opción A no protege contra OWASP. La opción C protege contra DDoS pero no ofrece reglas OWASP detalladas. La opción D requiere gestión manual y no es una solución gestionada.

**Servicio/concepto clave:** AWS WAF, CloudFront, Managed Rules, rate-based rules, geo-match
</details>
