# Dominio 2: Diseñar Arquitecturas Resilientes

## Pregunta 1

Una empresa tiene una aplicación web con un ALB, instancias EC2 en un Auto Scaling Group y una base de datos RDS MySQL. La aplicación experimenta caídas cuando la AZ eu-west-1a tiene problemas. ¿Cuál es la configuración correcta para alta disponibilidad?

A) Desplegar instancias EC2 en múltiples AZs con el ASG, y habilitar Multi-AZ en RDS
B) Desplegar instancias EC2 más grandes en una sola AZ y crear read replicas de RDS
C) Usar Route 53 failover routing a un sitio estático en S3
D) Desplegar la aplicación en una segunda región como standby

<details>
<summary>Ver respuesta</summary>

**Respuesta: A**

Para alta disponibilidad dentro de una región, el patrón estándar es distribuir instancias EC2 en múltiples AZs mediante el Auto Scaling Group (que el ALB ya balancea) y habilitar Multi-AZ en RDS para tener failover automático del database. Esto asegura que si una AZ falla, las instancias en otras AZs continúan sirviendo tráfico y RDS hace failover al standby en otra AZ. La opción B no resuelve el problema de AZ única. La opción C es para DR, no HA. La opción D es excesiva para un problema de una sola AZ.

**Servicio/concepto clave:** Multi-AZ deployment, Auto Scaling Group, RDS Multi-AZ
</details>

---

## Pregunta 2

Una aplicación de e-commerce procesa pedidos enviando mensajes a una cola SQS. Durante eventos de alto tráfico (Black Friday), algunos pedidos se procesan más de una vez, causando cobros duplicados. ¿Cuál es la mejor solución?

A) Aumentar el visibility timeout de la cola SQS Standard
B) Reemplazar la cola SQS Standard por una cola SQS FIFO con deduplicación habilitada
C) Añadir más instancias de procesamiento para reducir el tiempo en cola
D) Usar Amazon MQ en lugar de SQS para garantizar entrega exacta

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

SQS FIFO ofrece procesamiento **exactly-once** con deduplicación automática (basada en deduplication ID o content-based deduplication). Esto previene que el mismo mensaje sea procesado más de una vez. SQS Standard ofrece **at-least-once delivery**, lo que puede resultar en duplicados. La opción A reduce duplicados pero no los elimina. La opción C no resuelve la causa raíz. La opción D es para protocolos legacy, no para deduplicación.

**Servicio/concepto clave:** SQS FIFO, exactly-once processing, deduplicación
</details>

---

## Pregunta 3

Una empresa necesita una estrategia de disaster recovery con un RTO de 1 hora y RPO de 15 minutos para su aplicación crítica que usa Aurora MySQL. La solución debe ser la más económica posible dentro de estos requisitos. ¿Qué estrategia deben usar?

A) Backup and Restore — restaurar desde snapshots de Aurora
B) Pilot Light — Aurora Global Database con una instancia mínima en la región DR
C) Warm Standby — Aurora Global Database con Auto Scaling reducido en la región DR
D) Multi-Site Active/Active — Aurora Global Database con capacidad completa en ambas regiones

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

Con un RTO de 1 hora y RPO de 15 minutos, la estrategia **Pilot Light** es suficiente y la más económica que cumple los requisitos. Aurora Global Database replica datos a la región DR con un RPO típico de ~1 segundo. El Pilot Light mantiene una instancia mínima en DR que se puede escalar cuando se necesite (dentro del RTO de 1 hora). La opción A tiene RTO/RPO demasiado largos. La opción C cumple pero es más cara. La opción D es la más cara y excede los requisitos.

**Servicio/concepto clave:** DR strategies, Pilot Light, Aurora Global Database, RTO/RPO
</details>

---

## Pregunta 4

Un arquitecto debe diseñar un sistema de procesamiento de imágenes donde los usuarios suben fotos a S3 y se genera un thumbnail. El sistema debe tolerar fallos sin perder ninguna imagen y procesarlas eventualmente aunque haya picos de carga. ¿Cuál es la arquitectura más resiliente?

A) S3 Event Notification → Lambda directamente
B) S3 Event Notification → SQS Queue → Lambda (procesando desde SQS)
C) S3 Event Notification → SNS → Email al equipo para procesamiento manual
D) CloudWatch Events → EC2 que monitorea S3 periódicamente

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

La combinación S3 → SQS → Lambda proporciona la máxima resiliencia. SQS actúa como buffer: si Lambda falla o se alcanza el límite de concurrencia, los mensajes permanecen en la cola (hasta 14 días) y se reintentan automáticamente. Con Dead Letter Queue, los mensajes que fallen repetidamente se preservan para análisis. La opción A (Lambda directo) puede perder eventos si Lambda falla o alcanza throttling. La opción C es manual. La opción D tiene latencia alta y es frágil.

**Servicio/concepto clave:** SQS como buffer, desacoplamiento, Dead Letter Queue, resiliencia
</details>

---

## Pregunta 5

Una empresa tiene una aplicación con un Auto Scaling Group configurado con scaling policy de Target Tracking al 60% de CPU. El ASG tiene min=2, max=10, desired=4. Durante un despliegue, las nuevas instancias causan que CloudWatch detecte CPU alta brevemente, provocando que el ASG lance instancias innecesarias. ¿Cómo resolver esto?

A) Cambiar a Simple Scaling policy
B) Configurar un warmup period para las nuevas instancias en la scaling policy
C) Aumentar el target CPU al 90%
D) Deshabilitar el Auto Scaling durante los despliegues

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

El **warmup period** (instance warmup) le indica al Auto Scaling Group que no incluya las métricas de las instancias nuevas en los cálculos de scaling hasta que hayan terminado de inicializarse. Esto previene que los picos transitorios de CPU durante el arranque disparen escalado innecesario. La opción A empeoraría el problema. La opción C enmascararía problemas reales de capacidad. La opción D es operacionalmente riesgosa y no escalable.

**Servicio/concepto clave:** Auto Scaling warmup period, Target Tracking scaling
</details>

---

## Pregunta 6

Una aplicación utiliza Aurora PostgreSQL como base de datos principal. El equipo de analytics necesita ejecutar queries pesadas de reporting que no deben afectar el rendimiento de la aplicación de producción. ¿Cuál es la mejor solución?

A) Crear un snapshot de Aurora cada noche y restaurarlo como una instancia separada para analytics
B) Crear Aurora Read Replicas con un Custom Endpoint dedicado para las queries de analytics
C) Migrar los datos a Redshift cada noche para analytics
D) Escalar verticalmente la instancia Aurora principal

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

Aurora permite crear hasta 15 Read Replicas y configurar **Custom Endpoints** que dirijan tráfico a replicas específicas. Se pueden designar replicas con instancias más grandes para analytics y crear un custom endpoint que solo apunte a esas replicas. Así el tráfico de analytics no afecta al writer ni a las replicas usadas por producción. La opción A tiene datos obsoletos y es costosa. La opción C añade complejidad innecesaria si solo se necesitan queries SQL. La opción D no aísla la carga.

**Servicio/concepto clave:** Aurora Read Replicas, Custom Endpoints
</details>

---

## Pregunta 7

Una empresa tiene una arquitectura con un ALB frente a instancias EC2 que procesan requests y las almacenan en RDS. Después de una actualización de la aplicación, el 5% de los requests fallan. Necesitan la capacidad de volver a la versión anterior rápidamente con mínimo impacto. ¿Qué estrategia de despliegue deberían haber usado?

A) All at once deployment
B) Rolling deployment
C) Blue/Green deployment
D) In-place deployment con manual rollback

<details>
<summary>Ver respuesta</summary>

**Respuesta: C**

El despliegue **Blue/Green** mantiene el entorno anterior (Blue) completamente funcional mientras el nuevo entorno (Green) recibe tráfico. Si se detectan problemas, el rollback es instantáneo: simplemente se redirige el tráfico de vuelta al entorno Blue (swap del DNS o target group del ALB). No hay downtime y el rollback toma segundos. Las opciones A, B y D requieren re-desplegar la versión anterior, lo cual es más lento y arriesgado.

**Servicio/concepto clave:** Blue/Green deployment, rollback instantáneo, ALB target groups
</details>

---

## Pregunta 8

Una aplicación procesa transacciones financieras y utiliza una arquitectura de microservicios con múltiples Lambda functions. Si algún paso falla, todos los pasos anteriores deben revertirse (compensating transactions). El proceso total puede tomar hasta 30 minutos. ¿Cuál es el servicio más adecuado para orquestar este flujo?

A) SQS con Dead Letter Queue para reintentos
B) AWS Step Functions con manejo de errores y estados de compensación
C) SNS con múltiples suscriptores Lambda
D) EventBridge con reglas para cada paso

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

AWS Step Functions es el servicio diseñado específicamente para orquestar workflows con múltiples pasos, incluyendo manejo de errores, reintentos, y estados de compensación (saga pattern). Permite definir catch blocks que ejecuten pasos de reversión cuando algo falla. Standard Workflows soportan hasta 1 año de duración. La opción A desacopla pero no orquesta compensaciones. Las opciones C y D son para event routing, no para workflows transaccionales complejos.

**Servicio/concepto clave:** AWS Step Functions, saga pattern, compensating transactions
</details>

---

## Pregunta 9

Una empresa tiene un sitio web estático alojado en S3 con CloudFront. Necesitan configurar una página de error personalizada que se muestre cuando el sitio principal no esté disponible, y que el failover sea automático. ¿Cuál es la mejor solución?

A) Configurar S3 website hosting error document
B) Configurar CloudFront con un Origin Group que tenga un origin primario y uno de failover (otro bucket S3 en otra región)
C) Configurar Route 53 failover routing a dos distribuciones CloudFront
D) Usar Lambda@Edge para detectar errores y servir contenido alternativo

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

CloudFront Origin Groups permiten configurar failover automático a nivel de CDN. Si el origin primario devuelve errores (4xx, 5xx), CloudFront automáticamente redirige la request al origin secundario. Configurando un segundo bucket S3 en otra región como origin de failover, se obtiene resiliencia automática. La opción A solo muestra una página estática de error, no un sitio alternativo. La opción C requiere health checks adicionales y es más compleja. La opción D añade complejidad innecesaria.

**Servicio/concepto clave:** CloudFront Origin Groups, origin failover
</details>

---

## Pregunta 10

Una aplicación móvil usa API Gateway + Lambda + DynamoDB. Durante picos de uso, la aplicación experimenta throttling en DynamoDB. La mayoría de las operaciones son lecturas de los mismos datos populares. ¿Cuál es la forma más eficaz de reducir la carga en DynamoDB y mejorar la resiliencia?

A) Cambiar DynamoDB a modo On-Demand
B) Añadir DynamoDB Accelerator (DAX) como capa de cache
C) Crear una read replica de DynamoDB
D) Aumentar las RCU provisioned significativamente

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

DynamoDB Accelerator (DAX) es un cache in-memory totalmente gestionado para DynamoDB que reduce la latencia de milisegundos a microsegundos. Para patrones de lectura intensiva con datos repetidos (hot keys), DAX absorbe la carga de lectura y reduce dramáticamente las requests a DynamoDB. La opción A ayuda con el escalado pero es más cara para lecturas repetitivas. La opción C no existe en DynamoDB (no tiene read replicas como RDS). La opción D solo añade capacidad bruta sin resolver el problema de hot keys.

**Servicio/concepto clave:** DynamoDB Accelerator (DAX), caching, hot partition mitigation
</details>

---

## Pregunta 11

Un arquitecto necesita diseñar una arquitectura para una aplicación que debe estar disponible incluso si una región AWS completa falla. La aplicación usa Aurora MySQL. ¿Cuál es la arquitectura correcta?

A) Aurora Multi-AZ dentro de una región con backups automáticos
B) Aurora Global Database con una región primaria y una región secundaria, más Route 53 failover routing
C) RDS MySQL con read replica cross-region
D) DynamoDB Global Tables como reemplazo de Aurora

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

Aurora Global Database replica datos a regiones secundarias con un RPO típico de ~1 segundo. Combinado con Route 53 failover routing (con health checks), si la región primaria falla, Route 53 redirige el tráfico a la región secundaria donde se puede promover el cluster de Aurora secundario a primario. La opción A solo protege contra fallos de AZ, no de región. La opción C funciona pero con RPO peor y failover manual. La opción D cambia completamente el tipo de base de datos.

**Servicio/concepto clave:** Aurora Global Database, Route 53 failover, multi-region DR
</details>

---

## Pregunta 12

Una empresa tiene una aplicación que procesa mensajes de una cola SQS. Ocasionalmente, un mensaje malformado causa que el consumer falle repetidamente, bloqueando el procesamiento de otros mensajes. ¿Cómo solucionar este problema?

A) Aumentar el visibility timeout a 24 horas
B) Configurar una Dead Letter Queue (DLQ) con un maxReceiveCount bajo (ej: 3) para mover mensajes problemáticos fuera de la cola principal
C) Configurar la cola para eliminar mensajes después del primer intento fallido
D) Usar múltiples consumers para procesar más rápido

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

Una **Dead Letter Queue (DLQ)** captura mensajes que no se pueden procesar después de un número máximo de intentos (maxReceiveCount). Configurando maxReceiveCount en 3, después de 3 intentos fallidos el mensaje se mueve a la DLQ, permitiendo que los demás mensajes se procesen normalmente. La DLQ permite analizar los mensajes problemáticos por separado. La opción A solo retrasa el problema. La opción C pierde datos. La opción D no resuelve el mensaje bloqueante.

**Servicio/concepto clave:** SQS Dead Letter Queue (DLQ), maxReceiveCount, poison messages
</details>

---

## Pregunta 13

Una aplicación necesita almacenar sesiones de usuario que deben estar disponibles para todas las instancias EC2 detrás de un ALB. Las sesiones deben sobrevivir al reciclaje de instancias y ser accesibles con latencia sub-milisegundo. ¿Cuál es la mejor solución?

A) Usar ALB sticky sessions (session affinity)
B) Almacenar sesiones en Amazon ElastiCache for Redis
C) Almacenar sesiones en EBS volumes compartidos
D) Almacenar sesiones en el sistema de archivos local de cada instancia

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

ElastiCache for Redis es la solución estándar para almacenamiento de sesiones distribuido. Es accesible desde todas las instancias, tiene latencia sub-milisegundo, soporta replicación Multi-AZ para alta disponibilidad, y las sesiones sobreviven al reciclaje de instancias individuales. La opción A vincula usuarios a instancias específicas (si la instancia falla, se pierde la sesión). La opción C no es posible (EBS no se comparte así). La opción D pierde sesiones al reciclar.

**Servicio/concepto clave:** ElastiCache Redis, session store, stateless architecture
</details>

---

## Pregunta 14

Una empresa necesita un plan de backups centralizado para sus recursos en múltiples cuentas AWS (EC2, EBS, RDS, DynamoDB, EFS). Los backups deben seguir políticas consistentes y retenerse por 90 días. ¿Cuál es el servicio más adecuado?

A) Crear scripts de Lambda en cada cuenta para snapshots programados
B) Usar AWS Backup con Backup Plans y Backup Policies de AWS Organizations
C) Configurar cada servicio individualmente con sus backups nativos
D) Usar S3 Cross-Region Replication para todos los datos

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

**AWS Backup** proporciona una solución centralizada para gestionar backups de múltiples servicios AWS. Con **Backup Plans** se definen políticas (frecuencia, retención, región de destino) y con **Backup Policies de AWS Organizations** se aplican consistentemente a todas las cuentas. Soporta EC2, EBS, RDS, Aurora, DynamoDB, EFS, FSx, y más. La opción A requiere desarrollo y mantenimiento custom. La opción C no es centralizada. La opción D no es una solución de backup general.

**Servicio/concepto clave:** AWS Backup, Backup Plans, Organizations Backup Policies
</details>

---

## Pregunta 15

Una aplicación usa un Network Load Balancer con instancias EC2 en un Auto Scaling Group. El equipo detecta que las instancias nuevas reciben tráfico antes de que la aplicación esté completamente lista, causando errores 503 temporales. ¿Cuál es la mejor solución?

A) Aumentar el cooldown period del Auto Scaling Group
B) Configurar health checks en el target group del NLB con un path que verifique que la aplicación está lista, y habilitar el slow start en el target group
C) Usar instancias más grandes para que arranquen más rápido
D) Reducir el número mínimo de instancias para que haya menos rotación

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

Configurar **health checks** adecuados en el target group asegura que el NLB solo envíe tráfico a instancias que pasen el health check (aplicación lista). Además, aunque NLB no soporta slow start directamente como ALB, configurar health checks con intervalos y thresholds apropiados asegura que las instancias nuevas no reciban tráfico hasta estar listas. También se puede usar lifecycle hooks en el ASG para mantener instancias en "Pending:Wait" hasta que la aplicación esté lista. La opción A no previene el envío de tráfico a instancias no preparadas. Las opciones C y D no resuelven el problema.

**Servicio/concepto clave:** Target Group health checks, ASG lifecycle hooks, instance readiness
</details>
