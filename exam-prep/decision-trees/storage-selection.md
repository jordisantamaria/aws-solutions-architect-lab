# Arbol de Decisión: Selección de Almacenamiento

## Pregunta Principal: ¿Qué tipo de almacenamiento necesitas?

```
¿Qué tipo de datos necesitas almacenar?
│
├── OBJETOS / ARCHIVOS (acceso HTTP, sin sistema de archivos)
│   │
│   └──→ Amazon S3
│        │
│        ├── ¿Con qué frecuencia accedes a los datos?
│        │   │
│        │   ├── Frecuentemente ──→ S3 Standard
│        │   │
│        │   ├── Patrón impredecible ──→ S3 Intelligent-Tiering
│        │   │
│        │   ├── Poco frecuente
│        │   │   ├── ¿Datos recreables? ──→ S3 One Zone-IA (más barato, 1 AZ)
│        │   │   └── ¿Datos críticos?   ──→ S3 Standard-IA (multi-AZ)
│        │   │
│        │   └── Archival / largo plazo
│        │       ├── ¿Acceso instantáneo ocasional? ──→ Glacier Instant Retrieval
│        │       ├── ¿Acceso en horas, flexible?     ──→ Glacier Flexible Retrieval
│        │       └── ¿Retención 7-10+ años, rara vez? ──→ Glacier Deep Archive
│        │
│        └── Funcionalidades adicionales:
│            ├── Versionado de objetos ──→ S3 Versioning
│            ├── Mover datos automáticamente ──→ S3 Lifecycle Policies
│            ├── Replicación cross-region ──→ S3 CRR
│            └── Consultar datos sin extraer ──→ S3 Select / Athena
│
├── BLOCK STORAGE (disco para instancia EC2)
│   │
│   └──→ Amazon EBS
│        │
│        ├── ¿Qué tipo de carga?
│        │   │
│        │   ├── General (boot, dev, apps normales)
│        │   │   └──→ gp3 (más flexible y económico que gp2)
│        │   │
│        │   ├── Alto IOPS (> 16,000) / BD críticas
│        │   │   ├── ¿Hasta 64,000 IOPS? ──→ io2
│        │   │   └── ¿Hasta 256,000 IOPS? ──→ io2 Block Express
│        │   │
│        │   ├── Alto throughput secuencial (big data, logs)
│        │   │   └──→ st1 (Throughput Optimized HDD)
│        │   │
│        │   └── Datos fríos, acceso mínimo, menor costo
│        │       └──→ sc1 (Cold HDD)
│        │
│        └── Notas:
│            ├── ¿Boot volume? ──→ Solo SSD (gp2/gp3/io1/io2)
│            ├── ¿Multi-attach (varias instancias)? ──→ Solo io1/io2
│            └── ¿Snapshot? ──→ Sí, a S3 (incremental)
│
├── SISTEMA DE ARCHIVOS COMPARTIDO (múltiples instancias)
│   │
│   ├── ¿Qué sistema operativo?
│   │   │
│   │   ├── Linux (NFS)
│   │   │   └──→ Amazon EFS
│   │   │       ├── Acceso frecuente ──→ EFS Standard
│   │   │       ├── Acceso infrecuente ──→ EFS-IA (más barato)
│   │   │       └── Ambos automáticamente ──→ EFS Lifecycle Management
│   │   │
│   │   └── Windows (SMB)
│   │       └──→ Amazon FSx for Windows File Server
│   │           (Active Directory, DFS, quotas)
│   │
│   └── ¿HPC / alto rendimiento paralelo?
│       └──→ Amazon FSx for Lustre
│           ├── Se integra con S3 como data lake
│           └── Ideal para ML, simulaciones, genomics
│
├── ARCHIVAL / RETENCIÓN REGULATORIA
│   │
│   ├── ¿Acceso inmediato necesario? ──→ S3 Glacier Instant Retrieval
│   ├── ¿Acceso en minutos/horas?    ──→ S3 Glacier Flexible Retrieval
│   └── ¿Mínimo costo, acceso raro?  ──→ S3 Glacier Deep Archive
│       └── S3 Object Lock para compliance WORM (Write Once Read Many)
│
└── ALMACENAMIENTO HÍBRIDO (on-premises + nube)
    │
    └──→ AWS Storage Gateway
         │
         ├── ¿Qué necesitas?
         │   │
         │   ├── Acceso NFS/SMB a S3 desde on-prem
         │   │   └──→ S3 File Gateway
         │   │
         │   ├── Cache local para FSx Windows
         │   │   └──→ FSx File Gateway
         │   │
         │   ├── Volúmenes iSCSI
         │   │   ├── Datos principales on-prem ──→ Volume Gateway (Stored)
         │   │   └── Datos principales en S3   ──→ Volume Gateway (Cached)
         │   │
         │   └── Migrar backups de cinta
         │       └──→ Tape Gateway (Virtual Tape Library)
         │
         └── ¿Migración masiva de datos?
             ├── < 10 TB ──→ Internet / DataSync / Direct Connect
             ├── 10 TB - 10 PB ──→ Snowball Edge
             └── > 10 PB ──→ Snowmobile
```

---

## Tabla Resumen de Decisión

| Si necesitas... | Usa... | Porque... |
|----------------|--------|-----------|
| Almacenar archivos/objetos | S3 | Almacenamiento de objetos ilimitado, 11 nueves de durabilidad |
| Disco de alto rendimiento | EBS gp3/io2 | Block storage adjunto a EC2, IOPS configurables |
| Compartir archivos entre EC2 (Linux) | EFS | NFS gestionado, auto-scaling, multi-AZ |
| Compartir archivos entre EC2 (Windows) | FSx for Windows | SMB nativo, Active Directory |
| HPC / ML filesystem | FSx for Lustre | Rendimiento paralelo masivo, integración S3 |
| Archival barato | Glacier Deep Archive | Menor costo por GB en AWS |
| Conectar on-prem a S3 | S3 File Gateway | Interfaz familiar (NFS/SMB) con backend S3 |
| Migrar datos masivamente | Snow Family | Transferencia física cuando internet es lento |

---

## Keywords del Examen → Servicio

```
"Object storage"                     → S3
"Static website hosting"             → S3
"Data lake"                          → S3
"High IOPS database"                 → EBS io2
"Boot volume"                        → EBS (SSD)
"Shared Linux file system"           → EFS
"Shared Windows file system"         → FSx for Windows
"High performance computing"         → FSx for Lustre
"Archive / compliance / WORM"        → Glacier + Object Lock
"On-prem NFS to cloud"              → S3 File Gateway
"Backup tapes to cloud"             → Tape Gateway
"Transfer terabytes offline"         → Snowball Edge
"Transfer petabytes offline"         → Snowmobile
"Replicate data between regions"     → S3 Cross-Region Replication
"Query data in S3 without ETL"       → Athena / S3 Select
```
