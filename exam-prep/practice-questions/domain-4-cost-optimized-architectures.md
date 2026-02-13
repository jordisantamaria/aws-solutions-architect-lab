# Dominio 4: Diseñar Arquitecturas Optimizadas en Costo

## Pregunta 1

Una empresa ejecuta un clúster de instancias EC2 para procesamiento batch de datos que se ejecuta cada noche entre las 2:00 y las 6:00 AM. El procesamiento puede reiniciarse sin problemas si se interrumpe. ¿Cuál es la configuración más económica?

A) Instancias On-Demand ejecutándose 24/7
B) Instancias Reserved de 1 año
C) Instancias Spot con un Auto Scaling Group programado de 2:00 a 6:00 AM
D) Instancias On-Demand con un Auto Scaling Group programado de 2:00 a 6:00 AM

<details>
<summary>Ver respuesta</summary>

**Respuesta: C**

Las **Spot Instances** ofrecen hasta un 90% de descuento sobre On-Demand y son ideales para cargas tolerantes a interrupciones como procesamiento batch. Combinadas con un **Scheduled Scaling** que solo ejecuta instancias en el horario necesario (4 horas/noche), se minimiza el costo al máximo. Si una Spot es interrumpida, el batch puede reiniciarse según el escenario. La opción A paga 24 horas cuando solo necesita 4. La opción B paga todo el día durante un año. La opción D es correcta en horario pero más cara que Spot.

**Servicio/concepto clave:** Spot Instances, Scheduled Scaling, batch processing
</details>

---

## Pregunta 2

Una empresa almacena 50 TB de logs en S3 Standard. Los logs se analizan intensivamente los primeros 30 días, se acceden ocasionalmente durante los siguientes 90 días, y deben retenerse por 7 años por compliance. ¿Cuál es la configuración más económica?

A) Mantener todo en S3 Standard durante los 7 años
B) S3 Intelligent-Tiering para los 7 años completos
C) S3 Lifecycle Policy: Standard (30 días) → Standard-IA (90 días) → Glacier Deep Archive (7 años)
D) S3 Lifecycle Policy: Standard (30 días) → Glacier Flexible Retrieval (7 años)

<details>
<summary>Ver respuesta</summary>

**Respuesta: C**

La **Lifecycle Policy** con tres tiers optimiza el costo para cada fase de uso: S3 Standard para los 30 días de acceso intensivo, Standard-IA (más barato) para los 90 días de acceso ocasional, y Glacier Deep Archive (el más barato de todos, ~$0.00099/GB/mes) para la retención a largo plazo de 7 años. La opción A es la más cara. La opción B cobra tarifa de monitoreo por objeto. La opción D salta el tier IA, dejando datos en Glacier desde el día 31 cuando aún se acceden ocasionalmente (recuperación en horas).

**Servicio/concepto clave:** S3 Lifecycle Policy, tiered storage, Glacier Deep Archive
</details>

---

## Pregunta 3

Una aplicación tiene una base de datos RDS MySQL db.r5.2xlarge que opera 24/7 en producción. Los datos muestran que el CPU promedio es del 75% durante horas laborables (8AM-8PM) y del 10% fuera de horario. El equipo quiere reducir costos sin afectar el rendimiento durante horas pico. ¿Cuál es la mejor solución?

A) Comprar una Reserved Instance de 1 año para la instancia actual
B) Migrar a Aurora Serverless v2 que escala automáticamente según la demanda
C) Reducir a db.r5.xlarge y aceptar rendimiento degradado en pico
D) Parar la base de datos fuera de horas laborables

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

**Aurora Serverless v2** escala automáticamente la capacidad de compute (ACUs) basándose en la demanda real. Durante horas pico usa más ACUs (equivalente a la capacidad actual) y durante horas valle se reduce al mínimo, pagando solo por lo usado. Es compatible con MySQL, así que la migración es factible. La opción A reduce costo pero sigue pagando por capacidad ociosa fuera de horario. La opción C degrada el rendimiento. La opción D: no se puede parar una BD de producción que podría recibir requests 24/7.

**Servicio/concepto clave:** Aurora Serverless v2, auto-scaling, pay-per-use
</details>

---

## Pregunta 4

Una empresa transfiere 500 GB diarios de datos desde su aplicación en eu-west-1 a un bucket S3 en la misma región. También transfiere 100 GB diarios de datos procesados a otra cuenta AWS en la misma región. El equipo quiere minimizar los costos de transferencia de datos. ¿Qué es CORRECTO sobre los costos?

A) Ambas transferencias tienen costo de data transfer
B) La transferencia a S3 en la misma región es gratuita, y la transferencia cross-account en la misma región también es gratuita
C) La transferencia a S3 es gratuita, pero la transferencia cross-account tiene costo
D) Ambas transferencias son gratuitas porque están en la misma región

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

En AWS, la transferencia de datos **dentro de la misma región** es generalmente gratuita: de EC2 a S3 en la misma región es gratis, y la transferencia entre cuentas usando S3 en la misma región también es gratis (el costo es en data transfer IN que siempre es gratuito, y S3 requests). Sin embargo, la transferencia entre AZs tiene un costo mínimo. La transferencia cross-account dentro de la misma región vía S3 bucket policies o cross-account access no tiene cargo adicional de data transfer. Los costos principales son las API requests de S3 (PUT, GET), no la transferencia.

**Servicio/concepto clave:** Data transfer pricing, same-region transfers, cross-account
</details>

---

## Pregunta 5

Una startup tiene un tráfico web muy variable: picos de 100,000 requests/minuto durante lanzamientos de productos (unas pocas veces al mes) y tráfico base de 1,000 requests/minuto el resto del tiempo. Actualmente usan EC2 On-Demand con Auto Scaling. ¿Cuál es la configuración más económica?

A) Reserved Instances para el tráfico base + Spot Instances para los picos
B) Reserved Instances para la capacidad máxima
C) Savings Plans para el tráfico base + On-Demand Auto Scaling para los picos
D) Migrar completamente a Lambda + API Gateway con DynamoDB

<details>
<summary>Ver respuesta</summary>

**Respuesta: D**

Para cargas con alta variabilidad (100x entre base y pico), una arquitectura **serverless** es la más costo-efectiva. Lambda + API Gateway escala de 0 a millones de requests sin provisionar capacidad, y pagas exactamente por lo que usas. DynamoDB On-Demand escala automáticamente. Durante periodos base, el costo es mínimo. Durante picos, escala instantáneamente. La opción A es buena pero Spot no es adecuado para web (puede interrumpirse). La opción B paga por capacidad ociosa 95% del tiempo. La opción C es mejor que B pero sigue teniendo overhead de gestión.

**Servicio/concepto clave:** Serverless architecture, pay-per-use, Lambda + API Gateway + DynamoDB
</details>

---

## Pregunta 6

Una empresa tiene 200 instancias EC2 distribuidas en varias cuentas y regiones. Sospechan que muchas instancias están sobre-dimensionadas. ¿Qué servicio de AWS les ayuda a identificar instancias con recursos ociosos y recomendar el tamaño correcto?

A) AWS Trusted Advisor
B) AWS Cost Explorer con Right Sizing Recommendations
C) AWS Compute Optimizer
D) Amazon CloudWatch dashboards

<details>
<summary>Ver respuesta</summary>

**Respuesta: C**

**AWS Compute Optimizer** analiza las métricas de uso (CPU, memoria, red, disco) de las instancias EC2 usando machine learning y recomienda el tipo y tamaño de instancia óptimo. Funciona a nivel de organización, cubriendo múltiples cuentas. Proporciona estimaciones de ahorro concretas. La opción A da recomendaciones generales pero menos detalladas para rightsizing. La opción B ofrece recomendaciones de rightsizing pero menos sofisticadas que Compute Optimizer. La opción D solo muestra métricas sin recomendaciones.

**Servicio/concepto clave:** AWS Compute Optimizer, rightsizing, ML-based recommendations
</details>

---

## Pregunta 7

Un equipo de desarrollo ejecuta entornos de desarrollo y test en EC2 que solo se usan durante horario laboral (8AM-6PM, lunes a viernes). Actualmente las instancias están encendidas 24/7. ¿Cuál es la forma más eficiente de reducir costos?

A) Usar instancias Spot para todos los entornos de desarrollo
B) Usar AWS Instance Scheduler para iniciar/detener instancias automáticamente según horario
C) Comprar Reserved Instances para los entornos de desarrollo
D) Migrar los entornos de desarrollo a Lambda

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

**AWS Instance Scheduler** (solución de AWS) o scripts con EventBridge + Lambda permiten iniciar y detener instancias EC2 automáticamente según un horario definido. Ejecutando solo 10 horas al día, 5 días a la semana (50 horas) vs 168 horas semanales, se ahorra ~70% del costo. Las instancias detenidas no cobran por compute (solo almacenamiento EBS). La opción A puede causar interrupciones indeseadas en desarrollo. La opción C paga 24/7 por una instancia reservada. La opción D requiere reescribir la aplicación.

**Servicio/concepto clave:** Instance Scheduler, start/stop automation, development environments
</details>

---

## Pregunta 8

Una empresa paga $50,000/mes en instancias EC2 On-Demand. Las instancias incluyen una variedad de tipos (m5, c5, r5) en varias regiones. Tienen un compromiso estable de al menos $30,000/mes de uso predecible. ¿Cuál es la opción de ahorro más flexible?

A) Comprar Reserved Instances por $30,000/mes en tipos específicos
B) Comprar un Compute Savings Plan de $30,000/mes con compromiso de 1 año
C) Comprar un EC2 Instance Savings Plan de $30,000/mes
D) Usar solo Spot Instances para reducir la factura

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

Un **Compute Savings Plan** ofrece la máxima flexibilidad: aplica automáticamente el descuento a cualquier uso de EC2 (cualquier familia, tamaño, OS, tenancy, región), Lambda y Fargate. Con un compromiso de $30/hr, la empresa obtiene descuentos de hasta 66% sobre ese monto y paga On-Demand el resto. A diferencia de Reserved Instances (opción A) o EC2 Instance Savings Plan (opción C), no necesitan elegir familia de instancia o región específica. La opción D no es aplicable para todas las cargas.

**Servicio/concepto clave:** Compute Savings Plans, flexibility, cost commitment
</details>

---

## Pregunta 9

Una aplicación almacena millones de objetos en S3 Standard. El análisis muestra que el 60% de los objetos no se acceden después de los primeros 7 días, pero no pueden predecir cuáles serán accedidos. El equipo quiere reducir costos de almacenamiento sin afectar el rendimiento de acceso. ¿Cuál es la mejor solución?

A) Mover todo a S3 Standard-IA después de 7 días con Lifecycle Policy
B) Habilitar S3 Intelligent-Tiering en el bucket
C) Mover todo a S3 One Zone-IA después de 7 días
D) Comprimir los objetos antes de almacenarlos

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

**S3 Intelligent-Tiering** monitorea el patrón de acceso de cada objeto individualmente y lo mueve automáticamente entre tiers (Frequent → Infrequent → Archive Instant → Archive → Deep Archive) sin costos de retrieval. Como no pueden predecir qué objetos se accederán, Intelligent-Tiering es ideal. La opción A movería TODO a IA, incluyendo el 40% que sí se accede (cobrando retrieval fees). La opción C pone datos en 1 AZ (menor durabilidad) y también cobra retrieval. La opción D ayuda pero no optimiza tiers.

**Servicio/concepto clave:** S3 Intelligent-Tiering, automatic tiering, unpredictable access patterns
</details>

---

## Pregunta 10

Una empresa tiene una arquitectura con ALB → EC2 → RDS. Cada mes reciben una factura de $15,000 en data transfer. Después de analizar la factura, descubren que la mayoría del costo es data transfer OUT a internet. ¿Cuáles son dos formas de reducir este costo? (Selecciona DOS)

A) Usar CloudFront delante del ALB para cachear contenido y reducir data transfer desde el origin
B) Comprimir las respuestas con gzip en las instancias EC2
C) Mover la aplicación a una región más barata
D) Usar VPC Peering para la comunicación entre EC2 y RDS
E) Habilitar S3 Transfer Acceleration

<details>
<summary>Ver respuesta</summary>

**Respuesta: A y B**

**A)** CloudFront cachea contenido en edge locations. Los datos servidos desde cache no generan data transfer OUT desde el origin. Además, la transferencia de CloudFront a internet es más barata que desde EC2 directamente. **B)** La compresión gzip reduce el tamaño de las respuestas (típicamente 60-80% para texto/JSON/HTML), lo que directamente reduce la cantidad de GB de data transfer OUT. La opción C no necesariamente reduce el costo de transfer OUT. La opción D: EC2 y RDS en la misma AZ ya tienen transferencia económica. La opción E es para uploads a S3.

**Servicio/concepto clave:** Data transfer optimization, CloudFront caching, gzip compression
</details>

---

## Pregunta 11

Una empresa ejecuta una aplicación web 24/7 con las siguientes instancias EC2: 4 instancias m5.xlarge como carga base constante y hasta 8 instancias adicionales durante picos (varias horas al día). ¿Cuál es la estrategia de compra más económica?

A) 12 Reserved Instances para cubrir el máximo
B) 4 Reserved Instances (base) + 8 On-Demand (picos)
C) 4 Reserved Instances (base) + Auto Scaling con una mezcla de On-Demand y Spot para los picos
D) 12 Spot Instances para todo

<details>
<summary>Ver respuesta</summary>

**Respuesta: C**

La estrategia óptima es **Reserved Instances** (o Savings Plans) para la carga base de 4 instancias (descuento hasta 72%) y un **ASG con mixed instances policy** que combine On-Demand y Spot para los picos. La mixed instances policy puede configurarse, por ejemplo, con 20% On-Demand (garantiza capacidad mínima) y 80% Spot (máximo ahorro). La opción A paga reserved 24/7 por capacidad de pico. La opción B es buena pero no aprovecha Spot. La opción D es arriesgada para toda la aplicación (Spot puede interrumpirse).

**Servicio/concepto clave:** Mixed instances policy, Reserved + Spot strategy, ASG
</details>

---

## Pregunta 12

Un equipo necesita rastrear y distribuir los costos de AWS entre 10 departamentos que comparten la misma cuenta AWS. ¿Cuál es la forma más efectiva de asignar costos por departamento?

A) Crear cuentas AWS separadas para cada departamento
B) Usar Cost Allocation Tags y activarlas en la consola de Billing, asignando un tag "Department" a cada recurso
C) Usar AWS Budgets para establecer límites por departamento
D) Revisar la factura manualmente y dividir por servicio

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

**Cost Allocation Tags** permiten etiquetar recursos con metadata como "Department:Marketing" y luego ver los costos desglosados por tag en Cost Explorer y los Cost & Usage Reports. Se deben activar como "cost allocation tags" en la consola de Billing para que aparezcan en los reportes. También se pueden usar **Tag Policies** de Organizations para forzar el etiquetado consistente. La opción A funciona pero es una medida drástica. La opción C establece alertas pero no asigna costos. La opción D no escala.

**Servicio/concepto clave:** Cost Allocation Tags, Cost Explorer, cost attribution
</details>

---

## Pregunta 13

Una empresa tiene un bucket S3 con 100 TB de datos. Cada mes suben 5 TB adicionales. Necesitan mantener los datos indefinidamente pero solo acceden al último mes activamente. El presupuesto para almacenamiento es limitado. Actualmente todo está en S3 Standard ($0.023/GB/mes). ¿Cuánto podrían ahorrar aproximadamente con una Lifecycle Policy optimizada?

A) ~10% de ahorro
B) ~30% de ahorro
C) ~60% de ahorro
D) ~80% de ahorro

<details>
<summary>Ver respuesta</summary>

**Respuesta: D**

Cálculo aproximado: Con 100 TB en Standard a $0.023/GB/mes = ~$2,300/mes. Con Lifecycle Policy: 5 TB (último mes) en Standard = ~$115/mes. 95 TB en Glacier Deep Archive a $0.00099/GB/mes = ~$94/mes. Total optimizado: ~$209/mes vs $2,300/mes = **~91% de ahorro**. Incluso con un tier intermedio (IA para los últimos 3 meses), el ahorro supera el 80%. La clave es que Glacier Deep Archive es ~23x más barato que Standard. Para 100 TB donde 95% no se accede, el ahorro es masivo.

**Servicio/concepto clave:** S3 Lifecycle Policy, Glacier Deep Archive pricing, storage optimization
</details>

---

## Pregunta 14

Una empresa tiene un contrato de licencia de Oracle Database que requiere ejecución en hardware dedicado específico. Necesitan que la base de datos corra en AWS con el menor costo posible manteniendo compliance con la licencia. ¿Cuál es la mejor opción?

A) RDS for Oracle con licencia incluida (License Included)
B) EC2 Dedicated Hosts con Oracle instalado manualmente (BYOL)
C) EC2 On-Demand con Oracle instalado
D) RDS for Oracle en Multi-AZ

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

Los **EC2 Dedicated Hosts** proporcionan servidores físicos dedicados donde el cliente tiene visibilidad del hardware subyacente (sockets, cores). Esto permite cumplir con requisitos de licenciamiento de Oracle que requieren ejecución en hardware específico (BYOL - Bring Your Own License). Los Dedicated Hosts también son elegibles para **Reserved Pricing**, lo que reduce el costo significativamente. La opción A incluye costo de licencia (más caro). La opción C no es hardware dedicado. La opción D no cumple requisitos de licencia por hardware.

**Servicio/concepto clave:** EC2 Dedicated Hosts, BYOL, Oracle licensing compliance
</details>

---

## Pregunta 15

Un equipo quiere implementar alertas proactivas cuando el gasto de AWS se acerque a límites predefinidos. Necesitan notificaciones cuando se alcance el 50%, 80% y 100% del presupuesto mensual de $10,000. También quieren una acción automática para detener instancias EC2 no críticas cuando se alcance el 90%. ¿Cuál es la solución correcta?

A) Configurar CloudWatch alarms basadas en métricas de billing con acciones SNS
B) Configurar AWS Budgets con alertas de threshold (50%, 80%, 100%) vinculadas a SNS, y un Budget Action al 90% que ejecute una política para detener instancias
C) Usar AWS Cost Explorer para revisar gastos diariamente
D) Crear una Lambda que revise la factura diariamente vía la API de Cost Explorer

<details>
<summary>Ver respuesta</summary>

**Respuesta: B**

**AWS Budgets** permite crear presupuestos con múltiples thresholds de alerta y acciones automáticas. Se configuran las alertas al 50%, 80% y 100% que envían notificaciones vía SNS (email, SMS). Al 90%, un **Budget Action** puede ejecutar automáticamente una IAM policy que restrinja el lanzamiento de instancias o ejecutar una acción de Systems Manager para detener instancias no críticas. La opción A solo permite alarmas simples sin acciones automatizadas complejas. Las opciones C y D son manuales/reactivas, no proactivas.

**Servicio/concepto clave:** AWS Budgets, Budget Actions, cost alerts, automated cost control
</details>
