# 10 - Alta Disponibilidad y Recuperación ante Desastres

## Tabla de Contenidos

- [Conceptos Fundamentales: HA vs FT vs DR](#conceptos-fundamentales-ha-vs-ft-vs-dr)
- [RPO y RTO](#rpo-y-rto)
- [Estrategias de Disaster Recovery](#estrategias-de-disaster-recovery)
- [Arquitecturas Multi-AZ](#arquitecturas-multi-az)
- [Arquitecturas Multi-Region](#arquitecturas-multi-region)
- [ELB Health Checks](#elb-health-checks)
- [Auto Scaling para Alta Disponibilidad](#auto-scaling-para-alta-disponibilidad)
- [Route 53 Health Checks y Failover](#route-53-health-checks-y-failover)
- [AWS Backup](#aws-backup)
- [AWS Elastic Disaster Recovery (DRS)](#aws-elastic-disaster-recovery-drs)
- [Chaos Engineering - AWS Fault Injection Simulator](#chaos-engineering---aws-fault-injection-simulator)
- [Tips para el Examen](#tips-para-el-examen)

---

## Conceptos Fundamentales: HA vs FT vs DR

Estos tres conceptos se confunden con frecuencia en el examen. Es fundamental entender sus diferencias.

### Definiciones

| Concepto | Definición | Objetivo | Ejemplo |
|---|---|---|---|
| **Alta Disponibilidad (HA)** | Capacidad de un sistema para permanecer operativo y accesible durante un porcentaje alto de tiempo. Acepta breves interrupciones durante el failover. | Minimizar el tiempo de inactividad | RDS Multi-AZ: si la instancia primaria falla, el failover a la standby tarda ~60-120 segundos |
| **Tolerancia a Fallos (FT)** | Capacidad de un sistema para continuar operando **sin interrupción alguna** cuando un componente falla. Zero downtime. | Cero interrupción | Un avión con múltiples motores: si uno falla, los demás mantienen el vuelo sin que los pasajeros lo noten |
| **Recuperación ante Desastres (DR)** | Conjunto de políticas, herramientas y procedimientos para recuperar la infraestructura y los datos tras un evento catastrófico. | Recuperarse tras un desastre | Restaurar la operación en otra región AWS después de que una región completa quede fuera de servicio |

### Relación entre conceptos

```
Tolerancia a Fallos (FT)
  └── Es el nivel más alto: cero interrupción
  └── Ejemplo: S3 (11 9s de durabilidad), DynamoDB Global Tables

Alta Disponibilidad (HA)
  └── Acepta breve interrupción durante failover
  └── Ejemplo: RDS Multi-AZ, ELB con ASG en múltiples AZs

Recuperación ante Desastres (DR)
  └── Recuperación después de un desastre mayor
  └── Ejemplo: Restaurar desde backup en otra región

Coste: FT > HA > DR (básico)
```

---

## RPO y RTO

Dos métricas fundamentales para diseñar estrategias de DR.

### Recovery Point Objective (RPO)

**RPO** = Cantidad máxima de datos que la organización puede permitirse perder, medida en tiempo.

```
Último backup          Punto de fallo         Recuperación
     │                      │                      │
     ▼                      ▼                      ▼
─────●──────────────────────●──────────────────────●─────
     │◄────── RPO ─────────►│                      │
     │   (datos perdidos)   │                      │
```

**Ejemplos:**
- RPO de 1 hora: Puedes perder hasta 1 hora de datos. Necesitas backups al menos cada hora.
- RPO de 0: No puedes perder ningún dato. Necesitas replicación síncrona en tiempo real.

### Recovery Time Objective (RTO)

**RTO** = Tiempo máximo aceptable para restaurar el sistema y volver a la operación normal tras un fallo.

```
Punto de fallo                         Recuperación completa
     │                                        │
     ▼                                        ▼
─────●────────────────────────────────────────●─────
     │◄──────────── RTO ─────────────────────►│
     │   (tiempo de inactividad)              │
```

**Ejemplos:**
- RTO de 4 horas: El sistema debe estar operativo en menos de 4 horas tras un fallo.
- RTO de minutos: Necesitas soluciones como Multi-AZ con failover automático.

> **Punto clave para el examen:**
> - **RPO** responde a: "Cuántos datos puedo perder"
> - **RTO** responde a: "Cuánto tiempo puedo estar caído"
> - Menor RPO/RTO = Mayor coste

---

## Estrategias de Disaster Recovery

AWS define 4 estrategias de DR, ordenadas de menor a mayor coste y de mayor a menor RTO/RPO.

### Comparativa de estrategias

| Estrategia | RPO | RTO | Coste | Descripción |
|---|---|---|---|---|
| **Backup & Restore** | Horas | 24+ horas | Bajo ($) | Crear backups periódicos y restaurar cuando sea necesario |
| **Pilot Light** | Minutos | Decenas de minutos | Medio-bajo ($$) | Mantener una versión mínima del entorno siempre encendida (core services) |
| **Warm Standby** | Segundos-Minutos | Minutos | Medio-alto ($$$) | Versión reducida pero funcional del entorno completo siempre ejecutándose |
| **Multi-Site / Hot Standby** | Casi cero | Segundos-Minutos | Alto ($$$$) | Entorno completo activo-activo en múltiples regiones |

### Detalle de cada estrategia

#### 1. Backup & Restore

```
Región Primaria (Activa)              Región DR
┌─────────────────────┐        ┌──────────────────────┐
│  EC2, RDS, EBS      │        │                      │
│  (todo operativo)   │───────►│  S3 (backups)        │
│                     │ backup │  Snapshots EBS        │
│                     │        │  RDS snapshots        │
└─────────────────────┘        └──────────────────────┘

En caso de desastre: restaurar todo desde los backups (horas)
```

- **Cómo funciona:** Backups regulares a S3, snapshots de EBS/RDS copiados a otra región.
- **Cuándo usarla:** Aplicaciones no críticas donde horas de downtime son aceptables.
- **Servicios AWS:** S3 Cross-Region Replication, EBS Snapshots, RDS Automated Backups, AWS Backup.

#### 2. Pilot Light

```
Región Primaria (Activa)              Región DR (Pilot Light)
┌─────────────────────┐        ┌──────────────────────┐
│  Web servers (ASG)  │        │  (sin web servers)   │
│  App servers (ASG)  │        │  (sin app servers)   │
│  RDS Primary        │───────►│  RDS Read Replica    │
│                     │  réplica│  (solo DB encendida) │
└─────────────────────┘        └──────────────────────┘

En caso de desastre: promover RDS replica, lanzar EC2s con ASG (minutos)
```

- **Cómo funciona:** Solo los componentes críticos (base de datos) están encendidos. El resto se aprovisiona al activar el DR.
- **Cuándo usarla:** Aplicaciones con RPO de minutos y RTO aceptable de decenas de minutos.
- **Servicios AWS:** RDS Cross-Region Read Replicas, AMIs pre-configuradas, Launch Templates listos.

#### 3. Warm Standby

```
Región Primaria (Activa)              Región DR (Warm Standby)
┌─────────────────────┐        ┌──────────────────────┐
│  Web (ASG: 4 inst.) │        │  Web (ASG: 1 inst.)  │
│  App (ASG: 4 inst.) │        │  App (ASG: 1 inst.)  │
│  RDS Multi-AZ       │───────►│  RDS Read Replica    │
│  (tamaño completo)  │ réplica│  (tamaño reducido)   │
└─────────────────────┘        └──────────────────────┘

En caso de desastre: escalar instancias, promover RDS (minutos)
```

- **Cómo funciona:** Una versión reducida pero completamente funcional del entorno siempre ejecutándose.
- **Cuándo usarla:** Aplicaciones importantes con RTO de minutos.
- **Servicios AWS:** ASG con capacidad mínima, RDS Read Replicas, Route 53 health checks con failover.

#### 4. Multi-Site / Hot Standby

```
Región Primaria (Activa)              Región Secundaria (Activa)
┌─────────────────────┐        ┌──────────────────────┐
│  Web (ASG: 4 inst.) │        │  Web (ASG: 4 inst.)  │
│  App (ASG: 4 inst.) │        │  App (ASG: 4 inst.)  │
│  Aurora Global DB   │◄──────►│  Aurora Global DB     │
│  (escritura)        │ réplica│  (lectura/escritura)  │
└─────────────────────┘        └──────────────────────┘
         │                              │
         └──────────┬───────────────────┘
                    │
            Route 53 (Active-Active)
```

- **Cómo funciona:** Entorno completo activo-activo en ambas regiones. Tráfico distribuido.
- **Cuándo usarla:** Aplicaciones críticas con RPO/RTO cercanos a cero.
- **Servicios AWS:** Route 53 latency-based routing, Aurora Global Database, DynamoDB Global Tables, CloudFront.

---

## Arquitecturas Multi-AZ

Patrones de alta disponibilidad usando múltiples Availability Zones dentro de una misma región.

### Patrones por servicio

| Servicio | Patrón Multi-AZ | Failover | Notas |
|---|---|---|---|
| **RDS** | Multi-AZ deployment: instancia standby síncrona en otra AZ | Automático (~60-120s). Cambia el DNS endpoint. | La standby NO es legible. Para lectura usa Read Replicas. |
| **Aurora** | Hasta 15 Read Replicas en múltiples AZs. Storage replicado 6 veces en 3 AZs. | Automático (~30s). Promueve una Read Replica. | Más rápido que RDS Multi-AZ estándar. |
| **ELB** | ALB/NLB despliega nodos en múltiples AZs automáticamente | N/A (distribuye tráfico entre AZs activamente) | Habilitar Cross-Zone Load Balancing para distribución uniforme. |
| **ASG** | Configurar subnets en múltiples AZs | Lanza nuevas instancias en AZs saludables | Especificar al menos 2 AZs. Mejor 3 para mayor resiliencia. |
| **S3** | Automático: datos replicados en mínimo 3 AZs | N/A (transparente) | 99.999999999% (11 9s) de durabilidad. |
| **DynamoDB** | Automático: datos replicados en 3 AZs | N/A (transparente) | Sin configuración adicional necesaria. |
| **EFS** | Automático: almacenamiento replicado en múltiples AZs | N/A (transparente) | Modo One Zone disponible para ahorro (sin HA). |
| **ElastiCache** | Multi-AZ con failover automático (Redis) | Automático para Redis con réplicas | Memcached no soporta Multi-AZ con failover automático. |
| **OpenSearch** | Despliegue en 2 o 3 AZs con réplicas | Automático | Requiere mínimo 2 nodos por AZ para producción. |

### Patrón de arquitectura Multi-AZ típico

```
                    Route 53
                       │
                ┌──────▼──────┐
                │     ALB     │ (Multi-AZ automático)
                └──────┬──────┘
                       │
          ┌────────────┼────────────┐
          │            │            │
    ┌─────▼─────┐┌────▼─────┐┌────▼─────┐
    │  EC2 (AZ-a)││ EC2 (AZ-b)││ EC2 (AZ-c)│
    │  (ASG)    ││  (ASG)   ││  (ASG)   │
    └─────┬─────┘└────┬─────┘└────┬─────┘
          │            │            │
          └────────────┼────────────┘
                       │
                ┌──────▼──────┐
                │ RDS Multi-AZ │
                │ Primary (AZ-a)│
                │ Standby (AZ-b)│
                └─────────────┘
```

---

## Arquitecturas Multi-Region

Para protección contra fallos a nivel de región completa.

### Patrones Multi-Region por servicio

#### Route 53 Failover Routing

```
                   Route 53 (Failover Policy)
                       │
          ┌────────────┼────────────┐
          │                         │
    Primario (us-east-1)     Secundario (eu-west-1)
    Health check: HEALTHY     Health check: monitoreando
          │                         │
    ┌─────▼─────┐           ┌──────▼──────┐
    │   ALB     │           │    ALB      │
    │   ASG     │           │    ASG      │
    │   RDS     │           │    RDS      │
    └───────────┘           └─────────────┘

Si el primario falla → Route 53 redirige al secundario automáticamente
```

#### Aurora Global Database

- **Replicación:** Un cluster primario (lectura/escritura) y hasta 5 clusters secundarios (solo lectura) en otras regiones.
- **Latencia de replicación:** Menor a 1 segundo entre regiones.
- **Failover:** Promover un cluster secundario a primario en menos de 1 minuto.
- **RPO:** Típicamente < 1 segundo.
- **RTO:** Típicamente < 1 minuto.

#### DynamoDB Global Tables

- **Replicación:** Activa-Activa. Tablas replicadas en múltiples regiones.
- **Lectura/Escritura:** Se puede leer y escribir en cualquier región.
- **Resolución de conflictos:** Last writer wins (basado en timestamp).
- **Latencia de replicación:** Típicamente < 1 segundo.
- **Requisito:** DynamoDB Streams debe estar habilitado.

#### S3 Cross-Region Replication (CRR)

- **Configuración:** Regla de replicación entre bucket origen y bucket destino en otra región.
- **Requisitos:** Versionado habilitado en ambos buckets.
- **Comportamiento:** Solo replica objetos nuevos y modificados (no retroactivo; usar S3 Batch Replication para objetos existentes).
- **Opciones:** Puede cambiar la clase de almacenamiento en el destino y/o cambiar el propietario.

---

## ELB Health Checks

Los health checks del ELB determinan si las instancias detrás del balanceador están saludables para recibir tráfico.

### Tipos de Health Checks

| Tipo | Protocolo | Descripción | Ejemplo |
|---|---|---|---|
| **HTTP/HTTPS** | HTTP(S) GET | Verifica que una ruta específica devuelva código 200 | `GET /health` devuelve 200 OK |
| **TCP** | TCP | Verifica que el puerto esté aceptando conexiones | Conexión TCP al puerto 443 exitosa |
| **SSL** | TLS | Verifica conexión TLS | Handshake TLS exitoso |

### Parámetros de Health Check

| Parámetro | Descripción | Valor típico |
|---|---|---|
| **Interval** | Frecuencia del health check | 30 segundos |
| **Timeout** | Tiempo máximo de espera de respuesta | 5 segundos |
| **Unhealthy Threshold** | Checks fallidos consecutivos para marcar como unhealthy | 2 |
| **Healthy Threshold** | Checks exitosos consecutivos para marcar como healthy | 5 (CLB), 3 (ALB/NLB) |
| **Path** | Ruta HTTP para la verificación | /health o /status |

### Comportamiento

- Si una instancia falla el health check, el ELB **deja de enviarle tráfico**.
- La instancia NO se termina automáticamente (eso lo hace el ASG si está configurado con ELB health checks).
- **Importante:** El ASG puede usar EC2 status checks o ELB health checks. Para HA, configurar el ASG para que use **ELB health checks**, ya que son más granulares.

---

## Auto Scaling para Alta Disponibilidad

### Configuración de ASG para HA

| Configuración | Valor recomendado | Justificación |
|---|---|---|
| **AZs** | Mínimo 2, idealmente 3 | Resiliencia ante fallo de una AZ |
| **Min capacity** | >= número de AZs | Al menos 1 instancia por AZ |
| **Desired capacity** | Según la carga actual | Mantener rendimiento adecuado |
| **Max capacity** | 2x desired o más | Capacidad para manejar picos |
| **Health check type** | ELB | Más preciso que EC2 status checks |
| **Health check grace period** | Tiempo de arranque de la app | Evitar terminar instancias que están iniciando |

### Políticas de escalado

| Política | Descripción | Caso de uso para HA |
|---|---|---|
| **Target Tracking** | Mantener una métrica en un valor objetivo | Mantener CPU al 50% para tener margen |
| **Step Scaling** | Escalar según umbrales de alarmas CloudWatch | Escalado agresivo ante cambios bruscos |
| **Scheduled Scaling** | Escalar según horario predefinido | Pre-escalar antes de picos conocidos |
| **Predictive Scaling** | ML para predecir la demanda futura | Anticiparse a patrones de tráfico |

### Patrón de ASG para máxima HA

```
ASG Configuration:
  Min: 3 (una por AZ)
  Desired: 6
  Max: 12

  AZ-a: 2 instancias
  AZ-b: 2 instancias
  AZ-c: 2 instancias

Si AZ-a falla:
  ASG redistribuye automáticamente:
  AZ-b: 3 instancias
  AZ-c: 3 instancias
```

---

## Route 53 Health Checks y Failover

### Tipos de Health Checks

| Tipo | Descripción | Caso de uso |
|---|---|---|
| **Endpoint** | Monitorea un endpoint específico (IP, dominio, URL) | Verificar que un servidor o load balancer responda |
| **Calculated** | Combina resultados de múltiples health checks con lógica AND/OR | Verificar que al menos 2 de 3 componentes estén saludables |
| **CloudWatch Alarm** | Se basa en el estado de una alarma de CloudWatch | Health check basado en métricas personalizadas |

### Health Check de Endpoint

- Route 53 envía requests desde **múltiples ubicaciones globales** (health checkers).
- Si más del **18%** de los health checkers reportan el endpoint como saludable, Route 53 lo considera saludable.
- Soporta HTTP, HTTPS y TCP.
- Para HTTP/HTTPS, puede verificar que el body de la respuesta contenga un string específico (búsqueda en los primeros 5120 bytes).

### Failover Routing Policy

```
Cliente ──► Route 53
              │
              ├── Registro primario (us-east-1) ← Health Check
              │     └── Si HEALTHY → responde con IP primaria
              │
              └── Registro secundario (eu-west-1) ← Health Check (opcional)
                    └── Si primario UNHEALTHY → responde con IP secundaria
```

### Tipos de failover con Route 53

| Política de enrutamiento | Modelo | Descripción |
|---|---|---|
| **Failover** | Active-Passive | Un primario y un secundario. Tráfico al secundario solo si el primario falla. |
| **Weighted** | Active-Active (con pesos) | Distribuir tráfico entre regiones con pesos (p.ej., 70/30). |
| **Latency-based** | Active-Active (por latencia) | Dirige al usuario a la región con menor latencia. |
| **Geolocation** | Active-Active (por ubicación) | Dirige según la ubicación geográfica del usuario. |

> **Punto clave para el examen:** Para DR Active-Passive usa **Failover routing**. Para Active-Active usa **Weighted**, **Latency** o **Geolocation**.

---

## AWS Backup

Servicio centralizado para gestionar y automatizar backups de múltiples servicios de AWS.

### Servicios soportados

EC2, EBS, RDS, Aurora, DynamoDB, EFS, FSx, Storage Gateway, S3, Neptune, DocumentDB, SAP HANA en EC2, VMware (on-premises).

### Componentes principales

| Componente | Descripción |
|---|---|
| **Backup Plan** | Define la política: frecuencia, ventana de backup, retención, transición a cold storage |
| **Backup Vault** | Contenedor de almacenamiento para los backups. Se puede cifrar con KMS. |
| **Backup Vault Lock** | Protección WORM (Write Once Read Many) para evitar eliminación o modificación de backups |
| **Recovery Point** | Un backup individual dentro de un vault |
| **Resource Assignment** | Qué recursos están incluidos en el backup plan (por tags o ARNs) |

### Cross-Region y Cross-Account Backup

```
Cuenta A (Producción)                Cuenta B (Backup)
Región us-east-1                     Región eu-west-1
┌──────────────────┐                ┌──────────────────┐
│  Backup Plan     │                │                  │
│  ┌────────────┐  │   Cross-Region │  Backup Vault    │
│  │ RDS backup │──│───────────────►│  (copia)         │
│  │ EBS backup │──│── Cross-Account│                  │
│  │ DynamoDB   │  │───────────────►│  Vault Lock      │
│  └────────────┘  │                │  (WORM)          │
└──────────────────┘                └──────────────────┘
```

- **Cross-Region:** Copiar backups automáticamente a otra región para DR.
- **Cross-Account:** Copiar backups a una cuenta separada para protección contra compromiso de cuenta.
- **Vault Lock:** Política WORM que impide que nadie (ni root) elimine los backups durante el período de retención.

> **Punto clave para el examen:** Para proteger backups contra eliminación accidental o maliciosa, usa **Backup Vault Lock**. Para cumplimiento normativo, es la respuesta sobre inmutabilidad de backups.

---

## AWS Elastic Disaster Recovery (DRS)

Servicio que facilita la recuperación ante desastres, anteriormente conocido como CloudEndure Disaster Recovery.

### Cómo funciona

```
Entorno origen                          AWS (Región DR)
(on-prem o cloud)
┌──────────────────┐   replicación    ┌──────────────────┐
│  Servidores con  │   continua       │  Staging Area    │
│  agente DRS      │──────────────►   │  (instancias     │
│                  │  (nivel bloque)  │   de bajo coste) │
└──────────────────┘                  └────────┬─────────┘
                                               │
                                    Drill/Recovery (lanzamiento)
                                               │
                                     ┌─────────▼─────────┐
                                     │  Recovery Instances│
                                     │  (tipo y tamaño   │
                                     │   configurado)     │
                                     └───────────────────┘
```

### Características principales

- **Replicación continua:** Replica datos a nivel de bloque del servidor origen a un staging area en AWS.
- **RPO:** Típicamente segundos (replicación continua).
- **RTO:** Típicamente minutos (lanzar instancias desde la réplica).
- **Drill (simulacro):** Permite realizar simulacros de DR sin afectar la replicación ni el entorno de producción.
- **Failback:** Una vez resuelto el desastre, permite volver al entorno original.
- **Coste:** Solo se paga por el staging area (instancias ligeras + almacenamiento) hasta que se activa la recuperación.

### DRS vs MGN

| Característica | DRS (Disaster Recovery) | MGN (Migration) |
|---|---|---|
| **Propósito** | Recuperación ante desastres | Migración a AWS |
| **Replicación** | Continua (siempre activa) | Temporal (hasta completar la migración) |
| **Uso post-migración** | Permanece activo como solución DR | Se desactiva tras la migración |
| **Failback** | Sí, soportado | No aplica |

---

## Chaos Engineering - AWS Fault Injection Simulator

### Concepto de Chaos Engineering

Disciplina de experimentación donde se **inyectan fallos intencionalmente** en sistemas de producción o pre-producción para descubrir debilidades antes de que ocurran fallos reales.

### AWS Fault Injection Simulator (FIS)

Servicio completamente gestionado para ejecutar experimentos de chaos engineering en AWS.

### Acciones soportadas

| Servicio | Acciones posibles |
|---|---|
| **EC2** | Detener/terminar instancias, inyectar CPU stress, inyectar memory stress, perder paquetes de red |
| **ECS** | Detener tareas, drenar container instances |
| **EKS** | Terminar pods, inyectar fallos en nodos |
| **RDS** | Forzar failover de instancias Multi-AZ, rebotar instancias |
| **Network** | Disrupciones de red (latencia, pérdida de paquetes) entre AZs o subnets |
| **Systems Manager** | Ejecutar documentos SSM para simular fallos a nivel de SO |

### Componentes de un experimento FIS

| Componente | Descripción |
|---|---|
| **Experiment Template** | Define las acciones, targets, stop conditions y rol IAM |
| **Actions** | Qué fallos inyectar (e.g., stop EC2 instances) |
| **Targets** | Qué recursos se ven afectados (por tags, ARNs, filtros, % de recursos) |
| **Stop Conditions** | CloudWatch Alarms que detienen el experimento si se supera un umbral de seguridad |
| **IAM Role** | Rol con permisos para ejecutar las acciones sobre los targets |

### Ejemplo de experimento

```
Experiment Template:
  Action: aws:ec2:stop-instances
  Target: Instancias EC2 con tag "Environment=Production" (30%)
  Stop Condition: Alarma "ErrorRate > 10%"
  Duration: 10 minutos

Objetivo: Verificar que el ASG detecta instancias detenidas,
          las reemplaza y el servicio sigue disponible a través del ALB.
```

> **Punto clave para el examen:** FIS se usa para **probar la resiliencia** de la arquitectura. Las preguntas suelen preguntar cómo verificar que una arquitectura HA realmente funciona ante fallos.

---

## Tips para el Examen

### Preguntas frecuentes y respuestas rápidas

| Escenario del examen | Respuesta |
|---|---|
| RPO de 0, RTO de minutos | **Multi-Site / Hot Standby** con Aurora Global Database |
| RPO de horas, bajo presupuesto | **Backup & Restore** |
| Mantener solo la DB encendida en la región DR | **Pilot Light** |
| Versión reducida del entorno completo en DR | **Warm Standby** |
| Proteger backups contra eliminación | **AWS Backup Vault Lock** |
| Verificar que la arquitectura HA funciona | **AWS Fault Injection Simulator** |
| DR con RPO de segundos y RTO de minutos | **AWS Elastic Disaster Recovery (DRS)** |
| Replicar DynamoDB entre regiones | **DynamoDB Global Tables** |
| Replicar S3 entre regiones | **S3 Cross-Region Replication (CRR)** |
| Failover automático DNS | **Route 53 Failover routing** con health checks |
| Base de datos con failover < 1 min entre regiones | **Aurora Global Database** |
| Backup centralizado de múltiples servicios | **AWS Backup** |
| ASG que detecte errores de aplicación (no solo EC2) | Configurar **ELB health checks** en el ASG |
| Asegurar mínimo de instancias en cada AZ | ASG con **múltiples AZs** y min capacity adecuada |

### Tabla resumen: RPO / RTO / Coste

| Estrategia | RPO | RTO | Coste relativo |
|---|---|---|---|
| Backup & Restore | Horas | 24+ horas | $ |
| Pilot Light | Minutos | 10-30 minutos | $$ |
| Warm Standby | Segundos-Minutos | Minutos | $$$ |
| Multi-Site | ~0 | Segundos-Minutos | $$$$ |

### Errores comunes a evitar

1. **Confundir Pilot Light con Warm Standby:** Pilot Light solo tiene la base de datos encendida. Warm Standby tiene todo el stack pero en tamaño reducido.
2. **Olvidar que RDS Multi-AZ standby no es legible:** La instancia standby solo es para failover, no para consultas de lectura. Para lectura usa Read Replicas.
3. **No considerar el coste de Multi-Site:** Si la pregunta menciona presupuesto limitado, Multi-Site probablemente no es la respuesta.
4. **Confundir HA con DR:** Multi-AZ es HA (misma región). Multi-Region es DR (protección ante fallo de región).
5. **Confundir DRS con MGN:** DRS es para DR continuo, MGN es para migración puntual.
6. **No habilitar DynamoDB Streams para Global Tables:** Es un requisito previo que puede aparecer en el examen.
7. **Asumir que S3 CRR replica objetos existentes:** Solo replica objetos nuevos. Para existentes, usar S3 Batch Replication.
