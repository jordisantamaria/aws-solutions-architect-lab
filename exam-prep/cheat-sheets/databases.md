# Databases - Cheat Sheet Rápido

## RDS vs Aurora vs DynamoDB

| Característica | RDS | Aurora | DynamoDB |
|---------------|-----|--------|----------|
| **Tipo** | Relacional (SQL) | Relacional (SQL) | NoSQL (Key-Value / Document) |
| **Engines** | MySQL, PostgreSQL, MariaDB, Oracle, SQL Server | MySQL, PostgreSQL | Propietario AWS |
| **Almacenamiento máx** | 64 TB | 128 TB (auto-scaling) | Ilimitado |
| **Read Replicas** | Hasta 15 (5 por defecto) | Hasta 15 (auto-scaling) | Global Tables (multi-region) |
| **Multi-AZ** | Standby (failover) | Multi-AZ nativo (6 copias en 3 AZs) | Multi-AZ nativo (3 AZs) |
| **Failover** | 1-2 minutos | **< 30 segundos** | Automático (transparente) |
| **Auto-scaling storage** | Manual (hasta 64TB) | **Automático** (10GB incrementos) | Automático (on-demand mode) |
| **Serverless** | No | **Sí (Aurora Serverless v2)** | **Sí (on-demand mode)** |
| **Backups** | Automáticos (35 días máx) | Automáticos (35 días) + backtrack | Backups continuos (PITR 35 días) |
| **Precio** | Menor | ~20% más que RDS | Por lectura/escritura + almacenamiento |
| **Caso ideal** | Apps relacionales, motores específicos | Alta disponibilidad, auto-scaling relacional | Masiva escala, baja latencia, key-value |

---

## Engines Disponibles en RDS

| Engine | Versiones notables | Notas para el examen |
|--------|--------------------|---------------------|
| **MySQL** | 5.7, 8.0 | Compatible con Aurora MySQL |
| **PostgreSQL** | 13, 14, 15, 16 | Compatible con Aurora PostgreSQL |
| **MariaDB** | 10.x | Fork de MySQL, no compatible con Aurora |
| **Oracle** | SE2, EE | Requiere licencia (BYOL o License Included) |
| **SQL Server** | SE, EE, Express, Web | Requiere licencia. Multi-AZ usa mirroring/Always On |
| **Db2** | 11.5 | IBM Db2 gestionado en RDS |

> **Clave examen:** Si piden **Oracle o SQL Server** en AWS gestionado → solo **RDS** (no Aurora). Si piden MySQL/PostgreSQL con mejor rendimiento → **Aurora**.

---

## Aurora - Features Rápido

| Feature | Descripción |
|---------|-------------|
| **6 copias en 3 AZs** | Datos replicados automáticamente. Tolera pérdida de 2 copias para escrituras, 3 para lecturas |
| **Storage auto-scaling** | Crece automáticamente de 10 GB hasta 128 TB en incrementos de 10 GB |
| **Hasta 15 Read Replicas** | Con Auto Scaling. Failover automático al replica con mayor prioridad |
| **Aurora Serverless v2** | Escala automáticamente la capacidad compute (ACUs). Pago por uso real |
| **Aurora Global Database** | Replicación cross-region en < 1 segundo. RPO de 1s, RTO < 1 min |
| **Backtrack** | Rebobinar la base de datos a un punto en el tiempo **sin restaurar desde backup** (solo MySQL) |
| **Multi-Master** | Múltiples nodos de escritura (caso de uso: escrituras continuas sin failover) |
| **Cloning** | Crear copia de la BD usando copy-on-write — rápido y sin costo de almacenamiento inicial |
| **Custom Endpoints** | Dirigir tráfico a subgrupos de replicas (ej: analytics a replicas más grandes) |
| **Parallel Query** | Distribuye query processing al storage layer para queries analíticas grandes |

> **Truco examen:** "Base de datos relacional con **auto-scaling**, **alta disponibilidad** y **serverless**" → **Aurora Serverless v2**.

---

## DynamoDB - Capacity Modes y Límites

### Modos de Capacidad

| Modo | Descripción | Cuándo usarlo |
|------|-------------|---------------|
| **On-Demand** | Pago por lectura/escritura real. Sin planificación | Cargas impredecibles, nuevas apps, tráfico variable |
| **Provisioned** | Defines RCU/WCU. Más económico para cargas estables | Tráfico predecible, optimización de costos |

### Unidades de Capacidad

| Unidad | Definición |
|--------|-----------|
| **1 RCU** | 1 lectura strongly consistent de hasta 4 KB/s **O** 2 lecturas eventually consistent de hasta 4 KB/s |
| **1 WCU** | 1 escritura de hasta 1 KB/s |

### Límites Importantes

| Parámetro | Límite |
|-----------|--------|
| **Tamaño máximo de item** | 400 KB |
| **Partition key** | Hasta 2,048 bytes |
| **Sort key** | Hasta 1,024 bytes |
| **GSI por tabla** | 20 (default) |
| **LSI por tabla** | 5 (deben crearse al crear la tabla) |
| **Tamaño resultado de Query/Scan** | 1 MB por llamada (paginar si hay más) |
| **Transacciones** | Hasta 100 items o 4 MB por transacción |

> **Claves examen:**
> - **DAX** (DynamoDB Accelerator): Cache in-memory para DynamoDB. Latencia de microsegundos. Para lecturas intensivas.
> - **Global Tables**: Replicación multi-region activa-activa. Requiere DynamoDB Streams habilitado.
> - **DynamoDB Streams**: Captura cambios (CDC). Se integra con Lambda para triggers.

---

## ElastiCache: Redis vs Memcached

| Característica | Redis | Memcached |
|---------------|-------|-----------|
| **Persistencia** | **Sí** (snapshots, AOF) | No |
| **Replicación** | **Sí** (Multi-AZ con failover) | No |
| **Clustering** | Sí (hasta 500 nodos) | Sí (sharding simple) |
| **Tipos de datos** | Strings, hashes, lists, sets, sorted sets, streams | Strings simples |
| **Pub/Sub** | **Sí** | No |
| **Lua scripting** | **Sí** | No |
| **Multi-threaded** | No (single-threaded) | **Sí** |
| **Backup/Restore** | **Sí** | No |
| **Caso de uso** | Sesiones, leaderboards, colas, HA cache, real-time analytics | Cache simple, objetos grandes, escalado horizontal puro |

> **Regla examen:**
> - Si necesitas **persistencia, replicación o tipos de datos complejos** → **Redis**
> - Si solo necesitas un **cache simple y multi-threaded** → **Memcached**
> - **Casi siempre la respuesta es Redis** en el examen (a menos que explícitamente pidan multi-threading simple).

---

## Cuándo Usar Cada Base de Datos

| Servicio | Cuándo usarlo (1 línea) |
|----------|------------------------|
| **RDS** | Necesitas base de datos relacional gestionada con engine específico (Oracle, SQL Server, etc.) |
| **Aurora** | Relacional con auto-scaling, alta disponibilidad y rendimiento superior a RDS estándar |
| **DynamoDB** | NoSQL key-value con latencia de milisegundos a cualquier escala, schema flexible |
| **ElastiCache** | Cache in-memory para reducir latencia de lecturas frecuentes en base de datos |
| **Redshift** | Data warehouse para analytics y consultas OLAP sobre petabytes de datos |
| **Neptune** | Base de datos de grafos para relaciones complejas (redes sociales, fraud detection) |
| **DocumentDB** | Base de datos documental compatible con MongoDB gestionado en AWS |
| **QLDB** | Ledger inmutable con historial verificable criptográficamente (finanzas, supply chain) |
| **Timestream** | Series temporales para IoT, métricas de aplicación, datos de sensores |
| **Keyspaces** | Compatible con Apache Cassandra gestionado — cargas wide-column existentes |
| **MemoryDB** | Redis-compatible con durabilidad (multi-AZ) — reemplaza Redis + base de datos |

---

## Read Replicas vs Multi-AZ

| Característica | Read Replicas | Multi-AZ |
|---------------|---------------|----------|
| **Propósito** | **Rendimiento** (escalar lecturas) | **Disponibilidad** (failover automático) |
| **Tipo de replicación** | **Asíncrona** | **Síncrona** |
| **Acceso de lectura** | **Sí** — se pueden usar para lecturas | **No** — standby no acepta tráfico |
| **Regiones** | Misma región o **cross-region** | Misma región (otra AZ) |
| **Failover automático** | No (se puede promover manualmente) | **Sí** (DNS automático) |
| **Número máximo** | Hasta 15 (Aurora) / 5 (RDS) | 1 standby por instancia |
| **Costo de red** | Gratis en misma región. Costo cross-region | Gratis (misma región) |
| **Caso de uso** | Reportes, analytics, distribuir carga de lectura | Producción HA, disaster recovery intra-region |

```
                    ┌─────────────┐
    Escrituras ────→│   PRIMARY   │
                    │  (Master)   │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │ Síncrona   │            │ Asíncrona
              ▼            │            ▼
     ┌────────────┐        │    ┌──────────────┐
     │  STANDBY   │        │    │ READ REPLICA │ ← Lecturas
     │ (Multi-AZ) │        │    │  (scaling)   │
     │ NO tráfico │        │    └──────────────┘
     └────────────┘        │
                           │ Asíncrona
                           ▼
                   ┌──────────────┐
                   │ READ REPLICA │ ← Lecturas
                   │ (cross-region)│
                   └──────────────┘
```

> **Clave examen:** "Mejorar rendimiento de lectura" → **Read Replicas**. "Alta disponibilidad / disaster recovery" → **Multi-AZ**. Puedes tener **ambos** a la vez.

---

## Resumen de Decisiones Rápidas - Databases

```
PREGUNTA DEL EXAMEN                                    → RESPUESTA
────────────────────────────────────────────────────────────────────
"BD relacional, alta disponibilidad, auto-scaling"      → Aurora
"BD relacional, Oracle o SQL Server"                    → RDS
"NoSQL, key-value, latencia ms, escala masiva"          → DynamoDB
"Cache in-memory para reducir latencia"                 → ElastiCache Redis
"Data warehouse, OLAP, analytics sobre PBs"             → Redshift
"Relaciones complejas, grafos"                          → Neptune
"Compatible MongoDB gestionado"                         → DocumentDB
"Registro inmutable, auditoría criptográfica"           → QLDB
"Series temporales, IoT, métricas"                      → Timestream
"Replicación multi-region relacional"                   → Aurora Global Database
"Cache DynamoDB con microsegundos de latencia"          → DAX
```
