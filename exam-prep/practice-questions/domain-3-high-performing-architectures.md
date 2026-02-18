# Dominio 3: Diseñar Arquitecturas de Alto Rendimiento

## Pregunta 1

Una empresa tiene un sitio web global con contenido estático (imágenes, CSS, JS) almacenado en S3 y contenido dinámico servido por instancias EC2 en eu-west-1. Los usuarios en Asia y América experimentan latencias de 2-3 segundos. ¿Cuál es la mejor solución para mejorar el rendimiento globalmente?

A) Desplegar la aplicación en todas las regiones con Route 53 Latency-based routing
B) Configurar CloudFront con un origin S3 para contenido estático y un origin ALB para contenido dinámico
C) Usar S3 Transfer Acceleration para todas las requests
D) Aumentar el tamaño de las instancias EC2

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

CloudFront con múltiples origins es la solución estándar. El contenido estático se cachea en las 400+ edge locations globales, eliminando la latencia a S3. El contenido dinámico se beneficia de la red optimizada de AWS entre edge locations y el origin (ALB). CloudFront soporta múltiples origins con behaviors basados en path patterns (ej: /static/* → S3, /* → ALB). La opción A es excesiva y costosa. La opción C es para uploads, no para delivery. La opción D no resuelve la latencia geográfica.

**Servicio/concepto clave:** CloudFront, múltiples origins, edge caching, path-based routing
</details>

---

## Pregunta 2

Una aplicación de e-commerce tiene una base de datos RDS MySQL con alta carga de lecturas. Las páginas de productos tardan más de 5 segundos en cargar porque cada vista ejecuta queries complejas a la base de datos. Los mismos productos son consultados miles de veces por hora. ¿Cuál es la mejor solución para reducir la latencia?

A) Escalar verticalmente la instancia RDS a una clase más grande
B) Implementar ElastiCache Redis como capa de cache entre la aplicación y RDS, con cache-aside pattern
C) Crear 5 Read Replicas de RDS
D) Migrar a DynamoDB

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

ElastiCache Redis con el patrón **cache-aside** (lazy loading) reduce drásticamente la latencia: la primera consulta lee de RDS y almacena el resultado en cache; las siguientes consultas del mismo producto se sirven desde Redis con latencia sub-milisegundo. Para datos consultados repetidamente (productos populares), el hit rate será muy alto. La opción A mejora marginalmente. La opción C distribuye lecturas pero cada query sigue tocando el disco. La opción D requiere rediseñar la aplicación y no es compatible con queries complejas SQL.

**Servicio/concepto clave:** ElastiCache Redis, cache-aside pattern, read performance
</details>

---

## Pregunta 3

Una aplicación IoT ingesta 100,000 eventos por segundo de sensores distribuidos globalmente. Cada evento es de ~1 KB. Los datos deben estar disponibles en tiempo real para dashboards y también almacenarse en S3 para analytics posterior. ¿Cuál es la arquitectura más eficiente?

A) Los sensores envían a SQS → Lambda procesa y almacena en S3
B) Los sensores envían a API Gateway → Lambda almacena en DynamoDB y S3
C) Los sensores envían a Kinesis Data Streams → Lambda para dashboards real-time + Kinesis Firehose para delivery a S3
D) Los sensores envían directamente a S3 y un proceso batch analiza cada hora

<details>
<summary>Ver respuesta</summary>

**Respuesta: C**

Kinesis Data Streams maneja 100K+ eventos/segundo con múltiples consumidores simultáneos. Lambda (o Kinesis Data Analytics) consume el stream para dashboards en tiempo real, mientras Kinesis Firehose consume el mismo stream para entregar datos a S3 automáticamente (near real-time, con buffering y compresión). La opción A: SQS no soporta múltiples consumidores del mismo mensaje. La opción B: API Gateway + Lambda tiene límites de concurrencia y es más cara para este volumen. La opción D no es real-time.

**Servicio/concepto clave:** Kinesis Data Streams, Kinesis Firehose, real-time streaming, múltiples consumidores
</details>

---

## Pregunta 4

Una aplicación de gaming global necesita una base de datos NoSQL con latencia de un solo dígito de milisegundos para lecturas, que soporte ráfagas de millones de requests. La tabla tiene un hot partition en el item "leaderboard-global" que se lee constantemente. ¿Cómo optimizar el rendimiento?

A) Usar DynamoDB con provisioned capacity y aumentar las RCU
B) Usar DynamoDB con DAX para cache de lecturas frecuentes, resolviendo el hot partition
C) Migrar a RDS Aurora con read replicas
D) Usar ElastiCache Redis directamente como base de datos principal

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

**DAX** (DynamoDB Accelerator) es un cache in-memory específico para DynamoDB que reduce la latencia de milisegundos a microsegundos. Para hot partitions (items leídos constantemente como un leaderboard global), DAX absorbe las lecturas repetitivas sin consumir RCU en la tabla subyacente. La opción A solo aumenta capacidad bruta pero el hot partition sigue siendo un cuello de botella. La opción C cambia a un modelo relacional inapropiado. La opción D pierde las funcionalidades de DynamoDB.

**Servicio/concepto clave:** DynamoDB Accelerator (DAX), hot partition, microsecond latency
</details>

---

## Pregunta 5

Una empresa necesita servir archivos de video de 2-10 GB almacenados en S3 a usuarios globales. Los usuarios experimentan velocidades de descarga lentas, especialmente desde Asia y Sudamérica. ¿Cuál es la mejor solución para acelerar las descargas?

A) Habilitar S3 Transfer Acceleration
B) Usar CloudFront con S3 como origin, habilitando byte-range fetches
C) Copiar los videos a buckets S3 en todas las regiones
D) Usar un NLB delante de S3 para mejorar el throughput

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

CloudFront cachea contenido en edge locations globales. Para archivos grandes de video, CloudFront soporta **byte-range fetches** (Range requests) que permiten descargas parciales y paralelas. Una vez un video se solicita, se cachea en el edge location más cercano al usuario, mejorando drásticamente las descargas posteriores. La opción A es para **uploads** a S3 (no descargas). La opción C es costosa y difícil de gestionar. La opción D: NLB no puede estar delante de S3 directamente.

**Servicio/concepto clave:** CloudFront, edge caching, byte-range fetches, large file delivery
</details>

---

## Pregunta 6

Una base de datos DynamoDB tiene una tabla con modo provisioned (5,000 RCU, 1,000 WCU). La aplicación necesita leer items de 8 KB de tamaño con consistencia eventual. ¿Cuántas lecturas por segundo puede realizar la tabla?

A) 5,000 lecturas/s
B) 2,500 lecturas/s
C) 10,000 lecturas/s
D) 1,250 lecturas/s

<details>
<summary>Ver respuesta</summary>

**Respuesta: C**

Cálculo: 1 RCU = 1 lectura strongly consistent de 4 KB/s = 2 lecturas eventually consistent de 4 KB/s. Para items de 8 KB: cada lectura consume 8/4 = 2 RCUs (strongly consistent) o 1 RCU (eventually consistent). Con 5,000 RCU y lecturas **eventually consistent** de 8 KB: 5,000 RCU / 1 RCU por lectura = 5,000... pero cada RCU permite 2 eventually consistent reads de 4KB. Para 8KB eventually consistent: 5,000 * 2 / 2 = 5,000. Revisando: 8KB item = 2 read capacity units (strongly consistent), pero eventually = 1 RCU. Así que 5,000 / 1 = 5,000. Corrección: 1 RCU = 2 eventually consistent reads de 4KB. Item de 8KB requiere 2 bloques de 4KB, así que 2 RCU strongly = 1 RCU eventually. 5,000 RCU / 1 RCU = 5,000... El cálculo correcto: item de 8KB = ceil(8/4) = 2 unidades. Strongly = 2 RCU. Eventually = 2/2 = 1 RCU. 5,000/1 = **5,000 lecturas/s**. Nota: la respuesta correcta sería A con 5,000, pero revisando nuevamente: 1 RCU = 4KB strongly OR 8KB eventually. 8KB item eventually = 1 RCU. Respuesta = 5,000. Sin embargo, la pregunta tiene opciones y 10,000 representaría items de 4KB con eventually consistent. Con 8KB items = 5,000. La respuesta más cercana es **C) 10,000** si interpretamos que eventually consistent reads obtienen el doble de throughput: 5,000 RCU x 2 (eventually) = 10,000 reads de 4KB, pero como cada item es 8KB (2 unidades), necesita 2 unidades / 2 (eventually) = 1 RCU. Entonces 5,000 items/s. La respuesta correcta es **A) 5,000**.

Corrección de respuesta: **A) 5,000 lecturas/s**. Cada item de 8KB requiere ceil(8/4) = 2 unidades de lectura. Con eventually consistent, se divide entre 2: 2/2 = 1 RCU por lectura. Con 5,000 RCU: 5,000/1 = 5,000 lecturas/s.

**Servicio/concepto clave:** DynamoDB RCU calculation, eventually consistent reads
</details>

---

## Pregunta 7

Una aplicación necesita una API REST que pueda manejar ráfagas de hasta 10,000 requests por segundo. La respuesta para el 80% de las requests es idéntica durante periodos de 5 minutos. ¿Cuál es la forma más eficiente de manejar esta carga?

A) API Gateway con Lambda backend y Auto Scaling de Lambda concurrency
B) API Gateway con caching habilitado (5 minutos TTL) y Lambda backend
C) ALB con EC2 Auto Scaling Group
D) API Gateway con integración directa a DynamoDB

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

API Gateway ofrece **caching integrado** que almacena respuestas y las sirve directamente sin invocar el backend. Con un TTL de 5 minutos y el 80% de requests idénticas, el cache absorbe la gran mayoría del tráfico, reduciendo drásticamente las invocaciones a Lambda y la latencia para el usuario. Esto reduce costos y mejora rendimiento simultáneamente. La opción A maneja la carga pero sin optimizar las requests repetitivas. La opción C requiere más gestión. La opción D solo funciona para operaciones CRUD simples.

**Servicio/concepto clave:** API Gateway caching, TTL, request deduplication
</details>

---

## Pregunta 8

Una empresa necesita que sus instancias EC2 en eu-west-1 accedan a datos en un bucket S3 en us-east-1 con el máximo rendimiento posible. Los archivos son de 5-50 GB cada uno. ¿Cuál es la mejor estrategia?

A) Usar S3 Transfer Acceleration para las transferencias cross-region
B) Usar multipart upload con transfers paralelos y S3 Transfer Acceleration
C) Replicar el bucket a eu-west-1 con S3 Cross-Region Replication y acceder localmente
D) Usar Direct Connect entre las dos regiones

<details>
<summary>Ver respuesta</summary>

**Respuesta: C**

Si las instancias EC2 en eu-west-1 necesitan acceso frecuente y de máximo rendimiento a los datos, la mejor solución es **replicar los datos a un bucket local** usando S3 Cross-Region Replication (CRR). Así, las instancias acceden a datos en la misma región con latencia mínima. La opción A y B mejoran la transferencia pero siguen siendo cross-region. La opción D es para on-prem, no entre regiones AWS. El costo adicional de almacenamiento duplicado se compensa con el rendimiento.

**Servicio/concepto clave:** S3 Cross-Region Replication, data locality, rendimiento cross-region
</details>

---

## Pregunta 9

Un equipo de desarrollo tiene una Lambda function que se invoca por API Gateway. Los usuarios experimentan latencia elevada (3-5 segundos) en la primera request después de un periodo de inactividad, pero las requests posteriores son rápidas (~200ms). ¿Cuál es la mejor solución?

A) Aumentar la memoria asignada a la Lambda
B) Configurar Provisioned Concurrency para la Lambda function
C) Usar Lambda@Edge en lugar de Lambda estándar
D) Reducir el tamaño del deployment package

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

El problema descrito es el **cold start** de Lambda. La primera invocación después de inactividad requiere que AWS provisione un entorno de ejecución, lo cual toma tiempo adicional. **Provisioned Concurrency** mantiene un número configurable de entornos de ejecución "calientes" permanentemente, eliminando los cold starts. La opción A puede ayudar marginalmente pero no elimina el cold start. La opción C cambia la ubicación de ejecución, no el problema del cold start. La opción D ayuda minimamente.

**Servicio/concepto clave:** Lambda cold start, Provisioned Concurrency
</details>

---

## Pregunta 10

Una aplicación usa RDS PostgreSQL con una instancia db.r5.xlarge. El equipo de monitoreo detecta que el ReadIOPS está constantemente al 90% del máximo, pero el CPU está al 30%. Las queries más frecuentes son JOINs complejos que acceden a tablas grandes. ¿Cuál es la mejor optimización?

A) Escalar verticalmente a db.r5.2xlarge
B) Migrar de gp2 a io2 storage para obtener más IOPS provisioned
C) Crear Read Replicas para distribuir las lecturas
D) Crear Read Replicas para queries de lectura y añadir ElastiCache para resultados de queries frecuentes

<details>
<summary>Ver respuesta</summary>

**Respuesta: D**

El cuello de botella es I/O, no CPU. La combinación de **Read Replicas** para distribuir queries de lectura entre múltiples instancias y **ElastiCache** para cachear resultados de queries frecuentes aborda el problema desde dos ángulos. Las queries repetitivas se sirven desde cache (eliminando I/O), y las queries no cacheadas se distribuyen entre replicas. La opción A da más CPU pero no resuelve I/O. La opción B ayuda con IOPS pero es más cara y limitada. La opción C sola ayuda pero no optimiza queries repetitivas.

**Servicio/concepto clave:** Read Replicas, ElastiCache, I/O optimization, query caching
</details>

---

## Pregunta 11

Una empresa necesita procesar uploads de archivos de video de 10-50 GB subidos por usuarios desde todo el mundo. Los uploads son lentos y frecuentemente fallan, especialmente desde Asia. ¿Cuál es la mejor solución para mejorar la velocidad y confiabilidad de los uploads?

A) Aumentar el timeout del servidor web que recibe los uploads
B) Usar S3 Multipart Upload con S3 Transfer Acceleration habilitado
C) Desplegar servidores de upload en múltiples regiones
D) Usar CloudFront para cachear los uploads

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

**S3 Multipart Upload** divide archivos grandes en partes que se suben en paralelo. Si una parte falla, solo esa parte se reintenta (no el archivo completo). **S3 Transfer Acceleration** usa las edge locations de CloudFront para acelerar la transferencia de datos al bucket S3 de destino usando la red optimizada de AWS. Combinados, proporcionan uploads rápidos y confiables desde cualquier ubicación global. La opción A no mejora velocidad. La opción C es compleja. La opción D: CloudFront no cachea uploads.

**Servicio/concepto clave:** S3 Multipart Upload, S3 Transfer Acceleration, upload optimization
</details>

---

## Pregunta 12

Una aplicación necesita una base de datos con rendimiento consistente de lectura de microsegundos y la capacidad de escalar horizontalmente las lecturas. Los datos son pares key-value simples de menos de 1 KB con un volumen de 500,000 lecturas por segundo. ¿Cuál es la solución más adecuada?

A) DynamoDB con Provisioned Capacity alta
B) DynamoDB con DAX
C) Aurora MySQL con read replicas
D) ElastiCache Redis cluster mode

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

DynamoDB con DAX proporciona latencia de **microsegundos** para lecturas. DynamoDB solo tiene latencia de milisegundos de un solo dígito. DAX funciona como cache transparente: la aplicación usa el mismo API de DynamoDB pero apuntando al cluster DAX. Para 500K lecturas/s de datos key-value simples y pequeños, DAX es óptimo ya que los items caben fácilmente en memoria. La opción A da milisegundos, no microsegundos. La opción C tiene mayor latencia para key-value simple. La opción D funciona pero pierde las ventajas de DynamoDB como backend persistente.

**Servicio/concepto clave:** DynamoDB + DAX, microsecond reads, key-value at scale
</details>

---

## Pregunta 13

Una empresa tiene un API Gateway REST API que invoca Lambda functions. La API sirve datos de múltiples microservicios. El rendimiento necesita mejorar para responses que cambian raramente (catálogo de productos). Además, algunos endpoints tienen lógica pesada que beneficiaría de más recursos. ¿Cuáles son dos mejoras que pueden implementar? (Selecciona DOS)

A) Habilitar API Gateway stage caching con TTL para los endpoints del catálogo
B) Aumentar la memoria asignada a las Lambda functions (que también aumenta CPU proporcionalmente)
C) Migrar de REST API a HTTP API en API Gateway
D) Usar VPC endpoints para API Gateway
E) Convertir las Lambda en instancias EC2 para más control

<details>
<summary>Ver respuesta</summary>

**Respuesta: A y B**

**A)** API Gateway caching almacena responses y las sirve sin invocar Lambda, ideal para datos que cambian raramente como catálogos de productos. **B)** En Lambda, la CPU se asigna proporcionalmente a la memoria. Aumentar la memoria también aumenta la potencia de CPU, mejorando el rendimiento de lógica computacionalmente intensiva. La opción C puede reducir latencia marginalmente pero no cachea. La opción D es para acceso privado, no rendimiento. La opción E añade complejidad operacional.

**Servicio/concepto clave:** API Gateway caching, Lambda memory/CPU scaling
</details>

---

## Pregunta 14

Un equipo necesita ejecutar queries analíticas SQL sobre datos almacenados en S3 en formato Parquet. Los queries se ejecutan ad-hoc unas pocas veces al día. No quieren mantener infraestructura ni cargar datos en otra base de datos. ¿Cuál es la solución más eficiente?

A) Cargar los datos en Redshift y ejecutar queries
B) Usar Amazon Athena para queries directos sobre S3
C) Usar EMR con Apache Hive
D) Copiar datos a Aurora y hacer queries SQL

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

**Amazon Athena** es un servicio serverless de queries interactivas que permite ejecutar SQL directamente sobre datos en S3. No requiere infraestructura, no necesitas cargar datos en otra base de datos, y solo pagas por la cantidad de datos escaneados por query. Parquet es un formato columnar que Athena optimiza automáticamente (escanea solo las columnas necesarias). La opción A requiere mantener un cluster. La opción C es compleja para queries ad-hoc. La opción D requiere ETL y una base de datos.

**Servicio/concepto clave:** Amazon Athena, serverless SQL on S3, Parquet optimization
</details>

---

## Pregunta 15

There is a new compliance rule in your company that audits every Windows and Linux EC2 instances each month to view any performance issues. They have more than a hundred EC2 instances running in production, and each must have a logging function that collects various system details regarding that instance. The SysOps team will periodically review these logs and analyze their contents using AWS Analytics tools, and the result will need to be retained in an S3 bucket.

In this scenario, what is the most efficient way to collect and analyze logs from the instances with minimal effort?

A) Install the unified CloudWatch Logs agent in each instance which will automatically collect and push data to CloudWatch Logs. Analyze the log data with CloudWatch Logs Insights.
B) Install AWS Inspector Agent in each instance which will collect and push data to CloudWatch Logs periodically. Set up a CloudWatch dashboard to properly analyze the log data of all instances.
C) Install AWS SDK in each instance and create a custom daemon script that would collect and push data to CloudWatch Logs periodically. Enable CloudWatch detailed monitoring and use CloudWatch Logs Insights to analyze the log data of all instances.
D) Install the AWS Systems Manager Agent (SSM Agent) in each instance which will automatically collect and push data to CloudWatch Logs. Analyze the log data with CloudWatch Logs Insights.

<details>
<summary>Ver respuesta</summary>

**Respuesta: A**

El **CloudWatch Unified Agent** es la herramienta diseñada específicamente para recopilar logs y métricas del sistema (RAM, disco, procesos, etc.) de instancias EC2 (Windows y Linux) y enviarlas a CloudWatch Logs automáticamente. **CloudWatch Logs Insights** permite analizar esos logs con un lenguaje de queries. Los logs se pueden exportar a S3 para retención.

Por qué las demás son incorrectas:
- **B) Inspector Agent**: AWS Inspector es para **evaluación de vulnerabilidades de seguridad** (CVEs, exposición de red), no para recopilar logs de rendimiento del sistema. Herramienta equivocada para el caso de uso.
- **C) AWS SDK + daemon custom**: Funcionaría técnicamente, pero crear un daemon custom NO es "minimal effort". El CloudWatch Agent ya hace esto out-of-the-box sin escribir código.
- **D) SSM Agent**: El SSM Agent es para **gestión remota** de instancias (ejecutar comandos, parchear, inventario). No recopila ni envía logs del sistema a CloudWatch Logs. SSM podría usarse para *instalar* el CloudWatch Agent, pero no hace la recopilación en sí.

**Patrón del examen**: Cuando la pregunta dice "minimal effort" o "most efficient", descarta opciones que impliquen código custom si existe un servicio gestionado que lo hace. El CloudWatch Unified Agent es la respuesta estándar para "recopilar logs y métricas del sistema de EC2".

**Servicios/conceptos clave:** CloudWatch Unified Agent, CloudWatch Logs, CloudWatch Logs Insights, diferencia entre Inspector/SSM/CloudWatch Agent
</details>

---

## Pregunta 16

Una empresa global necesita que sus APIs estén disponibles con latencia ultra-baja y IPs estáticas para que sus clientes empresariales las incluyan en sus allowlists de firewall. Actualmente usan ALB en us-east-1. ¿Cuál es la mejor solución?

A) Desplegar ALBs en múltiples regiones con Route 53 Latency-based routing
B) Poner CloudFront delante del ALB
C) Usar AWS Global Accelerator delante del ALB
D) Asignar Elastic IPs al ALB

<details>
<summary>Ver respuesta</summary>

**Respuesta: C**

**AWS Global Accelerator** proporciona 2 IPs Anycast estáticas globales que los clientes pueden incluir en sus allowlists de firewall. El tráfico entra por el edge location más cercano al usuario y se enruta por la red global de AWS hasta el ALB, reduciendo la latencia significativamente. La opción A requiere desplegar infraestructura en múltiples regiones. La opción B proporciona un dominio DNS, no IPs estáticas. La opción D: los ALB no soportan Elastic IPs directamente (solo NLB).

**Servicio/concepto clave:** Global Accelerator, IPs Anycast estáticas, reduced latency
</details>
