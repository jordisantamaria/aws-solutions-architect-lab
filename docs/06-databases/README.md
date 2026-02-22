# Bases de Datos en AWS (Databases)

## Índice

- [Amazon RDS](#amazon-rds)
- [RDS Proxy](#rds-proxy)
- [Amazon Aurora](#amazon-aurora)
- [Amazon DynamoDB](#amazon-dynamodb)
- [DynamoDB Avanzado](#dynamodb-avanzado)
- [Amazon ElastiCache](#amazon-elasticache)
- [Amazon Redshift](#amazon-redshift)
- [Amazon Neptune](#amazon-neptune)
- [Amazon DocumentDB](#amazon-documentdb)
- [Amazon Keyspaces](#amazon-keyspaces)
- [Amazon QLDB](#amazon-qldb)
- [Amazon Timestream](#amazon-timestream)
- [Árbol de decisión de bases de datos](#árbol-de-decisión-de-bases-de-datos)
- [Tips para el examen](#tips-para-el-examen)

---

## Amazon RDS

Amazon Relational Database Service es un servicio gestionado de bases de datos relacionales.

### Motores soportados

| Motor | Notas |
|---|---|
| **MySQL** | Compatible con Aurora |
| **PostgreSQL** | Compatible con Aurora |
| **MariaDB** | Fork de MySQL |
| **Oracle** | Licencia incluida o BYOL |
| **Microsoft SQL Server** | Licencia incluida |

### Características principales

- **Servicio gestionado**: AWS gestiona parches, backups, monitoreo, escalado.
- **No se puede acceder por SSH** a la instancia subyacente.
- Almacenamiento respaldado por EBS (gp2, gp3, io1).

### Multi-AZ (Alta Disponibilidad)

- Réplica **síncrona** en otra AZ de la misma región.
- **Failover automático** ante fallos (DNS automático, no requiere cambios en la app).
- La instancia standby **NO sirve tráfico de lectura** (solo failover).
- Se puede convertir de Single-AZ a Multi-AZ **sin downtime** (snapshot interno → restore en otra AZ → sincronización).

```
                    ┌──────────────┐
                    │   Aplicación │
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │  RDS Master  │ ◄──── Endpoint DNS
                    │   (AZ-a)     │       (failover automático)
                    └──────┬───────┘
                           │ Replicación SÍNCRONA
                    ┌──────▼───────┐
                    │  RDS Standby │
                    │   (AZ-b)     │
                    └──────────────┘
```

### Read Replicas (Escalado de lecturas)

- Hasta **15 réplicas de lectura** (dentro de AZ, cross-AZ, cross-Region).
- Replicación **ASÍNCRONA** (eventualmente consistente).
- Las réplicas se pueden **promover a DB independiente**.
- La aplicación debe actualizar la connection string para usar las réplicas.
- **Coste de red**: No hay cargo por replicación dentro de la misma región. Cross-Region sí tiene cargo.

**Casos de uso**: Reportes, analytics, cargas de lectura intensiva.

> **Clave**: Multi-AZ = alta disponibilidad (HA). Read Replicas = escalabilidad de lectura. Son complementarios, no excluyentes.

### Storage Auto Scaling

- Incrementa automáticamente el almacenamiento cuando se acerca al límite.
- Se establece un **Maximum Storage Threshold** (límite máximo).
- Se activa cuando:
  - El espacio libre es < 10% del almacenamiento asignado.
  - La condición persiste durante 5 minutos.
  - Han pasado al menos 6 horas desde la última modificación.
- Útil para cargas de trabajo impredecibles.

### Backup y Restore

**Automated Backups:**
- Habilitados por defecto.
- Backup diario completo (durante la ventana de mantenimiento).
- Transaction logs cada 5 minutos.
- Retención de 1 a 35 días (0 para deshabilitar).
- Restauración a **cualquier punto en el tiempo** (Point-in-Time Recovery) con granularidad de 5 minutos.

**Manual Snapshots:**
- Iniciados manualmente por el usuario.
- Se conservan indefinidamente hasta que se eliminan.
- Se pueden copiar entre regiones.

> **Clave**: Restaurar un backup o snapshot **siempre crea una nueva instancia RDS** con un nuevo endpoint.

### IAM DB Authentication

Método de autenticación que reemplaza usuario/contraseña por tokens temporales generados via IAM. Soportado en **MySQL** y **PostgreSQL**.

**Autenticación tradicional vs IAM DB Auth:**

```
Tradicional:
  App en EC2 ──► conecta con usuario="admin" password="s3cret123"
                 (contraseña almacenada en config o Secrets Manager)

IAM DB Auth:
  1. EC2 tiene un IAM Role con permiso rds-db:connect
  2. App pide token ──► API de RDS genera token firmado con credenciales del IAM Role
  3. App conecta con usuario="iam_user" password=TOKEN
                   (el token expira en 15 minutos)
```

**El token no se almacena.** La app genera un token nuevo cada vez que necesita una conexión. Si la conexión ya está abierta, sigue funcionando. Para una nueva conexión, pide otro token.

**Beneficios:**
- No hay contraseñas que gestionar, rotar ni que puedan filtrarse.
- El tráfico está cifrado con SSL automáticamente.
- Control de acceso centralizado con IAM policies (quién puede conectarse a qué DB).
- En EC2: usa las credenciales del **instance profile** (IAM Role) automáticamente, sin configuración adicional.

**Limitaciones:**
- Solo MySQL y PostgreSQL (no Oracle, SQL Server ni MariaDB en RDS).
- Máximo **256 conexiones por segundo** con IAM auth (no es para alto throughput de conexiones).
- El token dura **15 minutos** (pero las conexiones ya establecidas no se cortan).

> **Tip para el examen:** Si la pregunta dice "authentication token" o "profile credentials of EC2" para conectar a RDS → **IAM DB Authentication**. No confundir con simplemente asignar un IAM Role a EC2 (eso da permisos a la API de AWS, no autenticación directa a la base de datos). No confundir con SSL (que cifra la conexión pero no cambia el método de autenticación).

### Acceso a RDS privado (para desarrollo y mantenimiento)

RDS debe estar en una subnet privada (sin acceso directo desde Internet). Para conectarse desde tu portátil con herramientas como pgAdmin o DBeaver, hay varias opciones de menos a más complejidad:

| Método | Necesita EC2? | Necesita VPN? | Complejidad |
|---|---|---|---|
| **EC2 Instance Connect Endpoint** | No | No | Baja |
| **SSM Port Forwarding** | Sí (privada, sin SSH) | No | Baja |
| **Client VPN** | No | Sí | Media |
| **Bastion + SSH tunnel** | Sí (pública, con SSH) | No | Alta |

#### EC2 Instance Connect Endpoint (recomendado)

Permite crear un túnel directo a recursos privados **sin necesidad de EC2 intermediarias ni VPN**. Se crea como un endpoint dentro de la VPC y el acceso se controla exclusivamente con IAM y Security Groups.

```
Tu portátil ──► EC2 Instance Connect Endpoint ──► RDS (subnet privada)
                (túnel seguro via API de AWS)
                No hay bastion, no hay VPN, no hay SSH
```

Se usa con el CLI de AWS:
```bash
aws ec2-instance-connect open-tunnel \
  --instance-connect-endpoint-id eice-xxxx \
  --remote-host-address mydb.xxxx.rds.amazonaws.com \
  --remote-port 5432 \
  --local-port 5432

# pgAdmin conecta a localhost:5432 como si RDS fuera local
```

**Requisitos:**
- Crear un EC2 Instance Connect Endpoint en una subnet de la VPC.
- Security Group del endpoint con acceso al puerto de RDS.
- Permisos IAM para `ec2-instance-connect:OpenTunnel`.

#### SSM Session Manager con Port Forwarding

Requiere una instancia EC2 privada con SSM Agent (viene preinstalado por defecto), pero **no necesita bastion ni puertos SSH abiertos**:

```
Tu portátil ──► SSM Session Manager ──► EC2 (privada) ──► RDS
                (túnel por API de AWS)   (solo necesita SSM Agent)
```

> **Tip para el examen:** Si la pregunta dice "acceso seguro a recursos privados sin bastion ni SSH" → **SSM Session Manager** o **EC2 Instance Connect Endpoint**. Si dice "acceso a RDS privado sin EC2 intermediaria" → **EC2 Instance Connect Endpoint**.

---

## RDS Proxy

Proxy gestionado de base de datos que se sitúa entre la aplicación y RDS.

### Beneficios

- **Connection pooling**: Reduce y reutiliza conexiones a la base de datos.
- **Menor failover time**: Reduce el tiempo de failover Multi-AZ hasta un **66%**.
- Soporta **IAM authentication** para la conexión a la DB.
- Las credenciales se almacenan en **AWS Secrets Manager**.
- **Nunca es accesible públicamente** (solo desde dentro de la VPC).

### Cuándo usar RDS Proxy

| Escenario | Problema sin Proxy | Solución con Proxy |
|---|---|---|
| **Lambda + RDS** | Cada invocación Lambda abre una conexión. Con alta concurrencia se agotan las conexiones | El proxy gestiona un pool de conexiones compartido |
| **Failover Multi-AZ** | Tiempo de failover de ~60-120 segundos | Reduce a ~30 segundos |
| **Muchos microservicios** | Cada servicio abre sus propias conexiones | Pool compartido reduce conexiones totales |

> **Clave para el examen**: Si una pregunta menciona Lambda + RDS con problemas de conexiones, la respuesta casi siempre es RDS Proxy.

---

## Amazon Aurora

Base de datos relacional propietaria de AWS, compatible con **MySQL** y **PostgreSQL**. Hasta **5x mejor rendimiento que MySQL** y **3x mejor que PostgreSQL**.

### Arquitectura

- Almacenamiento distribuido y auto-replicado en **6 copias** a través de **3 AZs**.
  - Necesita solo 4/6 copias para escrituras.
  - Necesita solo 3/6 copias para lecturas.
  - Self-healing con peer-to-peer replication.
- Almacenamiento **auto-escalable** de 10 GB hasta **128 TB**.
- **Failover instantáneo** (< 30 segundos).

```
    ┌─────────────┐      ┌─────────────┐
    │   Writer     │      │  Reader(s)  │
    │  Endpoint    │      │  Endpoint   │
    └──────┬──────┘      └──────┬──────┘
           │                     │
    ┌──────▼─────────────────────▼──────┐
    │     Shared Storage Volume         │
    │  (Auto-scaling, 6 copies, 3 AZs) │
    │  10 GB ──────────────► 128 TB     │
    └───────────────────────────────────┘
```

### Aurora Replicas

- Hasta **15 réplicas de lectura** con replicación de baja latencia (< 10 ms de lag).
- Failover automático a cualquier réplica (se puede configurar prioridad con **tiers**).
- **Reader Endpoint**: Balanceo de carga automático a nivel de conexión entre réplicas.
- **Custom Endpoints**: Dirigir tráfico a un subconjunto de réplicas (ej: réplicas más potentes para analytics).

### Aurora Global Database

- **1 región primaria** (lectura/escritura).
- Hasta **5 regiones secundarias** (solo lectura).
- Hasta 16 réplicas de lectura por región secundaria.
- Latencia de replicación < **1 segundo** cross-region.
- **Failover cross-region** con RTO < 1 minuto.
- Caso de uso: Disaster recovery global, baja latencia para lecturas globales.

### Aurora Serverless v2

- Escalado automático de la capacidad de cómputo basado en la carga.
- Se define un rango de **ACUs (Aurora Capacity Units)**: mínimo y máximo.
- Escala en incrementos granulares (no en pasos discretos como v1).
- Soporta Multi-AZ.
- **Caso de uso**: Cargas impredecibles, desarrollo, entornos con tráfico intermitente.

### Aurora Machine Learning

- Integración directa con **SageMaker** y **Amazon Comprehend**.
- Ejecutar inferencias ML directamente desde consultas SQL.
- Caso de uso: Detección de fraude, análisis de sentimiento, recomendaciones.

### Aurora Native Functions y Stored Procedures (invocar Lambda)

Aurora puede **llamar a AWS Lambda directamente desde dentro de la base de datos**, usando native functions o stored procedures. Esto permite reaccionar a cambios en los datos (INSERT, UPDATE, DELETE) desde la propia DB.

```
App borra un registro ──► Aurora ejecuta trigger/stored procedure
                              │
                              ▼
                         Llama a Lambda (native function)
                              │
                              ▼
                         Lambda procesa (envía a SQS, SNS, etc.)
```

**Ejemplo (Aurora MySQL):**
```sql
-- Stored procedure que invoca Lambda al borrar un coche:
CALL mysql.lambda_async(
    'arn:aws:lambda:eu-west-1:123456:function:procesar-venta',
    '{"car_id": 123, "action": "sold"}'
);
```

**Requisitos:**
- Aurora MySQL o Aurora PostgreSQL (RDS estándar no lo soporta).
- El cluster Aurora necesita un IAM Role con permisos para invocar Lambda.
- Conectividad de red entre Aurora y Lambda (NAT Gateway o VPC endpoint para Lambda).

#### RDS Event Subscription vs Native Functions

| | RDS Event Subscription | Native Function / Stored Procedure |
|---|---|---|
| **Detecta** | Eventos **operacionales** (failover, backup, maintenance) | Cambios **en los datos** (INSERT, UPDATE, DELETE) |
| **Ejemplo** | "La instancia se reinició" | "Se borró el registro con id=123" |
| **Destino** | SNS | Lambda (directamente desde la DB) |
| **Solo Aurora?** | No (funciona con cualquier RDS) | **Sí** (solo Aurora puede invocar Lambda) |

> **Tip para el examen:** Si la pregunta dice "reaccionar cuando se modifica/borra un registro en Aurora" → **native function o stored procedure que invoca Lambda**. No confundir con RDS Event Subscription, que solo detecta eventos de infraestructura (failovers, backups), no cambios en los datos.

### Otras características de Aurora

| Característica | Descripción |
|---|---|
| **Backtracking** | Rebobinar la base de datos a un punto en el tiempo sin restaurar desde backup. Solo Aurora MySQL. No crea nueva instancia. |
| **Cloning** | Crear una copia de la DB usando copy-on-write. Rápido y eficiente en almacenamiento. Ideal para testing en producción. |
| **Database Activity Streams** | Auditoría en tiempo real de la actividad de la DB. Se envía a Kinesis Data Streams. |

> **Clave**: Aurora Backtracking "rebobina" la DB existente in-place. Restaurar desde backup crea una nueva instancia. Son conceptos diferentes.

---

## Amazon DynamoDB

Base de datos NoSQL serverless, totalmente gestionada, con rendimiento de milisegundos de un solo dígito.

### Conceptos fundamentales

- **Tables**: Colección de items.
- **Items**: Cada registro (similar a una fila). Tamaño máximo: **400 KB**.
- **Attributes**: Campos del item.

### Claves

| Tipo de clave | Descripción | Ejemplo |
|---|---|---|
| **Partition Key (PK)** | Clave primaria simple. Debe ser única. | `user_id` |
| **Partition Key + Sort Key (PK + SK)** | Clave compuesta. La combinación debe ser única. | `user_id` + `timestamp` |

La **Partition Key** determina en qué partición se almacena el item. DynamoDB aplica una función hash interna sobre el valor de la PK para decidir en qué partición física va cada item.

### Cardinalidad de la Partition Key (hot partitions)

La elección de la PK es la decisión de diseño más importante en DynamoDB. La capacidad provisionada (RCU/WCU) se reparte **uniformemente entre las particiones**. Si una partición recibe más tráfico que las demás, se produce **throttling** aunque la tabla tenga capacidad total sobrante.

**Alta cardinalidad** = muchos valores distintos = buena distribución:

```
PK = user_id  →  millones de valores distintos  →  tráfico repartido entre muchas particiones
PK = order_id →  millones de valores distintos  →  tráfico repartido entre muchas particiones
```

**Baja cardinalidad** = pocos valores distintos = "hot partition":

```
PK = status ("active"/"inactive")  →  solo 2 valores  →  todo el tráfico va a 2 particiones
PK = country_code                  →  ~200 valores     →  particiones de US/CN reciben el 80% del tráfico
```

**Ejemplo numérico:**
- Tabla con 10,000 WCU provisionados y 10 particiones → cada partición recibe 1,000 WCU.
- Si usas `status` como PK (2 valores), el 90% de writes van a la partición "active" → esa partición tiene 1,000 WCU pero recibe 9,000 → **throttling**, aunque la tabla tenga 9,000 WCU sin usar en otras particiones.

**Soluciones para hot partitions:**
- Elegir una PK con **alta cardinalidad** (user_id, order_id, session_id).
- **Write Sharding**: Añadir un sufijo aleatorio a la PK (ej: `status#1`, `status#2`, ..., `status#10`) para forzar distribución.
- Usar claves compuestas (PK + SK) para tener más combinaciones únicas.

> **Tip para el examen:** Si preguntan "distribuir workload uniformemente" o "utilizar throughput eficientemente" en DynamoDB → **partition key con alta cardinalidad**. Si dicen "hot partition" o "throttling con capacidad sobrante" → el problema es una PK con baja cardinalidad.

### Índices secundarios

| Tipo | Descripción | Creación | Límite |
|---|---|---|---|
| **GSI (Global Secondary Index)** | PK y SK alternativas. Se puede consultar sobre atributos no clave. Tiene su propia tabla proyectada. | En cualquier momento | 20 por tabla |
| **LSI (Local Secondary Index)** | Misma PK de la tabla, pero diferente SK. | Solo al crear la tabla | 5 por tabla |

**Notas importantes sobre GSI:**

- Si el GSI tiene throttling, la tabla base también sufre throttling.
- El GSI consume su propia capacidad de lectura/escritura (WCU/RCU separados).
- Se recomienda elegir cuidadosamente la PK del GSI para evitar hot partitions.

### Modos de capacidad

| Modo | Descripción | Precio | Caso de uso |
|---|---|---|---|
| **Provisioned** | Se definen RCU y WCU por adelantado. Auto scaling opcional. | Más económico para cargas predecibles | Tráfico estable, predecible |
| **On-Demand** | Escala automáticamente sin planificar. Sin throttling por capacidad. | ~2.5x más caro que provisioned | Tráfico impredecible, nuevas tablas, spiky |

**Unidades de capacidad:**

- **1 RCU** = 1 lectura strongly consistent de hasta 4 KB/s, o 2 lecturas eventually consistent de hasta 4 KB/s.
- **1 WCU** = 1 escritura de hasta 1 KB/s.

> **Ejemplo de cálculo**: Leer 10 items de 6 KB cada uno por segundo (strongly consistent):
> Cada item necesita ceil(6/4) = 2 RCU → 10 * 2 = **20 RCU**.

---

## DynamoDB Avanzado

### DAX (DynamoDB Accelerator)

- Cache in-memory para DynamoDB, totalmente gestionado.
- Latencia de **microsegundos** (vs milisegundos de DynamoDB).
- Compatible con la API de DynamoDB existente (cambio mínimo de código).
- TTL por defecto de **5 minutos**.
- Cluster de hasta 11 nodos, Multi-AZ.
- **No sirve para writes**, solo para lecturas cacheadas.

**DAX vs ElastiCache para DynamoDB:**

| | DAX | ElastiCache |
|---|---|---|
| **Integración** | Nativa con DynamoDB | Requiere lógica de aplicación |
| **Tipo de cache** | Individual items y query results | Resultados computados/agregados |
| **Caso de uso** | Cache de lecturas DynamoDB | Almacenar resultados de cálculos complejos |

### DynamoDB Streams

- Flujo ordenado de cambios (inserciones, actualizaciones, eliminaciones) en la tabla.
- Retención de **24 horas**.
- Se pueden procesar con **Lambda** o **Kinesis Data Streams** (opción más reciente con retención de 1 año).
- Casos de uso: Reaccionar a cambios en tiempo real, replicación cross-region, analytics.

### DynamoDB Global Tables

- Tablas replicadas en **múltiples regiones**.
- Replicación **activa-activa** (lectura y escritura en cualquier región).
- Requiere DynamoDB Streams habilitado.
- Latencia de replicación típica: **< 1 segundo**.
- Caso de uso: Aplicaciones globales de baja latencia, DR multi-región.

### TTL (Time To Live)

- Elimina automáticamente items expirados sin consumir WCU.
- Se define un atributo con un timestamp Unix (epoch) de expiración.
- La eliminación real puede tardar hasta **48 horas** después de la expiración.
- Los items expirados aparecen en DynamoDB Streams.
- Caso de uso: Sesiones de usuario, datos temporales, logs con retención.

### Backup y Restore

| Tipo | Descripción |
|---|---|
| **On-demand backup** | Backup completo, se conserva hasta eliminarlo. Sin impacto en rendimiento. |
| **Point-in-time recovery (PITR)** | Restauración continua a cualquier punto en los últimos 35 días. Debe habilitarse explícitamente. |

> **Nota**: Restaurar siempre crea una **nueva tabla**.

### DynamoDB - Patrones de diseño para el examen

- **Write Sharding**: Añadir un sufijo aleatorio a la PK para distribuir escrituras.
- **Sparse Index**: GSI sobre atributos que solo existen en algunos items para consultas eficientes.
- **Composite Key**: Usar SK jerárquica (ej: `COUNTRY#US#STATE#CA#CITY#LA`).

---

## Amazon ElastiCache

Servicio de caché en memoria gestionado. Soporta dos motores:

### Redis vs Memcached

| Característica | Redis | Memcached |
|---|---|---|
| **Modelo de datos** | Estructuras complejas (strings, hashes, lists, sets, sorted sets) | Key-value simple |
| **Persistencia** | Sí (AOF, RDB) | No |
| **Replicación** | Sí (Read Replicas) | No |
| **Alta disponibilidad** | Multi-AZ con failover automático | No |
| **Backup y restore** | Sí | No |
| **Pub/Sub** | Sí | No |
| **Clustering** | Cluster mode (particionamiento de datos) | Multi-node partitioning |
| **Multi-thread** | No (single-threaded) | Sí (multi-threaded) |
| **Caso de uso** | Sesiones, leaderboards, pub/sub, geoespacial, HA requerida | Cache simple, alta concurrencia |

> **Regla para el examen**: Si la pregunta necesita HA, persistencia, o estructuras de datos complejas → **Redis**. Si solo necesita cache simple multi-threaded → **Memcached**.

### Estrategias de caching

| Estrategia | Descripción | Pros | Contras |
|---|---|---|---|
| **Lazy Loading** | Carga datos en cache solo cuando se solicitan (cache miss → leer DB → escribir cache) | Solo se cachean datos necesarios. Resiliente a fallos de cache | Cache miss = 3 llamadas (penalty). Datos pueden quedar stale |
| **Write-Through** | Escribe en cache cada vez que se actualiza la DB | Datos siempre frescos en cache | Write penalty (2 escrituras). Cache puede llenarse con datos no leídos |
| **Session Store** | Usar ElastiCache para almacenar sesiones de usuario con TTL | Aplicaciones stateless. Expiración automática | Requiere lógica de aplicación |

**Combinación recomendada**: Lazy Loading + TTL para datos que pueden estar stale un tiempo razonable.

### ElastiCache - Seguridad

ElastiCache Redis tiene tres capas de seguridad independientes:

| Capa | Qué protege | Cómo |
|---|---|---|
| **At-rest encryption** | Datos almacenados en disco/memoria | Cifrado con KMS. Se habilita al crear el cluster. |
| **In-transit encryption** | Datos en tránsito entre cliente y Redis | TLS. Se habilita con `--transit-encryption-enabled`. |
| **Autenticación** | Quién puede ejecutar comandos | Redis AUTH o IAM authentication. |

#### Redis AUTH vs IAM Authentication

| | Redis AUTH | IAM Authentication |
|---|---|---|
| **Credencial** | Password estático (auth-token) | Token temporal generado via IAM |
| **Duración** | Long-lived (no expira hasta que lo cambies) | Short-lived (expira automáticamente) |
| **Requisito** | **Requiere in-transit encryption (TLS)** | Requiere in-transit encryption (TLS) |
| **Gestión** | Tú gestionas el password | IAM gestiona credenciales |
| **Caso de uso** | Apps que necesitan credenciales fijas | Apps que ya usan IAM Roles (EC2, Lambda) |

```
Redis AUTH:
  Cliente ──► AUTH mi-password ──► Redis acepta ──► MULTI / SET / EXEC funcionan
              (password fijo, long-lived, requiere TLS habilitado)

IAM Authentication:
  App ──► genera token IAM ──► AUTH token-temporal ──► Redis acepta
          (token expira, short-lived)
```

**Importante:** Redis AUTH **no funciona sin in-transit encryption**. El flag `--auth-token` solo se puede usar junto con `--transit-encryption-enabled`. Si solo habilitas at-rest encryption o solo TLS sin auth-token, no hay autenticación de usuarios.

- Security Groups para control de red (quién puede conectarse al puerto de Redis).

---

## Amazon Redshift

Data warehouse basado en PostgreSQL, diseñado para **OLAP** (Online Analytical Processing) a escala de petabytes.

### Características principales

- Almacenamiento **columnar** (no por filas).
- Compresión de datos columnar.
- **MPP (Massively Parallel Processing)**: Distribuye queries entre nodos.
- Nodos **Leader** (planifica queries) y nodos **Compute** (ejecutan queries).
- No es Multi-AZ (cluster en una sola AZ).
- Carga de datos desde S3, DynamoDB, DMS, u otros.

### Redshift Spectrum

- Ejecuta queries directamente sobre datos en **S3** sin necesidad de cargarlos.
- Los nodos Compute no participan; se usan miles de nodos Spectrum dedicados.
- Caso de uso: Consultar datos históricos en S3 sin moverlos a Redshift.

### Snapshots y DR

- Los snapshots se almacenan internamente en S3.
- Snapshots incrementales.
- Se pueden copiar automáticamente a **otra región** para DR.
- Se puede restaurar un snapshot en un nuevo cluster.

### Redshift Serverless

- Escala automáticamente según la carga.
- No hay que gestionar la infraestructura del cluster.
- Pago por RPU (Redshift Processing Units) consumidos.
- Ideal para cargas intermitentes o impredecibles de analytics.

> **Clave para el examen**: Redshift es para analytics/OLAP, NO para OLTP. Si la pregunta es sobre un data warehouse o BI, piensa en Redshift. Si necesita datos de S3 sin moverlos, piensa en Redshift Spectrum.

---

## Amazon Neptune

Base de datos de **grafos** totalmente gestionada.

### Características

- Alta disponibilidad con replicación en hasta 3 AZs, 15 réplicas de lectura.
- Optimizada para relaciones complejas entre datos.
- Soporta modelos de grafos: **Property Graph** (Gremlin) y **RDF** (SPARQL).
- Latencia de milisegundos para queries de grafos.
- Almacena miles de millones de relaciones.

### Casos de uso

| Caso de uso | Descripción |
|---|---|
| **Redes sociales** | Relaciones entre usuarios, amigos, likes, posts |
| **Motor de recomendaciones** | "Usuarios que compraron esto también compraron..." |
| **Detección de fraude** | Patrones de transacciones sospechosas |
| **Knowledge graphs** | Relaciones entre entidades (Wikipedia, etc.) |
| **Network management** | Topología de red, dependencias |

> **Clave**: Si la pregunta menciona "grafos", "relaciones complejas entre entidades", o "red social", la respuesta es **Neptune**.

---

## Amazon DocumentDB

Base de datos documental compatible con **MongoDB**.

### Características

- Totalmente gestionada, alta disponibilidad con replicación en 3 AZs.
- Almacenamiento auto-escalable de 10 GB hasta 64 TB.
- Hasta 15 réplicas de lectura con latencia < 10 ms.
- Escala automáticamente para millones de requests por segundo.

### Cuándo usar

- Migración de workloads **MongoDB** a AWS.
- Aplicaciones que necesitan almacenamiento de documentos JSON.
- Cuando no quieres gestionar MongoDB manualmente.

> **Clave**: Si la pregunta menciona "MongoDB" o "migración de MongoDB", la respuesta es **DocumentDB**.

---

## Amazon Keyspaces

Base de datos compatible con **Apache Cassandra**, serverless y totalmente gestionada.

### Características

- API compatible con CQL (Cassandra Query Language).
- Serverless: escala automáticamente según la demanda.
- Tablas replicadas 3 veces en múltiples AZs.
- Modos de capacidad: **On-demand** y **Provisioned** (con auto scaling).
- Cifrado at-rest y backup continuo con PITR (35 días).

### Cuándo usar

- Migración de workloads **Apache Cassandra** a AWS.
- Aplicaciones IoT con datos de series temporales y alto volumen de escrituras.

> **Clave**: Si la pregunta menciona "Cassandra" o "migración de Cassandra", la respuesta es **Keyspaces**.

---

## Amazon QLDB

Quantum Ledger Database: base de datos de **ledger** (libro mayor) totalmente gestionada.

### Características

- **Inmutable**: Los datos no se pueden modificar ni eliminar (append-only).
- Historial completo y verificable criptográficamente de todos los cambios.
- 2-3x mejor rendimiento que frameworks de blockchain tradicionales.
- Usa un journal de transacciones con **hash chain** verificable.
- Centralizado (a diferencia de blockchain que es descentralizado).

### Cuándo usar

- Registros financieros, auditoría de transacciones.
- Historial de cambios en datos críticos (supply chain).
- Sistemas donde se necesita inmutabilidad verificable.

> **Clave**: Si la pregunta menciona "ledger", "registro inmutable", "auditoría verificable criptográficamente" y el control es **centralizado** → QLDB. Si necesita **descentralización** → Amazon Managed Blockchain.

---

## Amazon Timestream

Base de datos de **series temporales** serverless y totalmente gestionada.

### Características

- Hasta **1000x más rápido y 1/10 del coste** que bases de datos relacionales para datos de series temporales.
- Almacenamiento automático en tiers: datos recientes en memoria, datos históricos en almacenamiento magnético.
- Funciones analíticas de series temporales integradas (interpolación, smoothing, etc.).
- Cifrado at-rest y en tránsito.
- Integración con Grafana, QuickSight para visualización.

### Cuándo usar

- Datos de IoT y sensores.
- Métricas de aplicaciones y DevOps.
- Datos de click-stream y análisis en tiempo real.
- Cualquier dato con timestamp natural y patrones temporales.

> **Clave**: Si la pregunta menciona "time series", "IoT metrics", "datos temporales a gran escala", la respuesta es **Timestream**.

---

## Árbol de decisión de bases de datos

### Selección por tipo de dato y caso de uso

```
¿Qué tipo de datos?
│
├── Datos RELACIONALES (SQL, transacciones ACID)
│   ├── ¿Necesitas compatibilidad con MySQL/PostgreSQL con mejor rendimiento?
│   │   └── Amazon Aurora
│   ├── ¿Necesitas Oracle, SQL Server, MariaDB?
│   │   └── Amazon RDS
│   └── ¿Datos analíticos (OLAP, data warehouse)?
│       └── Amazon Redshift
│
├── Datos NO RELACIONALES (NoSQL)
│   ├── Key-Value / Documentos con baja latencia
│   │   └── Amazon DynamoDB
│   ├── Documentos JSON (compatible MongoDB)
│   │   └── Amazon DocumentDB
│   ├── Wide-column (compatible Cassandra)
│   │   └── Amazon Keyspaces
│   └── Grafos (relaciones complejas)
│       └── Amazon Neptune
│
├── Datos de CACHE en memoria
│   ├── ¿Necesitas persistencia, HA, estructuras complejas?
│   │   └── ElastiCache for Redis
│   └── ¿Solo cache simple multi-thread?
│       └── ElastiCache for Memcached
│
├── Datos de SERIES TEMPORALES
│   └── Amazon Timestream
│
├── LEDGER (inmutable, auditable)
│   └── Amazon QLDB
│
└── BLOCKCHAIN (descentralizado)
    └── Amazon Managed Blockchain
```

### Selección rápida por palabras clave

| Palabra clave en la pregunta | Servicio |
|---|---|
| "Relacional", "SQL", "transacciones ACID" | RDS o Aurora |
| "MySQL/PostgreSQL con alto rendimiento" | Aurora |
| "Oracle", "SQL Server" | RDS |
| "Data warehouse", "OLAP", "analytics", "BI" | Redshift |
| "NoSQL", "key-value", "baja latencia", "serverless DB" | DynamoDB |
| "MongoDB" | DocumentDB |
| "Cassandra" | Keyspaces |
| "Grafos", "relaciones entre entidades" | Neptune |
| "Cache", "sesiones", "leaderboard" | ElastiCache Redis |
| "Series temporales", "IoT", "métricas" | Timestream |
| "Ledger", "inmutable", "auditoría" | QLDB |
| "Lambda + RDS", "problemas de conexiones" | RDS Proxy |
| "Migración de DB heterogénea" | DMS + SCT |

---

## Tips para el examen

### RDS

1. **"Alta disponibilidad para RDS"** → Multi-AZ (síncrono, failover automático).
2. **"Escalar lecturas en RDS"** → Read Replicas (asíncrono).
3. **"Menor tiempo de failover RDS"** → RDS Proxy.
4. **"Lambda + RDS con problemas de conexiones"** → RDS Proxy (connection pooling).
5. **"Restaurar RDS"** → Siempre crea una NUEVA instancia.
6. **"Cifrar RDS existente no cifrado"** → Snapshot → copiar con cifrado → restaurar.
7. **"Autenticación con token / profile credentials de EC2 a RDS"** → IAM DB Authentication (no un IAM Role a secas, no SSL).

### Aurora

7. **"MySQL/PostgreSQL con alto rendimiento y HA"** → Aurora.
8. **"Rebobinar la DB a un punto anterior sin crear nueva instancia"** → Aurora Backtracking (solo MySQL).
9. **"Clonar DB para testing"** → Aurora Cloning (copy-on-write).
10. **"Lecturas globales cross-region con < 1s de lag"** → Aurora Global Database.
11. **"Capacidad variable, serverless relacional"** → Aurora Serverless v2.
12. **"Reaccionar a cambios en datos de Aurora (INSERT/UPDATE/DELETE)"** → Native function o stored procedure que invoca Lambda. No confundir con RDS Event Subscription (solo eventos de infraestructura).

### DynamoDB

12. **"Base de datos serverless NoSQL"** → DynamoDB.
13. **"Cache para DynamoDB"** → DAX (no ElastiCache para DynamoDB).
14. **"Replicación multi-región activa-activa NoSQL"** → DynamoDB Global Tables.
15. **"Reaccionar a cambios en DynamoDB"** → DynamoDB Streams + Lambda.
16. **"Patrón de acceso impredecible en DynamoDB"** → Modo On-Demand.
17. **"Expiración automática de items"** → TTL.

### ElastiCache

18. **"Cache con HA y persistencia"** → ElastiCache Redis.
19. **"Cache simple, multi-threaded"** → ElastiCache Memcached.
20. **"Sesiones de usuario stateless"** → ElastiCache Redis (o DynamoDB).
21. **"Autenticar usuarios con password antes de ejecutar comandos Redis"** → Redis AUTH (`--auth-token` + `--transit-encryption-enabled`). Ambos flags son obligatorios juntos.
22. **"Short-lived credentials para Redis"** → IAM Authentication. **"Long-lived credentials"** → Redis AUTH.

### Redshift

21. **"Data warehouse a gran escala"** → Redshift.
22. **"Query datos en S3 desde Redshift sin cargarlos"** → Redshift Spectrum.
23. **"OLAP, no OLTP"** → Redshift (OLAP) vs RDS/Aurora (OLTP).

### Bases de datos de propósito específico

24. **"Grafos"** → Neptune.
25. **"MongoDB"** → DocumentDB.
26. **"Cassandra"** → Keyspaces.
27. **"Ledger inmutable"** → QLDB.
28. **"Series temporales"** → Timestream.
29. **"Blockchain descentralizado"** → Managed Blockchain.
