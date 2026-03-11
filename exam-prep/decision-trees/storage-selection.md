# Decision Tree: Storage Selection

## Main Question: What type of storage do you need?

```
What type of data do you need to store?
│
├── OBJECTS / FILES (HTTP access, no file system)
│   │
│   └──→ Amazon S3
│        │
│        ├── How frequently do you access the data?
│        │   │
│        │   ├── Frequently ──→ S3 Standard
│        │   │
│        │   ├── Unpredictable pattern ──→ S3 Intelligent-Tiering
│        │   │
│        │   ├── Infrequently
│        │   │   ├── Recreatable data? ──→ S3 One Zone-IA (cheaper, 1 AZ)
│        │   │   └── Critical data?   ──→ S3 Standard-IA (multi-AZ)
│        │   │
│        │   └── Archival / long-term
│        │       ├── Occasional instant access? ──→ Glacier Instant Retrieval
│        │       ├── Access in hours, flexible?     ──→ Glacier Flexible Retrieval
│        │       └── 7-10+ year retention, rarely? ──→ Glacier Deep Archive
│        │
│        └── Additional features:
│            ├── Object versioning ──→ S3 Versioning
│            ├── Automatically move data ──→ S3 Lifecycle Policies
│            ├── Cross-region replication ──→ S3 CRR
│            └── Query data without extracting ──→ S3 Select / Athena
│
├── BLOCK STORAGE (disk for EC2 instance)
│   │
│   └──→ Amazon EBS
│        │
│        ├── What type of workload?
│        │   │
│        │   ├── General (boot, dev, normal apps)
│        │   │   └──→ gp3 (more flexible and economical than gp2)
│        │   │
│        │   ├── High IOPS (> 16,000) / critical databases
│        │   │   ├── Up to 64,000 IOPS? ──→ io2
│        │   │   └── Up to 256,000 IOPS? ──→ io2 Block Express
│        │   │
│        │   ├── High sequential throughput (big data, logs)
│        │   │   └──→ st1 (Throughput Optimized HDD)
│        │   │
│        │   └── Cold data, minimal access, lowest cost
│        │       └──→ sc1 (Cold HDD)
│        │
│        └── Notes:
│            ├── Boot volume? ──→ SSD only (gp2/gp3/io1/io2)
│            ├── Multi-attach (multiple instances)? ──→ io1/io2 only
│            └── Snapshot? ──→ Yes, to S3 (incremental)
│
├── SHARED FILE SYSTEM (multiple instances)
│   │
│   ├── What operating system?
│   │   │
│   │   ├── Linux (NFS)
│   │   │   └──→ Amazon EFS
│   │   │       ├── Frequent access ──→ EFS Standard
│   │   │       ├── Infrequent access ──→ EFS-IA (cheaper)
│   │   │       └── Both automatically ──→ EFS Lifecycle Management
│   │   │
│   │   └── Windows (SMB)
│   │       └──→ Amazon FSx for Windows File Server
│   │           (Active Directory, DFS, quotas)
│   │
│   └── HPC / high-performance parallel?
│       └──→ Amazon FSx for Lustre
│           ├── Integrates with S3 as data lake
│           └── Ideal for ML, simulations, genomics
│
├── ARCHIVAL / REGULATORY RETENTION
│   │
│   ├── Immediate access needed? ──→ S3 Glacier Instant Retrieval
│   ├── Access in minutes/hours?    ──→ S3 Glacier Flexible Retrieval
│   └── Minimum cost, rare access?  ──→ S3 Glacier Deep Archive
│       └── S3 Object Lock for WORM compliance (Write Once Read Many)
│
└── HYBRID STORAGE (on-premises + cloud)
    │
    └──→ AWS Storage Gateway
         │
         ├── What do you need?
         │   │
         │   ├── NFS/SMB access to S3 from on-prem
         │   │   └──→ S3 File Gateway
         │   │
         │   ├── Local cache for FSx Windows
         │   │   └──→ FSx File Gateway
         │   │
         │   ├── iSCSI volumes
         │   │   ├── Primary data on-prem ──→ Volume Gateway (Stored)
         │   │   └── Primary data in S3   ──→ Volume Gateway (Cached)
         │   │
         │   └── Migrate tape backups
         │       └──→ Tape Gateway (Virtual Tape Library)
         │
         └── Massive data migration?
             ├── < 10 TB ──→ Internet / DataSync / Direct Connect
             ├── 10 TB - 10 PB ──→ Snowball Edge
             └── > 10 PB ──→ Snowmobile
```

---

## Decision Summary Table

| If you need... | Use... | Because... |
|----------------|--------|-----------|
| Store files/objects | S3 | Unlimited object storage, 11 nines of durability |
| High-performance disk | EBS gp3/io2 | Block storage attached to EC2, configurable IOPS |
| Share files between EC2 (Linux) | EFS | Managed NFS, auto-scaling, multi-AZ |
| Share files between EC2 (Windows) | FSx for Windows | Native SMB, Active Directory |
| HPC / ML filesystem | FSx for Lustre | Massive parallel performance, S3 integration |
| Cheap archival | Glacier Deep Archive | Lowest cost per GB in AWS |
| Connect on-prem to S3 | S3 File Gateway | Familiar interface (NFS/SMB) with S3 backend |
| Migrate data massively | Snow Family | Physical transfer when internet is slow |

---

## Exam Keywords → Service

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
