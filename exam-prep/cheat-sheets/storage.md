# Storage - Cheat Sheet Rápido

## Clases de Almacenamiento S3

| Clase | Durabilidad | Disponibilidad | AZs | Tiempo de recuperación | Caso de uso |
|-------|------------|----------------|-----|----------------------|-------------|
| **S3 Standard** | 99.999999999% (11 nueves) | 99.99% | ≥ 3 | Milisegundos | Datos de acceso frecuente, contenido web, analytics |
| **S3 Intelligent-Tiering** | 99.999999999% | 99.9% | ≥ 3 | Milisegundos | Patrones de acceso impredecibles o cambiantes |
| **S3 Standard-IA** | 99.999999999% | 99.9% | ≥ 3 | Milisegundos | Datos accedidos con poca frecuencia, backups activos |
| **S3 One Zone-IA** | 99.999999999% | 99.5% | **1** | Milisegundos | Datos recreables, copias secundarias, thumbnails |
| **S3 Glacier Instant Retrieval** | 99.999999999% | 99.9% | ≥ 3 | Milisegundos | Archivos accedidos 1 vez/trimestre, acceso instantáneo |
| **S3 Glacier Flexible Retrieval** | 99.999999999% | 99.99% (tras restaurar) | ≥ 3 | 1-5 min (Expedited), 3-5 hrs (Standard), 5-12 hrs (Bulk) | Archivos, compliance, backups a largo plazo |
| **S3 Glacier Deep Archive** | 99.999999999% | 99.99% (tras restaurar) | ≥ 3 | 12 hrs (Standard), 48 hrs (Bulk) | Retención a largo plazo (7-10+ años), regulatorio |

> **Clave examen:** Todas las clases tienen **11 nueves de durabilidad** excepto que la disponibilidad varía. **One Zone-IA** es la única en 1 AZ.

### Datos importantes S3
- **Tamaño máximo de objeto:** 5 TB
- **Multipart upload:** Recomendado > 100 MB, obligatorio > 5 GB
- **Máximo PUT en una sola operación:** 5 GB

---

## Tipos de Volumen EBS

| Tipo | Nombre | IOPS máx | Throughput máx | Tamaño | Boot | Caso de uso |
|------|--------|----------|---------------|--------|------|-------------|
| **gp3** | General Purpose SSD | 16,000 | 1,000 MB/s | 1 GB - 16 TB | Sí | Cargas generales, desarrollo, bases de datos pequeñas |
| **gp2** | General Purpose SSD | 16,000 (burst) | 250 MB/s | 1 GB - 16 TB | Sí | Similar a gp3 (generación anterior) |
| **io2 Block Express** | Provisioned IOPS SSD | **256,000** | 4,000 MB/s | 4 GB - 64 TB | Sí | Bases de datos críticas, alta IOPS sostenida |
| **io2/io1** | Provisioned IOPS SSD | 64,000 | 1,000 MB/s | 4 GB - 16 TB | Sí | Bases de datos intensivas, SAP HANA |
| **st1** | Throughput Optimized HDD | 500 | **500 MB/s** | 125 GB - 16 TB | **No** | Big data, data warehouses, logs (secuencial) |
| **sc1** | Cold HDD | 250 | 250 MB/s | 125 GB - 16 TB | **No** | Datos fríos, acceso infrecuente, menor costo |

> **Claves examen:**
> - **HDD (st1/sc1) NO puede ser boot volume** — solo SSD (gp/io).
> - Si piden "IOPS garantizadas" o "más de 16,000 IOPS" → **io2/io1**.
> - **gp3** es más barato que gp2 y permite configurar IOPS y throughput independientemente.
> - Si piden "mayor throughput secuencial" → **st1**.

---

## EFS vs EBS vs S3

| Característica | EBS | EFS | S3 |
|---------------|-----|-----|-----|
| **Tipo** | Block storage | File storage (NFS) | Object storage |
| **Acceso** | Una instancia EC2 (excepto io multi-attach) | **Múltiples instancias** simultáneamente | Acceso vía HTTP/API |
| **Protocolo** | Dispositivo de bloque | NFSv4.1 | REST API / HTTP |
| **Scope** | **Una AZ** | Multi-AZ (Regional) | Multi-AZ (Regional) |
| **Escalado** | Tamaño fijo (manual resize) | **Automático** (crece/decrece) | **Ilimitado** |
| **Performance** | Muy alta (IOPS provisioned) | Buena (modos burst/provisioned) | Alta (paralelizable) |
| **Precio** | Más económico por GB | Más caro por GB | Más económico para objetos |
| **Snapshots** | Sí (a S3) | Backup con AWS Backup | Versionado nativo |
| **Caso de uso** | Base de datos, boot volume, app con disco local | CMS compartido, home dirs, contenedores, WordPress | Archivos estáticos, backups, data lake |

> **Truco examen:**
> - "Almacenamiento **compartido** entre múltiples EC2" → **EFS**
> - "Almacenamiento de **objetos** / archivos estáticos" → **S3**
> - "Disco de **alto rendimiento** para una instancia" → **EBS**
> - "Sistema de archivos Windows compartido" → **FSx for Windows**
> - "HPC con sistema de archivos de alto rendimiento" → **FSx for Lustre**

---

## Opciones de Cifrado S3

| Método | Tipo | Gestión de claves | Descripción |
|--------|------|-------------------|-------------|
| **SSE-S3** | Server-side | AWS gestiona todo | Default. Cifrado AES-256 gestionado por S3 automáticamente |
| **SSE-KMS** | Server-side | AWS KMS (tú controlas) | Usa claves KMS. Audit trail con CloudTrail. Tiene límite de API quota |
| **SSE-C** | Server-side | **Cliente provee la clave** | Tú envías la clave en cada request. AWS la usa y la descarta. Solo HTTPS |
| **CSE (Client-Side)** | Client-side | **Cliente cifra antes** | Tú cifras antes de subir a S3. S3 almacena datos ya cifrados |

> **Claves examen:**
> - **SSE-S3** es el default desde enero 2023 (todos los objetos nuevos se cifran automáticamente).
> - **SSE-KMS** cuando necesitas **auditoría** de quién usa las claves o **separación de responsabilidades**.
> - **SSE-C** cuando necesitas control total de las claves y no quieres almacenarlas en AWS.
> - **Bucket policy** puede forzar un tipo de cifrado específico (`s3:x-amz-server-side-encryption`).

---

## Tipos de Storage Gateway

| Tipo | Descripción |
|------|-------------|
| **S3 File Gateway** | Interfaz NFS/SMB que almacena archivos como objetos en S3 — acceso local con backend en la nube |
| **FSx File Gateway** | Cache local para acceder a FSx for Windows File Server — optimiza latencia para oficinas remotas |
| **Volume Gateway (Stored)** | Volúmenes iSCSI con datos primarios on-prem y snapshots asíncronas a S3 (como EBS Snapshots) |
| **Volume Gateway (Cached)** | Volúmenes iSCSI con datos primarios en S3 y cache local de datos frecuentes — expande capacidad |
| **Tape Gateway** | Emula librería de cintas (VTL) para software de backup existente, almacena en S3 y Glacier |

> **Truco examen:**
> - "Migrar backups de cinta a la nube" → **Tape Gateway**
> - "Acceso NFS a S3 desde on-prem" → **S3 File Gateway**
> - "Datos principales en la nube, cache local" → **Volume Gateway (Cached)**
> - "Datos principales on-prem, backup en la nube" → **Volume Gateway (Stored)**

---

## Snow Family

| Dispositivo | Capacidad de almacenamiento | Compute | Caso de uso |
|-------------|---------------------------|---------|-------------|
| **Snowcone** | 8 TB HDD / 14 TB SSD | 2 vCPUs, 4 GB RAM | Edge computing ligero, entornos remotos, transferencias pequeñas |
| **Snowball Edge Storage Optimized** | 80 TB usable | 40 vCPUs, 80 GB RAM | Migración de datos a gran escala, edge computing con almacenamiento |
| **Snowball Edge Compute Optimized** | 28 TB usable (+ 42 TB NVMe) | 104 vCPUs, 416 GB RAM, GPU opt. | ML en edge, procesamiento intensivo en campo |
| **Snowmobile** | **100 PB** | N/A | Migración de exabytes (centro de datos completo) |

> **Regla general examen:**
> - Transferir **hasta ~10 TB** → usar internet (Direct Connect, VPN, S3 Transfer Acceleration)
> - Transferir **10 TB - 10 PB** → **Snowball Edge**
> - Transferir **más de 10 PB** → **Snowmobile**
> - **Edge computing remoto** → Snowcone (pequeño) o Snowball Edge Compute (potente)

---

## Resumen de Decisiones Rápidas - Storage

```
PREGUNTA DEL EXAMEN                                → RESPUESTA
──────────────────────────────────────────────────────────────
"Almacenar objetos con acceso HTTP"                 → S3
"Disco de alto rendimiento para EC2"                → EBS (gp3 o io2)
"Sistema de archivos compartido Linux"              → EFS
"Sistema de archivos compartido Windows"            → FSx for Windows
"HPC filesystem de alto rendimiento"                → FSx for Lustre
"Archival a largo plazo, menor costo"               → S3 Glacier Deep Archive
"Patrón de acceso impredecible"                     → S3 Intelligent-Tiering
"Migrar TBs de datos de on-prem"                    → Snowball Edge
"Acceso NFS a S3 desde on-prem"                     → S3 File Gateway
"Backup de cintas a la nube"                        → Tape Gateway
"IOPS garantizadas > 16,000"                        → EBS io2/io1
"Throughput secuencial alto, big data"              → EBS st1
```
