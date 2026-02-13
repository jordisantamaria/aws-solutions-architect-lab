# 09 - Migración a AWS

## Tabla de Contenidos

- [AWS Cloud Adoption Framework (CAF)](#aws-cloud-adoption-framework-caf)
- [Estrategias de Migración: Las 7 Rs](#estrategias-de-migración-las-7-rs)
- [AWS Migration Hub](#aws-migration-hub)
- [AWS Application Discovery Service](#aws-application-discovery-service)
- [AWS Application Migration Service (MGN)](#aws-application-migration-service-mgn)
- [AWS Database Migration Service (DMS)](#aws-database-migration-service-dms)
- [AWS Snow Family](#aws-snow-family)
- [AWS Transfer Family](#aws-transfer-family)
- [AWS DataSync](#aws-datasync)
- [VMware Cloud on AWS](#vmware-cloud-on-aws)
- [Tips para el Examen](#tips-para-el-examen)

---

## AWS Cloud Adoption Framework (CAF)

El AWS Cloud Adoption Framework proporciona una guía estructurada para planificar la migración a la nube. Se organiza en **6 perspectivas** agrupadas en dos categorías.

### Perspectivas de Negocio (Business Capabilities)

| Perspectiva | Enfoque | Stakeholders Clave |
|---|---|---|
| **Business** | Alinear las inversiones en la nube con los objetivos de negocio. Garantizar que la nube genera valor medible. | CEO, CFO, COO, CIO |
| **People** | Gestión del cambio organizacional, formación, roles y estructura del equipo para la adopción de la nube. | RRHH, CIO, directores de formación |
| **Governance** | Control de riesgos, cumplimiento normativo, gestión de presupuesto y portfolio de proyectos en la nube. | CIO, CTO, CFO, CDO |

### Perspectivas Técnicas (Technical Capabilities)

| Perspectiva | Enfoque | Stakeholders Clave |
|---|---|---|
| **Platform** | Diseño de la arquitectura cloud, selección de servicios, definición de patrones y estándares de infraestructura. | CTO, arquitectos, ingenieros |
| **Security** | Gestión de identidades, protección de datos, detección de amenazas y respuesta ante incidentes en la nube. | CISO, equipo de seguridad |
| **Operations** | Definición de cómo se operarán los servicios en la nube: monitoreo, gestión de incidentes, automatización. | IT Operations, Site Reliability Engineers |

> **Punto clave para el examen:** Cuando una pregunta mencione "planificar la migración" o "evaluar la preparación organizacional para la nube", piensa en CAF. Las perspectivas de Business y People son las más relevantes para gestionar el cambio organizacional.

---

## Estrategias de Migración: Las 7 Rs

Las 7 Rs representan las estrategias disponibles para migrar cada aplicación o carga de trabajo a la nube.

```
Menor esfuerzo ◄──────────────────────────────────────► Mayor esfuerzo
  Retire → Retain → Relocate → Rehost → Replatform → Repurchase → Refactor
```

### Detalle de cada estrategia

| Estrategia | Descripción | Ejemplo | Esfuerzo | Beneficio Cloud |
|---|---|---|---|---|
| **Retire** | Eliminar aplicaciones que ya no son necesarias. | Sistema legacy que nadie usa | Mínimo | N/A (ahorro por eliminación) |
| **Retain** | Mantener en on-premises (no migrar ahora). Revisitar más adelante. | App con dependencias complejas, compliance estricto | Ninguno | Ninguno (por ahora) |
| **Relocate** | Mover a AWS sin cambios, usando VMware Cloud on AWS o similar. | Mover hipervisor VMware completo a AWS | Bajo | Bajo-Medio |
| **Rehost** | "Lift and shift". Mover tal cual a la nube (EC2). Sin cambios en código. | Mover un servidor web a EC2 usando MGN | Bajo | Bajo |
| **Replatform** | "Lift, tinker and shift". Pequeñas optimizaciones sin cambiar la arquitectura core. | Migrar MySQL on-prem a RDS MySQL, Elastic Beanstalk | Medio | Medio |
| **Repurchase** | Cambiar a un producto SaaS diferente. "Drop and shop". | Mover CRM propio a Salesforce, correo a Office 365 | Medio | Medio-Alto |
| **Refactor** | Re-arquitecturar la aplicación para aprovechar servicios cloud-nativos. | Descomponer monolito en microservicios con Lambda, ECS, DynamoDB | Alto | Alto |

### Cuándo usar cada estrategia

```
¿Se necesita la aplicación? ──NO──► Retire
         │
        SÍ
         │
¿Se puede migrar ahora? ──NO──► Retain
         │
        SÍ
         │
¿Es un entorno VMware completo? ──SÍ──► Relocate
         │
        NO
         │
¿Se necesitan cambios mínimos? ──SÍ──► Rehost (MGN)
         │
        NO
         │
¿Se puede optimizar ligeramente? ──SÍ──► Replatform (RDS, Beanstalk)
         │
        NO
         │
¿Existe un SaaS equivalente? ──SÍ──► Repurchase
         │
        NO
         │
        Refactor (cloud-native)
```

---

## AWS Migration Hub

**AWS Migration Hub** es un servicio centralizado que proporciona un **único panel de control** para rastrear el progreso de las migraciones a través de múltiples herramientas de AWS y partners.

### Características principales

- **Vista unificada:** Muestra el estado de todas las migraciones en un solo lugar.
- **Integración:** Se conecta con AWS MGN, AWS DMS, y herramientas de partners (CloudEndure, etc.).
- **Tracking por aplicación:** Permite agrupar servidores y bases de datos por aplicación para rastrear la migración completa de cada app.
- **Sin coste adicional:** Solo se paga por los servicios de migración subyacentes.

### Flujo de trabajo

```
Application Discovery Service    AWS MGN
         │                          │
         └──────────┬───────────────┘
                    │
            Migration Hub (panel central)
                    │
         ┌──────────┴───────────────┐
         │                          │
    AWS DMS              Herramientas de partners
```

---

## AWS Application Discovery Service

Servicio que ayuda a **descubrir y recopilar información** sobre los servidores y aplicaciones on-premises para planificar la migración.

### Modos de descubrimiento

| Característica | Agentless Discovery (Connector) | Agent-Based Discovery |
|---|---|---|
| **Implementación** | Appliance virtual (OVA) en VMware vCenter | Agente instalado en cada servidor (Windows/Linux) |
| **Datos recopilados** | CPU, memoria, disco, información de VM, configuración de red | Todo lo anterior + procesos en ejecución, conexiones de red, rendimiento detallado |
| **Nivel de detalle** | Básico (hardware y configuración) | Detallado (dependencias entre aplicaciones, patrones de tráfico) |
| **Caso de uso** | Inventario inicial rápido de VMs | Análisis profundo de dependencias para planificar agrupaciones de migración |
| **Requisitos** | Solo VMware vCenter | Acceso root/admin en cada servidor |
| **Dependencias** | No mapea dependencias | Sí, mapea dependencias entre servidores |

### Integración con Athena y S3

- Los datos descubiertos se pueden exportar a **S3** y analizar con **Amazon Athena** para crear consultas SQL sobre el inventario de servidores.
- Se puede visualizar con **Amazon QuickSight** para generar dashboards del entorno on-premises.

> **Punto clave para el examen:** Si la pregunta pide "mapear dependencias entre aplicaciones" o "entender qué servidores se comunican entre sí", la respuesta es **Agent-Based Discovery**.

---

## AWS Application Migration Service (MGN)

AWS MGN (anteriormente CloudEndure Migration) es el servicio recomendado para la estrategia **Rehost (Lift and Shift)**.

### Cómo funciona

```
On-Premises                         AWS
┌──────────────┐    replicación    ┌──────────────────────┐
│  Servidor    │    continua       │  Staging Area        │
│  origen con  │ ──────────────►   │  (instancias de bajo │
│  agente MGN  │    (bloque por    │   coste para réplica)│
│              │     bloque)       │                      │
└──────────────┘                   └──────────┬───────────┘
                                              │
                                    Cutover (lanzamiento)
                                              │
                                   ┌──────────▼───────────┐
                                   │  Target Instances     │
                                   │  (instancias finales  │
                                   │   con tipo correcto)  │
                                   └──────────────────────┘
```

### Características principales

- **Replicación continua:** Replica datos a nivel de bloque sin afectar al servidor de origen.
- **Staging Area:** Usa instancias ligeras y almacenamiento EBS barato para mantener la réplica.
- **Testing:** Permite lanzar instancias de test para validar antes del cutover.
- **Cutover mínimo:** Al hacer el cutover, simplemente lanza las instancias finales con los últimos datos replicados.
- **Plataformas soportadas:** Servidores físicos, VMware, Hyper-V, Azure, GCP y otras nubes.
- **SO soportados:** Windows y Linux.

> **Punto clave para el examen:** MGN = Rehost = Lift and Shift. Es la respuesta cuando se pregunta por migrar servidores a AWS con mínimo tiempo de inactividad y sin cambios en la aplicación.

---

## AWS Database Migration Service (DMS)

DMS permite migrar bases de datos a AWS de forma segura con **mínimo tiempo de inactividad**. La base de datos de origen permanece operativa durante la migración.

### Migraciones homogéneas vs heterogéneas

| Tipo | Descripción | Herramientas | Ejemplo |
|---|---|---|---|
| **Homogénea** | Mismo motor de base de datos origen y destino | Solo DMS | Oracle → RDS Oracle, MySQL → Aurora MySQL |
| **Heterogénea** | Diferente motor de base de datos origen y destino | SCT + DMS | Oracle → Aurora PostgreSQL, SQL Server → RDS MySQL |

### AWS Schema Conversion Tool (SCT)

SCT se usa **solo en migraciones heterogéneas** para convertir el esquema de la base de datos origen al formato del motor destino.

```
Migración Homogénea:
  Oracle on-prem ──── DMS ────► RDS Oracle

Migración Heterogénea:
  Oracle on-prem ──── SCT (convierte esquema) ──── DMS (migra datos) ────► Aurora PostgreSQL
```

### Componentes de DMS

- **Replication Instance:** Instancia EC2 que ejecuta el software de replicación.
- **Source Endpoint:** Conexión a la base de datos origen.
- **Target Endpoint:** Conexión a la base de datos destino.
- **Replication Task:** Define la tarea de migración (full load, CDC o ambas).

### Tipos de migración

| Tipo | Descripción | Caso de uso |
|---|---|---|
| **Full Load** | Migra todos los datos existentes de una vez | Migraciones con ventana de mantenimiento |
| **CDC (Change Data Capture)** | Solo replica los cambios incrementales | Replicación continua |
| **Full Load + CDC** | Migra datos existentes y luego captura cambios | Migración con mínimo downtime (lo más común) |

### Fuentes y destinos soportados

- **Fuentes:** Oracle, SQL Server, MySQL, MariaDB, PostgreSQL, MongoDB, SAP ASE, S3, IBM Db2
- **Destinos:** RDS (todos los motores), Aurora, Redshift, DynamoDB, S3, Elasticsearch, Kinesis Data Streams, DocumentDB, Neptune, Redis

> **Punto clave para el examen:**
> - Si la pregunta dice migración de DB con diferente motor → **SCT + DMS**
> - Si la pregunta dice migración de DB con mismo motor → **solo DMS**
> - DMS puede usarse para replicación continua (CDC), no solo para migraciones puntuales

---

## AWS Snow Family

La familia Snow se utiliza para **migración de datos offline** cuando la transferencia por red no es viable (ancho de banda limitado, volúmenes masivos, ubicaciones remotas).

### Comparativa de dispositivos

| Característica | Snowcone | Snowcone SSD | Snowball Edge Storage Optimized | Snowball Edge Compute Optimized | Snowmobile |
|---|---|---|---|---|---|
| **Almacenamiento utilizable** | 8 TB HDD | 14 TB SSD | 80 TB | 42 TB | 100 PB |
| **Cómputo** | 2 vCPUs, 4 GB RAM | 2 vCPUs, 4 GB RAM | 40 vCPUs, 80 GB RAM | 104 vCPUs, 416 GB RAM, GPU opcional | N/A |
| **Caso de uso** | Edge computing ligero, migración pequeña | Edge con mayor almacenamiento SSD | Migraciones de datos grandes, edge computing | Procesamiento ML en edge, video | Migraciones a escala de exabytes |
| **Peso** | 2.1 kg (4.5 lbs) | 2.1 kg (4.5 lbs) | ~23 kg (50 lbs) | ~23 kg (50 lbs) | Camión con contenedor |
| **DataSync** | Agente pre-instalado | Agente pre-instalado | No (usa cliente Snow) | No (usa cliente Snow) | N/A |
| **Clustering** | No | No | Hasta 5-10 dispositivos | Hasta 5-10 dispositivos | N/A |

### Tiempos estimados de transferencia por red vs Snow

| Volumen de datos | 100 Mbps | 1 Gbps | 10 Gbps | Solución Snow recomendada |
|---|---|---|---|---|
| 10 TB | ~12 días | ~30 horas | ~3 horas | Snowcone / red (depende de urgencia) |
| 100 TB | ~120 días | ~12 días | ~30 horas | Snowball Edge |
| 1 PB | ~3 años | ~120 días | ~12 días | Snowball Edge (múltiples dispositivos) |
| 10 PB+ | Décadas | Años | ~120 días | Snowmobile |

### Regla general para el examen

> Si la transferencia por red tarda **más de una semana**, considera usar Snow Family.

### Flujo de trabajo de Snow

```
1. Solicitar dispositivo Snow desde la consola AWS
2. AWS envía el dispositivo físico
3. Conectar dispositivo y cargar datos (cliente Snow o DataSync)
4. Devolver el dispositivo a AWS
5. AWS carga los datos en S3
6. AWS borra el dispositivo de forma segura (NIST 800-88)
```

### Snowball Edge - Tipos

- **Storage Optimized:** Máximo almacenamiento (80 TB). Ideal para migraciones de datos grandes y almacenamiento local.
- **Compute Optimized:** Máximo cómputo (104 vCPUs). Ideal para procesamiento ML, análisis de video en edge. GPU NVIDIA Tesla V100 opcional.

---

## AWS Transfer Family

Servicio **completamente administrado** para transferir archivos hacia y desde Amazon S3 o Amazon EFS usando protocolos estándar.

### Protocolos soportados

| Protocolo | Puerto | Cifrado | Caso de uso |
|---|---|---|---|
| **SFTP** (SSH File Transfer Protocol) | 22 | Sí (SSH) | El más común, transferencias seguras |
| **FTPS** (FTP over SSL/TLS) | 21/990 | Sí (TLS) | Sistemas legacy que requieren FTP con cifrado |
| **FTP** (File Transfer Protocol) | 21 | No | Solo dentro de VPC (no público). Sistemas legacy |
| **AS2** (Applicability Statement 2) | 443 | Sí | Intercambio B2B (EDI, supply chain) |

### Características clave

- **Endpoint público o VPC:** Se puede exponer en internet o mantener privado dentro de VPC.
- **Integración con Route 53:** DNS personalizado (sftp.miempresa.com).
- **Autenticación:** AWS Directory Service, IdP personalizado (Lambda), claves SSH.
- **Almacenamiento backend:** S3 o EFS.
- **Sin gestión de servidores:** AWS gestiona la infraestructura.

> **Punto clave para el examen:** Cuando la pregunta mencione "transferir archivos usando SFTP/FTP a S3" o "reemplazar servidor FTP existente", la respuesta es **AWS Transfer Family**.

---

## AWS DataSync

Servicio para **transferir datos de forma rápida y automatizada** entre almacenamiento on-premises y servicios de AWS, o entre servicios de AWS.

### Escenarios de transferencia

```
On-Premises → AWS:
  NFS/SMB Server ──► Agente DataSync ──► (Internet o Direct Connect) ──► S3, EFS, FSx

AWS → AWS:
  S3 ──► DataSync ──► EFS
  EFS ──► DataSync ──► FSx for Windows
  (No necesita agente para transferencias entre servicios AWS)
```

### Características principales

| Característica | Detalle |
|---|---|
| **Velocidad** | Hasta 10 Gbps por tarea, usa protocolos de transferencia optimizados |
| **Automatización** | Tareas programadas (por hora, diaria, semanal) |
| **Compresión** | Comprime datos en tránsito para optimizar el ancho de banda |
| **Cifrado** | TLS en tránsito, integración con KMS para cifrado en reposo |
| **Verificación** | Verifica integridad de datos automáticamente |
| **Preservación de metadatos** | Conserva permisos, timestamps y atributos del sistema de archivos |
| **Filtrado** | Puede incluir/excluir archivos según patrones |
| **Ancho de banda** | Límite configurable para no saturar la red |

### DataSync vs otros servicios

| Servicio | Mejor para | Transferencia |
|---|---|---|
| **DataSync** | Migración de datos y sincronización recurrente, NFS/SMB a AWS | Online, automatizada |
| **Snow Family** | Grandes volúmenes (>10 TB) cuando la red es lenta | Offline, física |
| **Transfer Family** | Intercambio de archivos usando SFTP/FTP con clientes externos | Online, protocolo estándar |
| **Storage Gateway** | Acceso híbrido continuo (caché local + almacenamiento en S3) | Online, híbrido continuo |

> **Punto clave para el examen:** DataSync es para **mover datos** (migración o sincronización). Storage Gateway es para **acceso híbrido continuo**. No confundirlos.

---

## VMware Cloud on AWS

Permite ejecutar **VMware vSphere** directamente en infraestructura de AWS con acceso nativo a servicios de AWS.

### Casos de uso

- **Migración de centros de datos VMware** a AWS sin necesidad de re-arquitecturar (estrategia Relocate).
- **Extensión de capacidad:** Ampliar el entorno VMware on-premises a AWS para manejar picos de demanda.
- **Disaster Recovery:** Usar AWS como sitio DR para cargas de trabajo VMware.
- **Modernización gradual:** Mantener VMware mientras se migran aplicaciones progresivamente a servicios nativos de AWS.

### Características

- Ejecuta VMware vSphere, vSAN y NSX directamente sobre hardware dedicado de AWS.
- Acceso a servicios nativos de AWS (S3, RDS, Lambda, etc.) desde las VMs VMware.
- Gestionado conjuntamente por VMware y AWS.
- Las VMs pueden vivir en la misma AZ que los servicios de AWS para baja latencia.

---

## Tips para el Examen

### Preguntas frecuentes y respuestas rápidas

| Escenario del examen | Servicio / Estrategia |
|---|---|
| Migrar servidores tal cual (lift and shift) | **MGN** (Rehost) |
| Migrar base de datos mismo motor | **DMS** (sin SCT) |
| Migrar base de datos diferente motor | **SCT + DMS** (heterogénea) |
| Transferir 50 TB, red lenta (1 semana+) | **Snowball Edge** |
| Transferir 100 PB | **Snowmobile** |
| Mover archivos NFS/SMB a S3/EFS | **DataSync** |
| Servidor SFTP para compartir archivos con S3 | **Transfer Family** |
| Mapear dependencias entre servidores on-prem | **Application Discovery Service (Agent-Based)** |
| Inventario rápido de VMs VMware | **Application Discovery Service (Agentless)** |
| Panel centralizado de progreso de migración | **Migration Hub** |
| Migrar entorno VMware completo | **VMware Cloud on AWS** (Relocate) |
| Planificar la adopción organizacional de la nube | **Cloud Adoption Framework (CAF)** |
| Migración de datos pequeña en edge remoto | **Snowcone** |
| Replicación continua de base de datos | **DMS con CDC** |

### Errores comunes a evitar

1. **Confundir DataSync con Storage Gateway:** DataSync mueve datos, Storage Gateway proporciona acceso híbrido continuo.
2. **Olvidar SCT en migraciones heterogéneas:** Si los motores son diferentes, siempre se necesita SCT antes de DMS.
3. **Elegir Snowball para pocos TB:** Si la red es razonable y el volumen es bajo (<10 TB), DataSync o transferencia directa pueden ser más rápidas.
4. **Confundir MGN con DMS:** MGN migra servidores (aplicaciones completas), DMS migra solo bases de datos.
5. **No considerar Relocate:** Si el entorno es VMware, Relocate (VMware Cloud on AWS) es válido y tiene menor esfuerzo que Rehost.

### Fórmula para recordar las 7 Rs

> **R**etire, **R**etain, **R**elocate, **R**ehost, **R**eplatform, **R**epurchase, **R**efactor
> De menor a mayor esfuerzo y de menor a mayor beneficio de la nube.
