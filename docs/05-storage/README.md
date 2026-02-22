# Almacenamiento en AWS (Storage)

## Índice

- [Tipos de almacenamiento: Block vs File vs Object](#tipos-de-almacenamiento-block-vs-file-vs-object)
- [Amazon S3](#amazon-s3)
- [Clases de almacenamiento S3](#clases-de-almacenamiento-s3)
- [Características de S3](#características-de-s3)
- [Rendimiento de S3](#rendimiento-de-s3)
- [Control de acceso en S3](#control-de-acceso-en-s3)
- [Notificaciones de eventos S3](#notificaciones-de-eventos-s3)
- [Amazon EBS](#amazon-ebs)
- [Amazon EFS](#amazon-efs)
- [Amazon FSx](#amazon-fsx)
- [AWS Storage Gateway](#aws-storage-gateway)
- [AWS Snow Family](#aws-snow-family)
- [AWS DataSync vs Transfer Family](#aws-datasync-vs-transfer-family)
- [Tips para el examen](#tips-para-el-examen)

---

## Tipos de almacenamiento: Block vs File vs Object

Antes de ver los servicios individuales, es fundamental entender los tres modelos de almacenamiento porque el examen pregunta cuál usar en cada escenario.

| | Block Storage | File Storage | Object Storage |
|---|---|---|---|
| **Analogía** | Un disco duro conectado a tu PC | Una carpeta compartida en red (NAS) | Un almacén de paquetes con etiqueta |
| **Unidad** | Bloques de bytes (como sectores de disco) | Archivos organizados en directorios | Objetos con key + metadata |
| **Acceso** | Directo, byte a byte | Por ruta jerárquica (NFS/SMB) | Por HTTP (GET/PUT) |
| **Modificación parcial** | Sí (cambiar 1 byte) | Sí (editar un fichero) | **No** (reescribir el objeto entero) |
| **Latencia** | Sub-milisegundo | Milisegundos | Milisegundos a cientos de ms |
| **El SO lo ve como** | Un disco local (le pone su filesystem: NTFS, ext4) | Un punto de montaje de red | No se monta; se accede por API |
| **Caso de uso** | Bases de datos, trading apps, boot volumes | Ficheros compartidos, home dirs, CMS | Backups, media, data lakes, web assets |
| **Servicios AWS** | **EBS**, FSx for NetApp ONTAP (iSCSI) | **EFS** (NFS), **FSx** (SMB/NFS) | **S3** |

### Por qué importa la distinción para el examen

```
App transaccional (BD, trading)  →  necesita leer/escribir bloques individuales rápido
                                 →  Block Storage (EBS o iSCSI)

Ficheros compartidos entre servers →  necesita rutas /datos/informe.pdf accesibles por varios servers
                                   →  File Storage (EFS o FSx)

Almacenar millones de objetos      →  no necesita edición parcial, escala infinita
                                   →  Object Storage (S3)
```

> **Tip para el examen:** Si el escenario dice "low-latency block storage" compartido multi-AZ, EBS no sirve (es single-AZ). La respuesta es **FSx for NetApp ONTAP con iSCSI**, que expone block storage por red accesible desde múltiples AZs. Si solo dice "block storage single-AZ", la respuesta es **EBS**.

---

## Amazon S3

Amazon Simple Storage Service (S3) es un servicio de almacenamiento de objetos que ofrece escalabilidad, disponibilidad de datos, seguridad y rendimiento líderes en la industria.

**Conceptos clave:**

- **Buckets**: Contenedores de objetos. Nombres globalmente únicos.
- **Objetos**: Archivos almacenados. Tamaño máximo de un objeto: **5 TB**. Para uploads mayores a 5 GB se debe usar multipart upload.
- **Key**: Ruta completa del objeto (prefijo + nombre).
- No hay concepto de "directorios" reales, solo prefijos en la key.

---

## Clases de almacenamiento S3

| Clase | Durabilidad | Disponibilidad | AZs | Latencia | Coste relativo | Caso de uso |
|---|---|---|---|---|---|---|
| **S3 Standard** | 99.999999999% (11 9s) | 99.99% | >= 3 | ms | $$$$$ | Datos accedidos frecuentemente |
| **S3 Intelligent-Tiering** | 99.999999999% | 99.9% | >= 3 | ms | $$$$$ (+ tarifa monitoreo) | Patrones de acceso impredecibles |
| **S3 Standard-IA** | 99.999999999% | 99.9% | >= 3 | ms | $$$$ | Datos poco frecuentes, acceso rápido necesario |
| **S3 One Zone-IA** | 99.999999999% | 99.5% | 1 | ms | $$$ | Datos poco frecuentes, recreables |
| **S3 Glacier Instant Retrieval** | 99.999999999% | 99.9% | >= 3 | ms | $$$ | Archivos accedidos 1 vez/trimestre, acceso inmediato |
| **S3 Glacier Flexible Retrieval** | 99.999999999% | 99.99% (tras restaurar) | >= 3 | min-hrs | $$ | Archivos con recuperación flexible |
| **S3 Glacier Deep Archive** | 99.999999999% | 99.99% (tras restaurar) | >= 3 | hrs | $ | Retención a largo plazo (7-10 años) |

### Detalles de Intelligent-Tiering

Mueve automáticamente los objetos entre niveles sin impacto en rendimiento ni cargos por recuperación:

- **Frequent Access tier**: acceso normal (por defecto).
- **Infrequent Access tier**: objetos no accedidos en 30 días.
- **Archive Instant Access tier**: objetos no accedidos en 90 días.
- **Archive Access tier** (opcional): objetos no accedidos en 90-730 días.
- **Deep Archive Access tier** (opcional): objetos no accedidos en 180-730 días.

### Tiempos de recuperación en Glacier

| Clase | Expedited | Standard | Bulk |
|---|---|---|---|
| **Glacier Flexible Retrieval** | 1-5 min | 3-5 hrs | 5-12 hrs |
| **Glacier Deep Archive** | No disponible | 12 hrs | 48 hrs |

**Detalle de cada tipo de retrieval:**
```
Expedited:  1-5 minutos, hasta 150 MB/s throughput
            ⚠️ Sin provisioned capacity → puede fallar en alta demanda
            Con provisioned capacity → GARANTIZADO siempre disponible

Standard:   3-5 horas, para datos que no son urgentes

Bulk:       5-12 horas, lo más barato, para grandes volúmenes sin prisa
```

**Provisioned Retrieval Capacity:**
```
Problema: Expedited retrieval usa capacidad compartida de AWS
          En momentos de alta demanda, tu request puede ser rechazado

Solución: Compras "provisioned capacity" (~$100/mes por unidad)
          → Garantiza que Expedited SIEMPRE funciona
          → Cada unidad = 3 retrievals cada 5 min + 150 MB/s throughput

Cuándo usarlo:
  - Compliance que exige acceso garantizado ("under all circumstances")
  - Auditorías sorpresa que necesitan datos en minutos
  - SLA estricto de recuperación de datos
```

> **Clave para el examen**: Glacier Instant Retrieval ofrece acceso en milisegundos. Glacier Flexible Retrieval requiere restauración previa. Deep Archive es la opción más barata pero con tiempos de recuperación de horas. Si el enunciado pide acceso garantizado en minutos "under all circumstances" → Expedited + Provisioned Retrieval Capacity.

---

## Características de S3

### Versionado (Versioning)

- Se habilita a nivel de bucket.
- Cada objeto tiene un **Version ID**.
- Protege contra eliminaciones accidentales (los deletes crean un **delete marker**).
- Versiones anteriores se pueden restaurar eliminando el delete marker.
- Una vez habilitado, solo se puede suspender, **no deshabilitar**.
- Los objetos previos a la habilitación tienen Version ID = `null`.

### Políticas de ciclo de vida (Lifecycle Policies)

Permiten automatizar la transición entre clases de almacenamiento o la expiración de objetos:

- **Transition actions**: Mover objetos a otra clase tras X días.
- **Expiration actions**: Eliminar objetos tras X días.
- Se pueden aplicar a prefijos específicos o tags.
- Se pueden aplicar a versiones actuales y/o anteriores.

**Reglas de transición permitidas:**

```
Standard → Standard-IA → Intelligent-Tiering → One Zone-IA
    ↓                                               ↓
Glacier Instant → Glacier Flexible → Glacier Deep Archive
```

> **Clave**: Mínimo 30 días en Standard antes de transicionar a Standard-IA o One Zone-IA. Mínimo 30 días adicionales antes de transicionar a Glacier.

### Replicación

| Característica | CRR (Cross-Region Replication) | SRR (Same-Region Replication) |
|---|---|---|
| **Regiones** | Diferentes regiones | Misma región |
| **Caso de uso** | Compliance, menor latencia, replicación entre cuentas | Agregación de logs, replicación entre cuentas en producción/test |
| **Requisitos** | Versionado habilitado en origen y destino | Versionado habilitado en origen y destino |

**Notas importantes sobre replicación:**

- Solo se replican objetos nuevos tras habilitar la regla.
- Para replicar objetos existentes se usa **S3 Batch Replication**.
- Los delete markers **no se replican** por defecto (se puede habilitar).
- No hay replicación en cadena (A → B → C: los objetos replicados en B no se replican a C).

### Cifrado (Encryption)

| Método | Gestión de claves | Cuándo usar |
|---|---|---|
#### Server-Side Encryption (SSE) — AWS cifra después de recibir el objeto

| Método | Quién gestiona la clave | Datos viajan sin cifrar a AWS? | Clave en AWS? |
|---|---|---|---|
| **SSE-S3** | AWS completamente (AES-256) | Sí (cifrados en tránsito por HTTPS, pero AWS los ve) | Sí |
| **SSE-KMS** | AWS KMS (tú controlas la key policy) | Sí | Sí |
| **SSE-C** | Tú proporcionas la clave en cada request | Sí (solo HTTPS) | No se almacena (AWS la usa y descarta) |

```
Cliente  ──── objeto en claro (HTTPS) ────►  S3  ──► cifra con la clave ──► almacena cifrado
```

En los tres casos SSE, AWS recibe el objeto sin cifrar (protegido por HTTPS en tránsito) y lo cifra antes de escribirlo a disco.

#### Client-Side Encryption — El cliente cifra ANTES de enviar

| Variante | Master key | Master key sale del cliente? | Datos sin cifrar llegan a AWS? |
|---|---|---|---|
| **Client-Side con KMS key** | AWS KMS genera la data key | Sí (pides la data key a KMS via API) | **No** |
| **Client-Side con client-side master key** | Tú la gestionas localmente | **No** (nunca sale de tu entorno) | **No** |

```
Client-Side con KMS:
Cliente ──► pide data key a KMS ──► cifra localmente ──► sube cifrado a S3

Client-Side con client master key:
Cliente ──► genera data key con su master key local ──► cifra localmente ──► sube cifrado a S3
                (la master key NUNCA sale del cliente)
```

**Con client-side encryption el objeto en S3 es ilegible.** No se puede ver desde la consola de AWS, ni con acceso directo al bucket. Para leerlo hay que descargarlo y descifrarlo con la master key correspondiente.

**Cómo funciona (envelope encryption):**
1. El SDK genera una **data key** aleatoria para cada objeto.
2. Cifra el objeto con esa data key.
3. Cifra la data key con la **master key** (KMS o local).
4. Sube el objeto cifrado + la data key cifrada como metadata (`x-amz-meta-x-amz-key`).
5. Para leer: descarga, descifra la data key con la master key, descifra el objeto con la data key.

> Si pierdes la master key, **pierdes los datos para siempre**. AWS no puede ayudarte.

#### Cuándo usar cada método (para el examen)

| Requisito del escenario | Método |
|---|---|
| Sin requisitos especiales, cifrado básico | **SSE-S3** (por defecto) |
| Auditoría de uso de claves con CloudTrail | **SSE-KMS** |
| "El cliente debe controlar la clave" pero acepta que AWS cifre | **SSE-C** |
| "Los datos no deben llegar sin cifrar a AWS" | **Client-Side** |
| "La master key no debe salir del entorno del cliente / no debe ir a AWS" | **Client-Side con client-side master key** |
| "Datos no cifrados ni master key deben llegar a AWS" | **Client-Side con client-side master key** |

> **Clave para el examen**: SSE-KMS tiene un límite de cuota de API de KMS (5,500-30,000 requests/s según región). Para cargas masivas, considerar SSE-S3 o S3 Bucket Keys (reduce llamadas a KMS un 99%).

**Cifrado por defecto:**
- Desde enero 2023, SSE-S3 se aplica automáticamente a todos los objetos nuevos.
- Se puede forzar SSE-KMS mediante bucket policy denegando uploads sin el header correcto.

### Object Lock y Glacier Vault Lock

**S3 Object Lock** (requiere versionado):
- **Retention mode - Compliance**: Nadie puede eliminar ni modificar la retención, ni siquiera el usuario root.
- **Retention mode - Governance**: Solo usuarios con permisos especiales pueden modificar la retención.
- **Legal Hold**: Protege el objeto indefinidamente, independiente del período de retención. Se puede establecer/quitar con permiso `s3:PutObjectLegalHold`.

**Glacier Vault Lock**: Política de vault que una vez bloqueada no puede modificarse. Ideal para compliance (WORM - Write Once Read Many).

### Presigned URLs

- URLs temporales que otorgan acceso a un objeto privado.
- Se generan con el SDK o CLI.
- Expiración configurable: por defecto **3600 segundos** (1 hora), máximo 168 horas con CLI.
- El que accede hereda los permisos del usuario que generó la URL.
- Caso de uso: compartir temporalmente archivos privados, permitir uploads temporales.

---

## Rendimiento de S3

### Línea base de rendimiento

- **3,500 PUT/COPY/POST/DELETE** requests por segundo por prefijo.
- **5,500 GET/HEAD** requests por segundo por prefijo.
- No hay límite en el número de prefijos.

### Multipart Upload

- **Recomendado** para archivos > 100 MB.
- **Obligatorio** para archivos > 5 GB.
- Paraleliza la subida dividiendo el archivo en partes.
- Si una parte falla, solo esa parte se re-sube.

### S3 Transfer Acceleration

- Usa edge locations de CloudFront para acelerar transferencias de larga distancia.
- El archivo se sube al edge más cercano y luego viaja por la red interna de AWS al bucket.
- Compatible con multipart upload.
- Coste adicional; útil cuando los usuarios están lejos de la región del bucket.

### S3 Byte-Range Fetches

- Paraleliza GETs solicitando rangos de bytes específicos.
- Mejor resiliencia ante fallos (se puede reintentar un rango específico).
- Caso de uso: descargar solo los primeros N bytes (ej: header de un archivo).

### S3 Select y Glacier Select

- Permiten usar SQL para filtrar datos directamente en S3.
- Reduce la transferencia de datos hasta un **80%** y el coste un **400%**.
- Filtra filas y columnas de archivos CSV, JSON o Parquet.
- Reemplazado progresivamente por S3 Object Lambda para transformaciones más complejas.

---

## Control de acceso en S3

### Bucket Policies

- Políticas basadas en JSON aplicadas al bucket.
- Permiten acceso cross-account.
- Casos de uso: forzar cifrado, conceder acceso público, requerir MFA para delete.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyUnencryptedUploads",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::mi-bucket/*",
      "Condition": {
        "StringNotEquals": {
          "s3:x-amz-server-side-encryption": "aws:kms"
        }
      }
    }
  ]
}
```

### ACLs (Access Control Lists)

- Mecanismo legacy, **AWS recomienda deshabilitarlas**.
- A nivel de bucket u objeto.
- Desde abril 2023, nuevos buckets tienen ACLs deshabilitadas por defecto (BucketOwnerEnforced).

### S3 Access Points

- Simplifican la gestión de acceso para datasets compartidos.
- Cada access point tiene su propio DNS y política.
- Se pueden restringir a una VPC específica (VPC origin).
- Caso de uso: equipos diferentes necesitan acceso a diferentes prefijos del mismo bucket.

### S3 Object Lambda

- Permite transformar datos al vuelo durante un GET request.
- Usa funciones Lambda para modificar el objeto antes de devolverlo.
- Casos de uso: redactar datos PII, convertir formatos, redimensionar imágenes, enriquecer datos.

---

## Notificaciones de eventos S3

Se pueden enviar notificaciones cuando ocurren eventos en el bucket (ej: `s3:ObjectCreated:*`, `s3:ObjectRemoved:*`):

| Destino | Notas |
|---|---|
| **Amazon SNS** | Requiere SNS Resource Policy que permita a S3 publicar |
| **Amazon SQS** | Requiere SQS Resource Policy que permita a S3 enviar mensajes |
| **AWS Lambda** | Requiere Lambda Resource Policy que permita a S3 invocar |
| **Amazon EventBridge** | Se habilita a nivel de bucket. Permite reglas avanzadas, múltiples destinos, archivo, replay |

> **Clave para el examen**: EventBridge ofrece filtrado avanzado (JSON rules), múltiples destinos y capacidades de archivo/replay que los otros destinos no tienen.

---

## Amazon EBS

Amazon Elastic Block Store proporciona volúmenes de almacenamiento en bloque para instancias EC2.

**Características clave:**

- Ligado a una **AZ específica** (para mover entre AZs, crear snapshot y restaurar).
- Solo se puede adjuntar a instancias en la misma AZ.
- Se factura por capacidad provisionada.
- Permite cambiar tipo y tamaño en caliente (con limitaciones).

### Tipos de volúmenes EBS

| Tipo | Categoría | IOPS máx | Throughput máx | Tamaño | Caso de uso |
|---|---|---|---|---|---|
| **gp3** | SSD General Purpose | 16,000 | 1,000 MB/s | 1 GB - 16 TB | Boot volumes, apps interactivas, dev/test |
| **gp2** | SSD General Purpose | 16,000 (burst) | 250 MB/s | 1 GB - 16 TB | Boot volumes (legacy, burst IOPS) |
| **io2 Block Express** | SSD Provisioned IOPS | 256,000 | 4,000 MB/s | 4 GB - 64 TB | Cargas críticas, bases de datos de alto rendimiento |
| **io2** | SSD Provisioned IOPS | 64,000 | 1,000 MB/s | 4 GB - 16 TB | Bases de datos con requisitos consistentes de IOPS |
| **io1** | SSD Provisioned IOPS | 64,000 | 1,000 MB/s | 4 GB - 16 TB | Similar a io2 (legacy) |
| **st1** | HDD Throughput Optimized | 500 | 500 MB/s | 125 GB - 16 TB | Big data, data warehouses, procesamiento de logs |
| **sc1** | HDD Cold | 250 | 250 MB/s | 125 GB - 16 TB | Datos poco accedidos, coste mínimo |

**Notas importantes:**

- Solo **gp2, gp3, io1, io2** pueden ser boot volumes.
- **gp2**: IOPS escalan con el tamaño del volumen (3 IOPS por GB, mínimo 100, máximo 16,000). Burst hasta 3,000 IOPS para volúmenes < 1 TB.
- **gp3**: IOPS y throughput se configuran **independientemente** del tamaño. Base: 3,000 IOPS y 125 MB/s incluidos.
- **io1/io2**: Ratio máximo IOPS:GB es 50:1 (io1) y 500:1 (io2).

### EBS Snapshots

- Copia incremental del volumen en un punto en el tiempo.
- Se almacenan en S3 (gestionado por AWS).
- No es necesario detach el volumen, pero se recomienda.
- Se pueden copiar entre regiones y cuentas.

**Características de snapshots:**

- **EBS Snapshot Archive**: Mover snapshot a un tier 75% más barato. Restauración tarda 24-72 horas.
- **Recycle Bin**: Protección contra eliminación accidental. Configurable de 1 día a 1 año.
- **Fast Snapshot Restore (FSR)**: Elimina la latencia en el primer acceso. Costoso ($$$).

### EBS Encryption

- Cifrado AES-256 con claves KMS.
- Cifra datos en reposo, datos en tránsito (entre instancia y volumen), snapshots y volúmenes creados desde snapshots cifrados.
- Impacto mínimo en latencia.
- Para cifrar un volumen existente no cifrado:
  1. Crear snapshot del volumen.
  2. Copiar el snapshot habilitando cifrado.
  3. Crear nuevo volumen desde el snapshot cifrado.

### EBS Multi-Attach

- Solo disponible para volúmenes **io1/io2**.
- Permite adjuntar un volumen a **hasta 16 instancias EC2** en la **misma AZ**.
- Cada instancia tiene permisos de lectura y escritura.
- Requiere un sistema de archivos cluster-aware (ej: GFS2, no ext4/XFS).
- Caso de uso: aplicaciones de alta disponibilidad en cluster.

---

## Amazon EFS

Amazon Elastic File System es un sistema de archivos NFS gestionado que puede montarse en múltiples instancias EC2 simultáneamente.

**Características principales:**

- Funciona **cross-AZ** (a diferencia de EBS).
- Solo compatible con instancias **Linux** (basado en POSIX/NFS v4.1).
- Escala automáticamente (pago por uso, no hay provisionamiento de capacidad).
- Puede crecer hasta **petabytes**.
- Alta disponibilidad y durabilidad.

### Performance Modes (se definen al crear)

| Modo | Latencia | Throughput | Caso de uso |
|---|---|---|---|
| **General Purpose** (default) | Baja (sub-ms) | Normal | Web servers, CMS, desarrollo |
| **Max I/O** | Mayor latencia | Mayor throughput paralelo | Big data, procesamiento de media |

> **Nota**: Con EFS elástico, el modo Max I/O se considera legacy. AWS recomienda General Purpose para la mayoría de cargas.

### Throughput Modes

| Modo | Descripción | Caso de uso |
|---|---|---|
| **Bursting** | Throughput escala con el tamaño del filesystem | Cargas con picos esporádicos |
| **Provisioned** | Throughput fijo independiente del tamaño | Throughput alto con poco almacenamiento |
| **Elastic** (recomendado) | Escala automáticamente según la carga | Cargas impredecibles |

### Storage Classes de EFS

| Clase | Descripción |
|---|---|
| **Standard** | Acceso frecuente |
| **Standard-IA** | Acceso infrecuente, menor coste |
| **One Zone** | Una sola AZ, acceso frecuente |
| **One Zone-IA** | Una sola AZ, acceso infrecuente (la más barata) |

Se pueden configurar lifecycle policies para mover archivos entre clases (ej: mover a IA tras 30 días sin acceso).

### EFS vs EBS - Comparación

| Característica | EBS | EFS |
|---|---|---|
| **Tipo** | Block storage | File storage (NFS) |
| **Adjunto** | 1 instancia (excepto multi-attach io1/io2) | Múltiples instancias |
| **Alcance** | Una AZ | Multi-AZ |
| **SO** | Linux y Windows | Solo Linux |
| **Escalado** | Tamaño fijo (provisionado) | Automático |
| **Rendimiento** | Más rápido (directamente adjunto) | Bueno para compartir |
| **Coste** | Menor (por GB provisionado) | Mayor (pero pago por uso) |
| **Backup** | Snapshots | AWS Backup |

---

## Amazon FSx

Servicios de sistemas de archivos de alto rendimiento gestionados por AWS.

### FSx for Windows File Server

- **Protocolo**: SMB (Server Message Block) y NTFS.
- Integración con **Microsoft Active Directory**.
- Soporta **DFS (Distributed File System)** namespaces y replicación.
- Accesible desde instancias Windows y Linux.
- Almacenamiento SSD o HDD.
- Multi-AZ para alta disponibilidad.
- Backups diarios a S3.

**Cuándo usar**: Aplicaciones Windows que necesitan almacenamiento compartido, home directories, cargas de trabajo Microsoft.

### FSx for Lustre

- Sistema de archivos de **alto rendimiento** (HPC - High Performance Computing).
- Throughput de hasta **cientos de GB/s**, millones de IOPS, latencias sub-ms.
- Integración nativa con **S3**: puede leer/escribir datos directamente desde/hacia S3.
- **Scratch**: temporal, no replicado, alto rendimiento (procesamiento corto).
- **Persistent**: almacenamiento a largo plazo, replicado dentro de una AZ.

**Cuándo usar**: Machine learning, HPC, procesamiento de video, modelado financiero, análisis genómico.

### FSx for NetApp ONTAP

- Compatible con protocolos **NFS, SMB, iSCSI**.
- Compatible con **cualquier SO** (Linux, Windows, macOS).
- Almacenamiento auto-escalable.
- Snapshots, replicación, clonación instantánea.
- Compresión y deduplicación de datos.
- Point-in-time cloning.
- **Multi-AZ** para alta disponibilidad.

**iSCSI = block storage por red:** El protocolo iSCSI hace que la instancia vea el almacenamiento remoto como un disco local (block device). Esto lo diferencia de FSx for Windows (solo file/SMB) y EFS (solo file/NFS). Es el único FSx que ofrece **block storage compartido multi-AZ**.

**Cuándo usar**: Migración de workloads NetApp on-premises, necesidad de multi-protocolo, entornos heterogéneos, **block storage compartido multi-AZ** (trading, bases de datos Windows).

### FSx for OpenZFS

- Compatible con protocolo **NFS**.
- Rendimiento hasta **1,000,000 IOPS** con latencia < 0.5 ms.
- Snapshots, compresión.
- Point-in-time cloning (útil para testing).

**Cuándo usar**: Migración de workloads ZFS on-premises, cargas que requieren alto rendimiento con NFS.

### Resumen de FSx - Cuándo usar cada uno

| Servicio | Protocolo | SO | Caso de uso principal |
|---|---|---|---|
| **FSx for Windows** | SMB | Windows (y Linux) | Active Directory, apps Windows |
| **FSx for Lustre** | POSIX | Linux | HPC, ML, procesamiento masivo |
| **FSx for NetApp ONTAP** | NFS, SMB, iSCSI | Todos | Multi-protocolo, migración NetApp |
| **FSx for OpenZFS** | NFS | Linux | Migración ZFS, alto rendimiento |

---

## AWS Storage Gateway

Servicio de almacenamiento híbrido que conecta infraestructura on-premises con almacenamiento en la nube de AWS. Se ejecuta como VM on-premises o como hardware appliance.

### Tipos de Storage Gateway

| Gateway | Backend en AWS | Protocolo | Cache local | Caso de uso |
|---|---|---|---|---|
| **S3 File Gateway** | S3 (todas las clases excepto Glacier) | NFS, SMB | Sí | Extender almacenamiento de archivos a S3 |
| **FSx File Gateway** | FSx for Windows | SMB | Sí | Cache local de FSx for Windows |
| **Volume Gateway - Cached** | S3 (con EBS snapshots) | iSCSI | Datos frecuentes en cache | Volúmenes de bloque con cache local |
| **Volume Gateway - Stored** | S3 (con EBS snapshots) | iSCSI | Todos los datos locales | Backups de volúmenes completos |
| **Tape Gateway** | S3 y Glacier | iSCSI VTL | Sí | Reemplazo de cintas físicas (backup) |

### S3 File Gateway — Detalle

Es una VM (o appliance) que se instala on-premises y expone una carpeta compartida **NFS/SMB**. Los servidores on-premises la ven como un file share normal, pero los datos se almacenan en S3.

```
On-premises                                          AWS
┌────────────────────────────┐          ┌─────────────────────────┐
│  Servidor ──► \\gateway\docs (SMB) │          │  Amazon S3              │
│                │                   │          │  (todos los datos)      │
│         ┌──────▼──────────┐        │  sube    │                         │
│         │ S3 File Gateway │ ────────────────► │  Lifecycle Policy:      │
│         │ [Local Cache]   │        │  auto    │  0-6m: S3 Standard      │
│         │ SSD con datos   │        │          │  6m+: Glacier           │
│         │ recientes       │        │          └─────────────────────────┘
│         └─────────────────┘        │
└────────────────────────────────────┘
```

**Cómo funciona el local cache:**
- Al subir un fichero: se guarda en cache local **y** se sube a S3 automáticamente.
- Al leer un fichero reciente: se lee del cache local (baja latencia, sin coste de egress).
- Al leer un fichero antiguo (no en cache): se descarga de S3 y entra en cache. Lecturas siguientes son locales.
- El cache usa LRU (Least Recently Used): evicta los ficheros menos accedidos para hacer espacio.

**Beneficios:**
- Los empleados ven una carpeta SMB normal — no saben que los datos están en S3.
- Integra con **Active Directory** para autenticación SMB.
- Se pueden aplicar **S3 Lifecycle Policies** (mover a Glacier tras X meses).
- Reduce **data egress charges**: lecturas frecuentes se sirven del cache local, no de S3.

### Notas importantes sobre los demás tipos

- **Volume Gateway - Cached**: Solo los datos más accedidos se mantienen localmente; el dataset completo está en S3.
- **Volume Gateway - Stored**: Todos los datos están on-premises con backups asíncronos a S3.
- **Tape Gateway**: Compatible con software de backup existente (NetBackup, Veeam, etc.). Las cintas virtuales se archivan en S3 Glacier o Deep Archive. Protocolo iSCSI VTL (no SMB/NFS).

### Storage Gateway vs DataSync

| | S3 File Gateway | DataSync |
|---|---|---|
| **Propósito** | Acceso híbrido continuo (on-premises ↔ S3) | Migración/sincronización de datos (one-time o scheduled) |
| **Local cache** | **Sí** (baja latencia para datos recientes) | **No** |
| **Protocolo** | NFS, SMB (como un file share normal) | Agente que transfiere datos |
| **Patrón** | Los usuarios acceden a ficheros diariamente | Copiar/mover datos de A a B |

> **Clave para el examen:**
> - "Cache local" + "acceso a ficheros on-premises" + "datos en S3" → **S3 File Gateway**.
> - "SMB + Active Directory + lifecycle a Glacier" → **S3 File Gateway**.
> - "Migración de cintas de backup" → **Tape Gateway**.
> - "Migración de datos NFS/SMB a AWS (sin cache)" → **DataSync**.

---

## AWS Snow Family

Dispositivos físicos para transferencia de datos offline y edge computing.

| Característica | Snowcone / Snowcone SSD | Snowball Edge Storage Optimized | Snowball Edge Compute Optimized | Snowmobile |
|---|---|---|---|---|
| **Capacidad** | 8 TB HDD / 14 TB SSD | 80 TB usable | 42 TB usable | 100 PB |
| **Compute** | 2 vCPU, 4 GB RAM | 40 vCPU, 80 GB RAM | 104 vCPU, 416 GB RAM (GPU opcional) | No |
| **Tipo de transferencia** | Offline / DataSync (online) | Offline | Offline | Offline |
| **Caso de uso** | Entornos con espacio limitado, edge computing ligero | Migración masiva de datos, edge storage | HPC en edge, ML inference | Migración a escala de exabytes |
| **Peso** | ~2.1 kg | ~22 kg | ~22 kg | Camión completo |

### Cuándo usar Snow Family vs transferencia por red

**Regla general**: Si la transferencia por red tardaría más de **1 semana**, considerar Snow Family.

| Volumen de datos | Red (100 Mbps) | Red (1 Gbps) | Red (10 Gbps) | Dispositivo recomendado |
|---|---|---|---|---|
| 10 TB | 12 días | 30 horas | 3 horas | Red si >= 1 Gbps |
| 100 TB | 120 días | 12 días | 30 horas | Snowball Edge |
| 1 PB | 3 años | 120 días | 12 días | Snowball Edge (varios) |
| 10+ PB | 30 años | 3 años | 120 días | Snowmobile |

### Edge Computing con Snow

- Se pueden ejecutar instancias EC2 y funciones Lambda (usando IoT Greengrass).
- Procesamiento de datos donde no hay conexión a Internet o hay conectividad limitada.
- Se configuran antes del envío con AMIs y funciones Lambda.

### OpsHub

- Aplicación de escritorio para gestionar dispositivos Snow.
- Transferencia de datos, lanzar instancias, monitoreo.

---

## AWS DataSync vs Transfer Family

### AWS DataSync

- Servicio para **mover grandes cantidades de datos** entre:
  - On-premises → AWS (requiere DataSync agent)
  - AWS → AWS (entre servicios sin agent)
- **Destinos**: S3, EFS, FSx.
- **Orígenes**: NFS, SMB, HDFS, otros servicios AWS.
- Tareas programables (no continuas).
- Preserva metadatos y permisos.
- **Ancho de banda**: Puede consumir toda la red o limitarse.
- Cifrado en tránsito y verificación de integridad.

**Caso de uso**: Migración de datos, replicación para DR, archivado de datos.

### AWS Transfer Family

- Servicio gestionado para transferencias de archivos hacia/desde S3 o EFS usando protocolos estándar:
  - **SFTP** (SSH File Transfer Protocol)
  - **FTPS** (FTP sobre SSL)
  - **FTP** (solo dentro de VPC)
  - **AS2** (Applicability Statement 2)
- Integración con sistemas de autenticación existentes (Active Directory, LDAP, custom).
- Se expone como endpoint público o VPC.

**Caso de uso**: Socios comerciales que necesitan enviar/recibir archivos usando protocolos estándar (FTP/SFTP), flujos de trabajo B2B.

### Comparación

| Característica | DataSync | Transfer Family |
|---|---|---|
| **Protocolo** | Propietario (agent) | SFTP, FTPS, FTP, AS2 |
| **Dirección** | Bi-direccional (batch) | Bi-direccional (individual) |
| **Velocidad** | Alta (hasta 10 Gbps) | Depende del protocolo |
| **Uso** | Migración/replicación masiva | Intercambio de archivos con terceros |
| **Programación** | Tareas programables | Continuo (endpoint siempre activo) |

---

## Tips para el examen

### S3

1. **"Acceso infrecuente pero inmediato"** → S3 Standard-IA o One Zone-IA.
2. **"Patrón de acceso impredecible"** → S3 Intelligent-Tiering.
3. **"Archivado con acceso en milisegundos"** → Glacier Instant Retrieval.
4. **"Archivado largo plazo, no importa esperar horas"** → Glacier Deep Archive.
5. **"Forzar cifrado"** → Bucket policy con condición en el header de encryption.
6. **"Compartir archivo temporalmente"** → Presigned URL.
7. **"Datos deben ser inmutables (WORM)"** → Object Lock (Compliance mode) o Glacier Vault Lock.
8. **"Alto volumen de requests a S3"** → Distribuir objetos en múltiples prefijos.
9. **"Throttling con SSE-KMS"** → Usar S3 Bucket Keys o SSE-S3.
10. **"Replicar objetos existentes"** → S3 Batch Replication.

### EBS

1. **"Base de datos con IOPS altos y consistentes"** → io2/io2 Block Express.
2. **"Boot volume económico"** → gp3.
3. **"Alto throughput secuencial (logs, big data)"** → st1.
4. **"Almacenamiento frío, coste mínimo"** → sc1.
5. **"Compartir volumen entre instancias en misma AZ"** → Multi-Attach io1/io2.
6. **"Mover volumen a otra AZ"** → Snapshot + restaurar en otra AZ.
7. **"Cifrar volumen existente"** → Snapshot → copiar con cifrado → crear volumen.

### EFS

1. **"Almacenamiento compartido entre múltiples instancias Linux"** → EFS.
2. **"Almacenamiento compartido cross-AZ"** → EFS.
3. **"Windows file share"** → NO es EFS, es FSx for Windows.

### FSx

1. **"Windows file share con Active Directory"** → FSx for Windows.
2. **"HPC, ML, alto throughput en Linux"** → FSx for Lustre.
3. **"Multi-protocolo (NFS + SMB + iSCSI)"** → FSx for NetApp ONTAP.
4. **"Block storage compartido multi-AZ"** o **"low-latency block storage + Windows + multi-AZ"** → FSx for NetApp ONTAP con iSCSI (no EBS, que es single-AZ).
5. **"Migración de ZFS on-premises"** → FSx for OpenZFS.

### Storage Gateway

1. **"Extensión de almacenamiento on-premises a la nube"** → Storage Gateway.
2. **"Cache local + datos en S3"** → S3 File Gateway o Volume Gateway Cached.
3. **"Backup de cintas a la nube"** → Tape Gateway.
4. **"Latencia baja desde on-premises a FSx"** → FSx File Gateway.

### Snow Family

1. **"Transferencia > 1 semana por red"** → Snow Family.
2. **"Edge computing sin Internet"** → Snowball Edge o Snowcone.
3. **"Migración de exabytes"** → Snowmobile.

### DataSync vs Transfer Family

1. **"Migración masiva de datos NFS/SMB a AWS"** → DataSync.
2. **"Socios comerciales necesitan SFTP/FTP"** → Transfer Family.
