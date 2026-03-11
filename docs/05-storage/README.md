# Storage in AWS

## Table of Contents

- [Storage Types: Block vs File vs Object](#storage-types-block-vs-file-vs-object)
- [Amazon S3](#amazon-s3)
- [S3 Storage Classes](#s3-storage-classes)
- [S3 Features](#s3-features)
- [S3 Performance](#s3-performance)
- [S3 Access Control](#s3-access-control)
- [S3 Event Notifications](#s3-event-notifications)
- [Amazon EBS](#amazon-ebs)
- [Amazon EFS](#amazon-efs)
- [Amazon FSx](#amazon-fsx)
- [AWS Storage Gateway](#aws-storage-gateway)
- [AWS Snow Family](#aws-snow-family)
- [AWS DataSync vs Transfer Family](#aws-datasync-vs-transfer-family)
- [Exam Tips](#exam-tips)

---

## Storage Types: Block vs File vs Object

Before looking at individual services, it is essential to understand the three storage models because the exam asks which one to use in each scenario.

| | Block Storage | File Storage | Object Storage |
|---|---|---|---|
| **Analogy** | A hard drive connected to your PC | A shared network folder (NAS) | A package warehouse with labels |
| **Unit** | Byte blocks (like disk sectors) | Files organized in directories | Objects with key + metadata |
| **Access** | Direct, byte by byte | By hierarchical path (NFS/SMB) | By HTTP (GET/PUT) |
| **Partial modification** | Yes (change 1 byte) | Yes (edit a file) | **No** (rewrite the entire object) |
| **Latency** | Sub-millisecond | Milliseconds | Milliseconds to hundreds of ms |
| **The OS sees it as** | A local disk (applies its filesystem: NTFS, ext4) | A network mount point | Not mounted; accessed by API |
| **Use case** | Databases, trading apps, boot volumes | Shared files, home dirs, CMS | Backups, media, data lakes, web assets |
| **AWS services** | **EBS**, FSx for NetApp ONTAP (iSCSI) | **EFS** (NFS), **FSx** (SMB/NFS) | **S3** |

### Why the Distinction Matters for the Exam

```
Transactional app (DB, trading)  ->  needs to read/write individual blocks fast
                                 ->  Block Storage (EBS or iSCSI)

Files shared between servers     ->  needs paths /data/report.pdf accessible by multiple servers
                                 ->  File Storage (EFS or FSx)

Store millions of objects        ->  no need for partial editing, infinite scale
                                 ->  Object Storage (S3)
```

> **Exam tip:** If the scenario says "low-latency block storage" shared multi-AZ, EBS doesn't work (it's single-AZ). The answer is **FSx for NetApp ONTAP with iSCSI**, which exposes block storage over the network accessible from multiple AZs. If it only says "block storage single-AZ", the answer is **EBS**.

---

## Amazon S3

Amazon Simple Storage Service (S3) is an object storage service that offers industry-leading scalability, data availability, security, and performance.

**Key concepts:**

- **Buckets**: Object containers. Globally unique names.
- **Objects**: Stored files. Maximum object size: **5 TB**. For uploads larger than 5 GB, multipart upload must be used.
- **Key**: Full path of the object (prefix + name).
- There is no concept of real "directories", only prefixes in the key.

---

## S3 Storage Classes

| Class | Durability | Availability | AZs | Latency | Relative Cost | Use Case |
|---|---|---|---|---|---|---|
| **S3 Standard** | 99.999999999% (11 9s) | 99.99% | >= 3 | ms | $$$$$ | Frequently accessed data |
| **S3 Intelligent-Tiering** | 99.999999999% | 99.9% | >= 3 | ms | $$$$$ (+ monitoring fee) | Unpredictable access patterns |
| **S3 Standard-IA** | 99.999999999% | 99.9% | >= 3 | ms | $$$$ | Infrequently accessed data, fast access needed |
| **S3 One Zone-IA** | 99.999999999% | 99.5% | 1 | ms | $$$ | Infrequently accessed data, recreatable |
| **S3 Glacier Instant Retrieval** | 99.999999999% | 99.9% | >= 3 | ms | $$$ | Archives accessed once/quarter, immediate access |
| **S3 Glacier Flexible Retrieval** | 99.999999999% | 99.99% (after restore) | >= 3 | min-hrs | $$ | Archives with flexible retrieval |
| **S3 Glacier Deep Archive** | 99.999999999% | 99.99% (after restore) | >= 3 | hrs | $ | Long-term retention (7-10 years) |

### Intelligent-Tiering Details

Automatically moves objects between tiers without performance impact or retrieval charges:

- **Frequent Access tier**: Normal access (default).
- **Infrequent Access tier**: Objects not accessed in 30 days.
- **Archive Instant Access tier**: Objects not accessed in 90 days.
- **Archive Access tier** (optional): Objects not accessed in 90-730 days.
- **Deep Archive Access tier** (optional): Objects not accessed in 180-730 days.

### Glacier Retrieval Times

| Class | Expedited | Standard | Bulk |
|---|---|---|---|
| **Glacier Flexible Retrieval** | 1-5 min | 3-5 hrs | 5-12 hrs |
| **Glacier Deep Archive** | Not available | 12 hrs | 48 hrs |

**Detail of each retrieval type:**
```
Expedited:  1-5 minutes, up to 150 MB/s throughput
            Warning: Without provisioned capacity -> may fail under high demand
            With provisioned capacity -> GUARANTEED always available

Standard:   3-5 hours, for non-urgent data

Bulk:       5-12 hours, cheapest, for large volumes without urgency
```

**Provisioned Retrieval Capacity:**
```
Problem: Expedited retrieval uses AWS shared capacity
         During high-demand periods, your request may be rejected

Solution: You purchase "provisioned capacity" (~$100/month per unit)
          -> Guarantees Expedited ALWAYS works
          -> Each unit = 3 retrievals every 5 min + 150 MB/s throughput

When to use it:
  - Compliance that requires guaranteed access ("under all circumstances")
  - Surprise audits that need data in minutes
  - Strict data recovery SLA
```

> **Key for the exam**: Glacier Instant Retrieval offers millisecond access. Glacier Flexible Retrieval requires prior restoration. Deep Archive is the cheapest option but with retrieval times of hours. If the question asks for guaranteed access in minutes "under all circumstances" -> Expedited + Provisioned Retrieval Capacity.

---

## S3 Features

### Versioning

- Enabled at the bucket level.
- Each object has a **Version ID**.
- Protects against accidental deletions (deletes create a **delete marker**).
- Previous versions can be restored by removing the delete marker.
- Once enabled, it can only be suspended, **not disabled**.
- Objects prior to enabling have Version ID = `null`.

### Lifecycle Policies

Allow automating the transition between storage classes or object expiration:

- **Transition actions**: Move objects to another class after X days.
- **Expiration actions**: Delete objects after X days.
- Can be applied to specific prefixes or tags.
- Can be applied to current and/or previous versions.

**Allowed transition rules:**

```
Standard -> Standard-IA -> Intelligent-Tiering -> One Zone-IA
    |                                               |
Glacier Instant -> Glacier Flexible -> Glacier Deep Archive
```

> **Key**: Minimum 30 days in Standard before transitioning to Standard-IA or One Zone-IA. Minimum 30 additional days before transitioning to Glacier.

### Replication

| Feature | CRR (Cross-Region Replication) | SRR (Same-Region Replication) |
|---|---|---|
| **Regions** | Different regions | Same region |
| **Use case** | Compliance, lower latency, cross-account replication | Log aggregation, production/test cross-account replication |
| **Requirements** | Versioning enabled on source and destination | Versioning enabled on source and destination |

**Important notes about replication:**

- Only new objects are replicated after enabling the rule.
- To replicate existing objects, use **S3 Batch Replication**.
- Delete markers are **not replicated** by default (can be enabled).
- There is no chain replication (A -> B -> C: objects replicated to B are not replicated to C).

### Encryption

| Method | Key Management | When to Use |
|---|---|---|
#### Server-Side Encryption (SSE) -- AWS encrypts after receiving the object

| Method | Who manages the key | Does data travel unencrypted to AWS? | Key in AWS? |
|---|---|---|---|
| **SSE-S3** | AWS completely (AES-256) | Yes (encrypted in transit by HTTPS, but AWS sees them) | Yes |
| **SSE-KMS** | AWS KMS (you control the key policy) | Yes | Yes |
| **SSE-C** | You provide the key in each request | Yes (HTTPS only) | Not stored (AWS uses it and discards it) |

```
Client  ---- plaintext object (HTTPS) ---->  S3  --> encrypts with the key --> stores encrypted
```

In all three SSE cases, AWS receives the object unencrypted (protected by HTTPS in transit) and encrypts it before writing to disk.

#### Client-Side Encryption -- The client encrypts BEFORE sending

| Variant | Master key | Does master key leave the client? | Does unencrypted data reach AWS? |
|---|---|---|---|
| **Client-Side with KMS key** | AWS KMS generates the data key | Yes (you request the data key from KMS via API) | **No** |
| **Client-Side with client-side master key** | You manage it locally | **No** (never leaves your environment) | **No** |

```
Client-Side with KMS:
Client --> requests data key from KMS --> encrypts locally --> uploads encrypted to S3

Client-Side with client master key:
Client --> generates data key with its local master key --> encrypts locally --> uploads encrypted to S3
                (the master key NEVER leaves the client)
```

**With client-side encryption the object in S3 is unreadable.** It cannot be viewed from the AWS console, nor with direct bucket access. To read it you must download it and decrypt it with the corresponding master key.

**How it works (envelope encryption):**
1. The SDK generates a random **data key** for each object.
2. Encrypts the object with that data key.
3. Encrypts the data key with the **master key** (KMS or local).
4. Uploads the encrypted object + the encrypted data key as metadata (`x-amz-meta-x-amz-key`).
5. To read: download, decrypt the data key with the master key, decrypt the object with the data key.

> If you lose the master key, **you lose the data forever**. AWS cannot help you.

#### When to Use Each Method (for the exam)

| Scenario Requirement | Method |
|---|---|
| No special requirements, basic encryption | **SSE-S3** (default) |
| Key usage auditing with CloudTrail | **SSE-KMS** |
| "The customer must control the key" but accepts AWS encrypting | **SSE-C** |
| "Data must not reach AWS unencrypted" | **Client-Side** |
| "The master key must not leave the customer's environment / must not go to AWS" | **Client-Side with client-side master key** |
| "Neither unencrypted data nor master key should reach AWS" | **Client-Side with client-side master key** |

> **Key for the exam**: SSE-KMS has a KMS API quota limit (5,500-30,000 requests/s depending on region). For massive workloads, consider SSE-S3 or S3 Bucket Keys (reduces KMS calls by 99%).

**Default encryption:**
- Since January 2023, SSE-S3 is automatically applied to all new objects.
- SSE-KMS can be enforced via bucket policy denying uploads without the correct header.

### Object Lock and Glacier Vault Lock

**S3 Object Lock** (requires versioning):
- **Retention mode - Compliance**: Nobody can delete or modify the retention, not even the root user.
- **Retention mode - Governance**: Only users with special permissions can modify the retention.
- **Legal Hold**: Protects the object indefinitely, independent of the retention period. Can be set/removed with `s3:PutObjectLegalHold` permission.

**Glacier Vault Lock**: Vault policy that once locked cannot be modified. Ideal for compliance (WORM - Write Once Read Many).

### S3 Server Access Logging

- Logs all requests made to an S3 bucket.
- Logs are stored in **another S3 bucket** (never in the same bucket, to avoid infinite loops).
- Information included: requester, bucket name, request time, action, response status, **error code**, **referrer**, turnaround time.
- **Not real-time**: Logs can take hours to appear (best-effort delivery).
- Cannot be sent directly to CloudWatch Logs (unlike CloudTrail).

**S3 Server Access Logging vs CloudTrail Data Events:**

| Feature | S3 Server Access Logging | CloudTrail Data Events |
|---------------|-------------------------|----------------------|
| **Latency** | Hours (best-effort) | Minutes (~15 min) |
| **Extra fields** | Referrer, turnaround time, error code, bytes sent | Principal ARN, source IP, request parameters |
| **Destination** | Another S3 bucket | S3, CloudWatch Logs, EventBridge |
| **Cost** | Free (you only pay for the log storage) | Cost per event ($0.10 per 100,000 events) |
| **Use case** | Detailed access auditing, HTTP error analysis | Security auditing, compliance, real-time alerts |

> **Exam tip:** If the question asks for "detailed auditing with referrer and error codes" -> **S3 Server Access Logging**. If it asks for "real-time alerts on S3 access" -> **CloudTrail Data Events + EventBridge**.

### Minimum Duration Charges by Storage Class

AWS charges a **minimum duration** when using certain S3 classes. If you delete or move an object before that period, you pay for the full period anyway:

| Class | Minimum Billing Duration |
|---|---|
| **S3 Standard** | No minimum |
| **S3 Standard-IA** | **30 days** |
| **S3 One Zone-IA** | **30 days** |
| **S3 Glacier Instant Retrieval** | **90 days** |
| **S3 Glacier Flexible Retrieval** | **90 days** |
| **S3 Glacier Deep Archive** | **180 days** |

**Impact on Lifecycle Policies:**
- You cannot transition from Standard to Standard-IA before **30 days** (AWS prevents it).
- You can transition from Standard to Glacier Flexible directly **with no minimum days**.
- **Exam trap**: If a question proposes "Standard-IA after 7 days", it is incorrect (violates the 30-day minimum). But "Glacier Flexible after 7 days" is valid.

> **Exam tip:** Remember: Standard-IA and One Zone-IA -> minimum 30 days. Glacier -> minimum 90 days. Deep Archive -> minimum 180 days. Lifecycle transitions must respect these minimums.

### Presigned URLs

- Temporary URLs that grant access to a private object.
- Generated with the SDK or CLI.
- Configurable expiration: default **3600 seconds** (1 hour), maximum 168 hours with CLI.
- The accessor inherits the permissions of the user who generated the URL.
- Use case: temporarily share private files, allow temporary uploads.

---

## S3 Performance

### Performance Baseline

- **3,500 PUT/COPY/POST/DELETE** requests per second per prefix.
- **5,500 GET/HEAD** requests per second per prefix.
- No limit on the number of prefixes.

### Multipart Upload

- **Recommended** for files > 100 MB.
- **Mandatory** for files > 5 GB.
- Parallelizes the upload by splitting the file into parts.
- If one part fails, only that part is re-uploaded.

### S3 Transfer Acceleration

- Uses CloudFront edge locations to accelerate long-distance transfers.
- The file is uploaded to the nearest edge and then travels through AWS's internal network to the bucket.
- Compatible with multipart upload.
- Additional cost; useful when users are far from the bucket's region.

### S3 Byte-Range Fetches

- Parallelizes GETs by requesting specific byte ranges.
- Better resilience against failures (a specific range can be retried).
- Use case: download only the first N bytes (e.g., header of a file).

### S3 Select and Glacier Select

- Allow using SQL to filter data directly in S3.
- Reduces data transfer by up to **80%** and cost by up to **400%**.
- Filters rows and columns of CSV, JSON or Parquet files.
- Progressively being replaced by S3 Object Lambda for more complex transformations.

---

## S3 Access Control

### Bucket Policies

- JSON-based policies applied to the bucket.
- Allow cross-account access.
- Use cases: enforce encryption, grant public access, require MFA for delete.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyUnencryptedUploads",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::my-bucket/*",
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

- Legacy mechanism, **AWS recommends disabling them**.
- At bucket or object level.
- Since April 2023, new buckets have ACLs disabled by default (BucketOwnerEnforced).

### S3 Access Points

- Simplify access management for shared datasets.
- Each access point has its own DNS and policy.
- Can be restricted to a specific VPC (VPC origin).
- Use case: different teams need access to different prefixes of the same bucket.

### S3 Object Lambda

- Allows transforming data on the fly during a GET request.
- Uses Lambda functions to modify the object before returning it.
- Use cases: redact PII data, convert formats, resize images, enrich data.

---

## S3 Event Notifications

Notifications can be sent when events occur in the bucket (e.g., `s3:ObjectCreated:*`, `s3:ObjectRemoved:*`):

| Destination | Notes |
|---|---|
| **Amazon SNS** | Requires SNS Resource Policy allowing S3 to publish |
| **Amazon SQS** | Requires SQS Resource Policy allowing S3 to send messages |
| **AWS Lambda** | Requires Lambda Resource Policy allowing S3 to invoke |
| **Amazon EventBridge** | Enabled at bucket level. Allows advanced rules, multiple destinations, archiving, replay |

> **Key for the exam**: EventBridge offers advanced filtering (JSON rules), multiple destinations and archive/replay capabilities that the other destinations do not have.

---

## Amazon EBS

Amazon Elastic Block Store provides block storage volumes for EC2 instances.

**Key features:**

- Tied to a **specific AZ** (to move between AZs, create snapshot and restore).
- Can only be attached to instances in the same AZ.
- Billed by provisioned capacity.
- Allows changing type and size on the fly (with limitations).

### EBS Volume Types

| Type | Category | Max IOPS | Max Throughput | Size | Use Case |
|---|---|---|---|---|---|
| **gp3** | SSD General Purpose | 16,000 | 1,000 MB/s | 1 GB - 16 TB | Boot volumes, interactive apps, dev/test |
| **gp2** | SSD General Purpose | 16,000 (burst) | 250 MB/s | 1 GB - 16 TB | Boot volumes (legacy, burst IOPS) |
| **io2 Block Express** | SSD Provisioned IOPS | 256,000 | 4,000 MB/s | 4 GB - 64 TB | Critical workloads, high-performance databases |
| **io2** | SSD Provisioned IOPS | 64,000 | 1,000 MB/s | 4 GB - 16 TB | Databases with consistent IOPS requirements |
| **io1** | SSD Provisioned IOPS | 64,000 | 1,000 MB/s | 4 GB - 16 TB | Similar to io2 (legacy) |
| **st1** | HDD Throughput Optimized | 500 | 500 MB/s | 125 GB - 16 TB | Big data, data warehouses, log processing |
| **sc1** | HDD Cold | 250 | 250 MB/s | 125 GB - 16 TB | Infrequently accessed data, minimum cost |

**Important notes:**

- Only **gp2, gp3, io1, io2** can be boot volumes.
- **gp2**: IOPS scale with volume size (3 IOPS per GB, minimum 100, maximum 16,000). Burst up to 3,000 IOPS for volumes < 1 TB.
- **gp3**: IOPS and throughput are configured **independently** of size. Base: 3,000 IOPS and 125 MB/s included.
- **io1/io2**: Maximum IOPS:GB ratio is 50:1 (io1) and 500:1 (io2).

### EBS Snapshots

- Incremental copy of the volume at a point in time.
- Stored in S3 (managed by AWS).
- Not necessary to detach the volume, but recommended.
- Can be copied between regions and accounts.

**Snapshot features:**

- **EBS Snapshot Archive**: Move snapshot to a 75% cheaper tier. Restoration takes 24-72 hours.
- **Recycle Bin**: Protection against accidental deletion. Configurable from 1 day to 1 year.
- **Fast Snapshot Restore (FSR)**: Eliminates latency on first access. Expensive ($$$).

### EBS Encryption

- AES-256 encryption with KMS keys.
- Encrypts data at rest, data in transit (between instance and volume), snapshots and volumes created from encrypted snapshots.
- Minimal impact on latency.
- To encrypt an existing unencrypted volume:
  1. Create a snapshot of the volume.
  2. Copy the snapshot enabling encryption.
  3. Create a new volume from the encrypted snapshot.

### EBS Multi-Attach

- Only available for **io1/io2** volumes.
- Allows attaching a volume to **up to 16 EC2 instances** in the **same AZ**.
- Each instance has read and write permissions.
- Requires a cluster-aware filesystem (e.g., GFS2, not ext4/XFS).
- Use case: high-availability cluster applications.

---

## Amazon EFS

Amazon Elastic File System is a managed NFS file system that can be mounted on multiple EC2 instances simultaneously.

**Main features:**

- Works **cross-AZ** (unlike EBS).
- Only compatible with **Linux** instances (based on POSIX/NFS v4.1).
- Scales automatically (pay per use, no capacity provisioning).
- Can grow up to **petabytes**.
- High availability and durability.

### Performance Modes (defined at creation)

| Mode | Latency | Throughput | Use Case |
|---|---|---|---|
| **General Purpose** (default) | Low (sub-ms) | Normal | Web servers, CMS, development |
| **Max I/O** | Higher latency | Higher parallel throughput | Big data, media processing |

> **Note**: With elastic EFS, the Max I/O mode is considered legacy. AWS recommends General Purpose for most workloads.

### Throughput Modes

| Mode | Description | Use Case |
|---|---|---|
| **Bursting** | Throughput scales with filesystem size | Workloads with sporadic peaks |
| **Provisioned** | Fixed throughput independent of size | High throughput with little storage |
| **Elastic** (recommended) | Scales automatically based on load | Unpredictable workloads |

### EFS Storage Classes

| Class | Description |
|---|---|
| **Standard** | Frequent access |
| **Standard-IA** | Infrequent access, lower cost |
| **One Zone** | Single AZ, frequent access |
| **One Zone-IA** | Single AZ, infrequent access (cheapest) |

Lifecycle policies can be configured to move files between classes (e.g., move to IA after 30 days without access).

### EFS vs EBS - Comparison

| Feature | EBS | EFS |
|---|---|---|
| **Type** | Block storage | File storage (NFS) |
| **Attachment** | 1 instance (except multi-attach io1/io2) | Multiple instances |
| **Scope** | One AZ | Multi-AZ |
| **OS** | Linux and Windows | Linux only |
| **Scaling** | Fixed size (provisioned) | Automatic |
| **Performance** | Faster (directly attached) | Good for sharing |
| **Cost** | Lower (per GB provisioned) | Higher (but pay per use) |
| **Backup** | Snapshots | AWS Backup |

---

## Amazon FSx

High-performance managed file system services by AWS.

### FSx for Windows File Server

- **Protocol**: SMB (Server Message Block) and NTFS.
- Integration with **Microsoft Active Directory**.
- Supports **DFS (Distributed File System)** namespaces and replication.
- Accessible from Windows and Linux instances.
- SSD or HDD storage.
- Multi-AZ for high availability.
- Daily backups to S3.

**When to use**: Windows applications that need shared storage, home directories, Microsoft workloads.

### FSx for Lustre

- **High-performance** file system (HPC - High Performance Computing).
- Throughput of up to **hundreds of GB/s**, millions of IOPS, sub-ms latencies.
- Native integration with **S3**: can read/write data directly from/to S3.
- **Scratch**: temporary, not replicated, high performance (short processing).
- **Persistent**: long-term storage, replicated within an AZ.

**When to use**: Machine learning, HPC, video processing, financial modeling, genomic analysis.

### FSx for NetApp ONTAP

- Compatible with **NFS, SMB, iSCSI** protocols.
- Compatible with **any OS** (Linux, Windows, macOS).
- Auto-scaling storage.
- Snapshots, replication, instant cloning.
- Data compression and deduplication.
- Point-in-time cloning.
- **Multi-AZ** for high availability.

**iSCSI = block storage over network:** The iSCSI protocol makes the instance see the remote storage as a local disk (block device). This differentiates it from FSx for Windows (file/SMB only) and EFS (file/NFS only). It is the only FSx that offers **shared multi-AZ block storage**.

**When to use**: Migration of NetApp on-premises workloads, need for multi-protocol, heterogeneous environments, **shared multi-AZ block storage** (trading, Windows databases).

### FSx for OpenZFS

- Compatible with **NFS** protocol.
- Performance up to **1,000,000 IOPS** with latency < 0.5 ms.
- Snapshots, compression.
- Point-in-time cloning (useful for testing).

**When to use**: Migration of ZFS on-premises workloads, workloads requiring high performance with NFS.

### FSx Summary - When to Use Each

| Service | Protocol | OS | Primary Use Case |
|---|---|---|---|
| **FSx for Windows** | SMB | Windows (and Linux) | Active Directory, Windows apps |
| **FSx for Lustre** | POSIX | Linux | HPC, ML, massive processing |
| **FSx for NetApp ONTAP** | NFS, SMB, iSCSI | All | Multi-protocol, NetApp migration |
| **FSx for OpenZFS** | NFS | Linux | ZFS migration, high performance |

---

## AWS Storage Gateway

Hybrid storage service that connects on-premises infrastructure with AWS cloud storage. Runs as an on-premises VM or hardware appliance.

### Storage Gateway Types

| Gateway | Backend in AWS | Protocol | Local Cache | Use Case |
|---|---|---|---|---|
| **S3 File Gateway** | S3 (all classes except Glacier) | NFS, SMB | Yes | Extend file storage to S3 |
| **FSx File Gateway** | FSx for Windows | SMB | Yes | Local cache for FSx for Windows |
| **Volume Gateway - Cached** | S3 (with EBS snapshots) | iSCSI | Frequently accessed data in cache | Block volumes with local cache |
| **Volume Gateway - Stored** | S3 (with EBS snapshots) | iSCSI | All data local | Full volume backups |
| **Tape Gateway** | S3 and Glacier | iSCSI VTL | Yes | Physical tape replacement (backup) |

### S3 File Gateway -- Detail

It is a VM (or appliance) installed on-premises that exposes an **NFS/SMB** shared folder. On-premises servers see it as a normal file share, but data is stored in S3.

```
On-premises                                          AWS
+----------------------------+          +-------------------------+
|  Server --> \\gateway\docs (SMB) |          |  Amazon S3              |
|                |                   |          |  (all data)             |
|         +------v----------+        |  upload  |                         |
|         | S3 File Gateway | -----------------> |  Lifecycle Policy:      |
|         | [Local Cache]   |        |  auto    |  0-6m: S3 Standard      |
|         | SSD with recent |        |          |  6m+: Glacier           |
|         | data            |        |          +-------------------------+
|         +-----------------+        |
+------------------------------------+
```

**How the local cache works:**
- When uploading a file: saved in local cache **and** uploaded to S3 automatically.
- When reading a recent file: read from local cache (low latency, no egress cost).
- When reading an old file (not in cache): downloaded from S3 and enters cache. Subsequent reads are local.
- The cache uses LRU (Least Recently Used): evicts the least accessed files to make space.

**Benefits:**
- Employees see a normal SMB folder -- they don't know the data is in S3.
- Integrates with **Active Directory** for SMB authentication.
- **S3 Lifecycle Policies** can be applied (move to Glacier after X months).
- Reduces **data egress charges**: frequent reads are served from local cache, not from S3.

### Important Notes About Other Types

- **Volume Gateway - Cached**: Only the most accessed data is kept locally; the complete dataset is in S3.
- **Volume Gateway - Stored**: All data is on-premises with asynchronous backups to S3.
- **Tape Gateway**: Compatible with existing backup software (NetBackup, Veeam, etc.). Virtual tapes are archived in S3 Glacier or Deep Archive. iSCSI VTL protocol (not SMB/NFS).

### Storage Gateway vs DataSync

| | S3 File Gateway | DataSync |
|---|---|---|
| **Purpose** | Continuous hybrid access (on-premises <-> S3) | Data migration/synchronization (one-time or scheduled) |
| **Local cache** | **Yes** (low latency for recent data) | **No** |
| **Protocol** | NFS, SMB (like a normal file share) | Agent that transfers data |
| **Pattern** | Users access files daily | Copy/move data from A to B |

> **Key for the exam:**
> - "Local cache" + "on-premises file access" + "data in S3" -> **S3 File Gateway**.
> - "SMB + Active Directory + lifecycle to Glacier" -> **S3 File Gateway**.
> - "Backup tape migration" -> **Tape Gateway**.
> - "NFS/SMB data migration to AWS (no cache)" -> **DataSync**.

---

## AWS Snow Family

Physical devices for offline data transfer and edge computing.

| Feature | Snowcone / Snowcone SSD | Snowball Edge Storage Optimized | Snowball Edge Compute Optimized | Snowmobile |
|---|---|---|---|---|
| **Capacity** | 8 TB HDD / 14 TB SSD | 80 TB usable | 42 TB usable | 100 PB |
| **Compute** | 2 vCPU, 4 GB RAM | 40 vCPU, 80 GB RAM | 104 vCPU, 416 GB RAM (optional GPU) | No |
| **Transfer type** | Offline / DataSync (online) | Offline | Offline | Offline |
| **Use case** | Space-limited environments, lightweight edge computing | Massive data migration, edge storage | Edge HPC, ML inference | Exabyte-scale migration |
| **Weight** | ~2.1 kg | ~22 kg | ~22 kg | Full truck |

### When to Use Snow Family vs Network Transfer

**General rule**: If network transfer would take more than **1 week**, consider Snow Family.

| Data Volume | Network (100 Mbps) | Network (1 Gbps) | Network (10 Gbps) | Recommended Device |
|---|---|---|---|---|
| 10 TB | 12 days | 30 hours | 3 hours | Network if >= 1 Gbps |
| 100 TB | 120 days | 12 days | 30 hours | Snowball Edge |
| 1 PB | 3 years | 120 days | 12 days | Snowball Edge (multiple) |
| 10+ PB | 30 years | 3 years | 120 days | Snowmobile |

### Edge Computing with Snow

- EC2 instances and Lambda functions can be run (using IoT Greengrass).
- Data processing where there is no Internet connection or limited connectivity.
- Configured before shipping with AMIs and Lambda functions.

### OpsHub

- Desktop application for managing Snow devices.
- Data transfer, launching instances, monitoring.

---

## AWS DataSync vs Transfer Family

### AWS DataSync

- Service for **moving large amounts of data** between:
  - On-premises -> AWS (requires DataSync agent)
  - AWS -> AWS (between services without agent)
- **Destinations**: S3, EFS, FSx.
- **Sources**: NFS, SMB, HDFS, other AWS services.
- Schedulable tasks (not continuous).
- Preserves metadata and permissions.
- **Bandwidth**: Can consume all network or be limited.
- Encryption in transit and integrity verification.

- **Preserves metadata and permissions**: Includes NTFS permissions, timestamps, ownership. Ideal for migrating Windows file servers with their ACLs intact.
- **Transfer modes**:
  - **Transfer only data that has changed**: Only transfers new or modified files (incremental). Default.
  - **Transfer all data**: Transfers everything, useful for complete initial synchronization.

**Use case**: Data migration, DR replication, data archiving.

### AWS Transfer Family

- Managed service for file transfers to/from S3 or EFS using standard protocols:
  - **SFTP** (SSH File Transfer Protocol)
  - **FTPS** (FTP over SSL)
  - **FTP** (within VPC only)
  - **AS2** (Applicability Statement 2)
- Integration with existing authentication systems (Active Directory, LDAP, custom).
- Exposed as public or VPC endpoint.

**Use case**: Business partners who need to send/receive files using standard protocols (FTP/SFTP), B2B workflows.

### Comparison

| Feature | DataSync | Transfer Family |
|---|---|---|
| **Protocol** | Proprietary (agent) | SFTP, FTPS, FTP, AS2 |
| **Direction** | Bi-directional (batch) | Bi-directional (individual) |
| **Speed** | High (up to 10 Gbps) | Depends on the protocol |
| **Usage** | Massive migration/replication | File exchange with third parties |
| **Scheduling** | Schedulable tasks | Continuous (endpoint always active) |

---

## Exam Tips

### S3

1. **"Infrequent access but immediate"** -> S3 Standard-IA or One Zone-IA.
2. **"Unpredictable access pattern"** -> S3 Intelligent-Tiering.
3. **"Archive with millisecond access"** -> Glacier Instant Retrieval.
4. **"Long-term archive, doesn't matter waiting hours"** -> Glacier Deep Archive.
5. **"Enforce encryption"** -> Bucket policy with condition on the encryption header.
6. **"Temporarily share a file"** -> Presigned URL.
7. **"Data must be immutable (WORM)"** -> Object Lock (Compliance mode) or Glacier Vault Lock.
8. **"High volume of requests to S3"** -> Distribute objects across multiple prefixes.
9. **"Throttling with SSE-KMS"** -> Use S3 Bucket Keys or SSE-S3.
10. **"Replicate existing objects"** -> S3 Batch Replication.

### EBS

1. **"Database with high and consistent IOPS"** -> io2/io2 Block Express.
2. **"Economical boot volume"** -> gp3.
3. **"High sequential throughput (logs, big data)"** -> st1.
4. **"Cold storage, minimum cost"** -> sc1.
5. **"Share volume between instances in the same AZ"** -> Multi-Attach io1/io2.
6. **"Move volume to another AZ"** -> Snapshot + restore in another AZ.
7. **"Encrypt existing volume"** -> Snapshot -> copy with encryption -> create volume.

### EFS

1. **"Shared storage between multiple Linux instances"** -> EFS.
2. **"Shared cross-AZ storage"** -> EFS.
3. **"Windows file share"** -> NOT EFS, it's FSx for Windows.

### FSx

1. **"Windows file share with Active Directory"** -> FSx for Windows.
2. **"HPC, ML, high throughput on Linux"** -> FSx for Lustre.
3. **"Multi-protocol (NFS + SMB + iSCSI)"** -> FSx for NetApp ONTAP.
4. **"Shared multi-AZ block storage"** or **"low-latency block storage + Windows + multi-AZ"** -> FSx for NetApp ONTAP with iSCSI (not EBS, which is single-AZ).
5. **"ZFS on-premises migration"** -> FSx for OpenZFS.

### Storage Gateway

1. **"Extend on-premises storage to the cloud"** -> Storage Gateway.
2. **"Local cache + data in S3"** -> S3 File Gateway or Volume Gateway Cached.
3. **"Backup tape migration to the cloud"** -> Tape Gateway.
4. **"Low latency from on-premises to FSx"** -> FSx File Gateway.

### Snow Family

1. **"Transfer > 1 week over network"** -> Snow Family.
2. **"Edge computing without Internet"** -> Snowball Edge or Snowcone.
3. **"Exabyte migration"** -> Snowmobile.

### DataSync vs Transfer Family

1. **"Massive NFS/SMB data migration to AWS"** -> DataSync.
2. **"Business partners need SFTP/FTP"** -> Transfer Family.
