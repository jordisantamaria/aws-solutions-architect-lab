# Storage - Quick Cheat Sheet

## S3 Storage Classes

| Class | Durability | Availability | AZs | Retrieval Time | Use Case |
|-------|-----------|--------------|-----|----------------|----------|
| **S3 Standard** | 99.999999999% (11 nines) | 99.99% | >= 3 | Milliseconds | Frequently accessed data, web content, analytics |
| **S3 Intelligent-Tiering** | 99.999999999% | 99.9% | >= 3 | Milliseconds | Unpredictable or changing access patterns |
| **S3 Standard-IA** | 99.999999999% | 99.9% | >= 3 | Milliseconds | Infrequently accessed data, active backups |
| **S3 One Zone-IA** | 99.999999999% | 99.5% | **1** | Milliseconds | Recreatable data, secondary copies, thumbnails |
| **S3 Glacier Instant Retrieval** | 99.999999999% | 99.9% | >= 3 | Milliseconds | Archives accessed once per quarter, instant access |
| **S3 Glacier Flexible Retrieval** | 99.999999999% | 99.99% (after restore) | >= 3 | 1-5 min (Expedited), 3-5 hrs (Standard), 5-12 hrs (Bulk) | Archives, compliance, long-term backups |
| **S3 Glacier Deep Archive** | 99.999999999% | 99.99% (after restore) | >= 3 | 12 hrs (Standard), 48 hrs (Bulk) | Long-term retention (7-10+ years), regulatory |

> **Exam key:** All classes have **11 nines of durability** except availability varies. **One Zone-IA** is the only one in 1 AZ.

### Important S3 Data
- **Maximum object size:** 5 TB
- **Multipart upload:** Recommended > 100 MB, mandatory > 5 GB
- **Maximum PUT in a single operation:** 5 GB

---

## EBS Volume Types

| Type | Name | Max IOPS | Max Throughput | Size | Boot | Use Case |
|------|------|----------|---------------|------|------|----------|
| **gp3** | General Purpose SSD | 16,000 | 1,000 MB/s | 1 GB - 16 TB | Yes | General workloads, development, small databases |
| **gp2** | General Purpose SSD | 16,000 (burst) | 250 MB/s | 1 GB - 16 TB | Yes | Similar to gp3 (previous generation) |
| **io2 Block Express** | Provisioned IOPS SSD | **256,000** | 4,000 MB/s | 4 GB - 64 TB | Yes | Critical databases, high sustained IOPS |
| **io2/io1** | Provisioned IOPS SSD | 64,000 | 1,000 MB/s | 4 GB - 16 TB | Yes | Intensive databases, SAP HANA |
| **st1** | Throughput Optimized HDD | 500 | **500 MB/s** | 125 GB - 16 TB | **No** | Big data, data warehouses, logs (sequential) |
| **sc1** | Cold HDD | 250 | 250 MB/s | 125 GB - 16 TB | **No** | Cold data, infrequent access, lowest cost |

> **Exam keys:**
> - **HDD (st1/sc1) CANNOT be boot volume** — only SSD (gp/io).
> - If they ask for "guaranteed IOPS" or "more than 16,000 IOPS" → **io2/io1**.
> - **gp3** is cheaper than gp2 and allows configuring IOPS and throughput independently.
> - If they ask for "highest sequential throughput" → **st1**.

---

## EFS vs EBS vs S3

| Feature | EBS | EFS | S3 |
|---------|-----|-----|-----|
| **Type** | Block storage | File storage (NFS) | Object storage |
| **Access** | One EC2 instance (except io multi-attach) | **Multiple instances** simultaneously | Access via HTTP/API |
| **Protocol** | Block device | NFSv4.1 | REST API / HTTP |
| **Scope** | **One AZ** | Multi-AZ (Regional) | Multi-AZ (Regional) |
| **Scaling** | Fixed size (manual resize) | **Automatic** (grows/shrinks) | **Unlimited** |
| **Performance** | Very high (provisioned IOPS) | Good (burst/provisioned modes) | High (parallelizable) |
| **Price** | Most economical per GB | More expensive per GB | Most economical for objects |
| **Snapshots** | Yes (to S3) | Backup with AWS Backup | Native versioning |
| **Use case** | Database, boot volume, app with local disk | Shared CMS, home dirs, containers, WordPress | Static files, backups, data lake |

> **Exam trick:**
> - "**Shared** storage between multiple EC2" → **EFS**
> - "**Object** storage / static files" → **S3**
> - "**High-performance** disk for a single instance" → **EBS**
> - "Shared Windows file system" → **FSx for Windows**
> - "HPC with high-performance file system" → **FSx for Lustre**

---

## S3 Encryption Options

| Method | Type | Key Management | Description |
|--------|------|----------------|-------------|
| **SSE-S3** | Server-side | AWS manages everything | Default. AES-256 encryption managed by S3 automatically |
| **SSE-KMS** | Server-side | AWS KMS (you control) | Uses KMS keys. Audit trail with CloudTrail. Has API quota limit |
| **SSE-C** | Server-side | **Client provides the key** | You send the key with each request. AWS uses it and discards it. HTTPS only |
| **CSE (Client-Side)** | Client-side | **Client encrypts before** | You encrypt before uploading to S3. S3 stores already-encrypted data |

> **Exam keys:**
> - **SSE-S3** is the default since January 2023 (all new objects are automatically encrypted).
> - **SSE-KMS** when you need **auditing** of who uses the keys or **separation of responsibilities**.
> - **SSE-C** when you need full control of the keys and don't want to store them in AWS.
> - **Bucket policy** can force a specific encryption type (`s3:x-amz-server-side-encryption`).

---

## Storage Gateway Types

| Type | Description |
|------|-------------|
| **S3 File Gateway** | NFS/SMB interface that stores files as objects in S3 — local access with cloud backend |
| **FSx File Gateway** | Local cache for accessing FSx for Windows File Server — optimizes latency for remote offices |
| **Volume Gateway (Stored)** | iSCSI volumes with primary data on-prem and async snapshots to S3 (as EBS Snapshots) |
| **Volume Gateway (Cached)** | iSCSI volumes with primary data in S3 and local cache of frequent data — expands capacity |
| **Tape Gateway** | Emulates a tape library (VTL) for existing backup software, stores in S3 and Glacier |

> **Exam trick:**
> - "Migrate tape backups to the cloud" → **Tape Gateway**
> - "NFS access to S3 from on-prem" → **S3 File Gateway**
> - "Primary data in the cloud, local cache" → **Volume Gateway (Cached)**
> - "Primary data on-prem, backup in the cloud" → **Volume Gateway (Stored)**

---

## Snow Family

| Device | Storage Capacity | Compute | Use Case |
|--------|-----------------|---------|----------|
| **Snowcone** | 8 TB HDD / 14 TB SSD | 2 vCPUs, 4 GB RAM | Lightweight edge computing, remote environments, small transfers |
| **Snowball Edge Storage Optimized** | 80 TB usable | 40 vCPUs, 80 GB RAM | Large-scale data migration, edge computing with storage |
| **Snowball Edge Compute Optimized** | 28 TB usable (+ 42 TB NVMe) | 104 vCPUs, 416 GB RAM, GPU opt. | ML at the edge, intensive field processing |
| **Snowmobile** | **100 PB** | N/A | Exabyte-scale migration (entire data center) |

> **General exam rule:**
> - Transfer **up to ~10 TB** → use internet (Direct Connect, VPN, S3 Transfer Acceleration)
> - Transfer **10 TB - 10 PB** → **Snowball Edge**
> - Transfer **more than 10 PB** → **Snowmobile**
> - **Remote edge computing** → Snowcone (small) or Snowball Edge Compute (powerful)

---

## Quick Decision Summary - Storage

```
EXAM QUESTION                                  → ANSWER
──────────────────────────────────────────────────────────────
"Store objects with HTTP access"                → S3
"High-performance disk for EC2"                 → EBS (gp3 or io2)
"Shared Linux file system"                      → EFS
"Shared Windows file system"                    → FSx for Windows
"HPC high-performance filesystem"               → FSx for Lustre
"Long-term archival, lowest cost"               → S3 Glacier Deep Archive
"Unpredictable access pattern"                  → S3 Intelligent-Tiering
"Migrate TBs of data from on-prem"              → Snowball Edge
"NFS access to S3 from on-prem"                 → S3 File Gateway
"Tape backups to the cloud"                     → Tape Gateway
"Guaranteed IOPS > 16,000"                      → EBS io2/io1
"High sequential throughput, big data"          → EBS st1
```
