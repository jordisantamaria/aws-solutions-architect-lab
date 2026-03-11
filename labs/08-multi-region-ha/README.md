# Lab 08: Multi-Region High Availability with Automatic Failover

## Objective

Design and deploy a multi-region architecture with automatic failover using Route53, Aurora Global Database and S3 Cross-Region Replication. This is one of the most important patterns for the SA exam.

## Architecture

```
                         +------------------+
                         |    Route 53      |
                         |  Failover DNS    |
                         |                  |
                         +-----+-------+----+
                               |       |
                    PRIMARY    |       |    SECONDARY
                    (active)   |       |    (passive)
                               v       v
              +--------------------+  +--------------------+
              |   eu-west-1        |  |   us-east-1        |
              |                    |  |                    |
              |  +--------------+  |  |  +--------------+  |
              |  |     ALB      |  |  |  |     ALB      |  |
              |  +------+-------+  |  |  +------+-------+  |
              |         |          |  |         |          |
              |  +------v-------+  |  |  +------v-------+  |
              |  |     ASG      |  |  |  |     ASG      |  |
              |  |  (t3.micro)  |  |  |  |  (t3.micro)  |  |
              |  +------+-------+  |  |  +------+-------+  |
              |         |          |  |         |          |
              |  +------v-------+  |  |  +------v-------+  |
              |  | Aurora       |<-+--+--| Aurora       |  |
              |  | Primary      |--+--+->| Read Replica |  |
              |  | (writer)     |  |  |  | (reader)     |  |
              |  +--------------+  |  |  +--------------+  |
              |                    |  |                    |
              |  +--------------+  |  |  +--------------+  |
              |  |  S3 Bucket   |--+--+->|  S3 Bucket   |  |
              |  |  (source)    |  |  |  |  (replica)   |  |
              |  +--------------+  |  |  +--------------+  |
              +--------------------+  +--------------------+
                                  ^
                       Aurora Global Database
                       (async replication <1s)
```

## What you will learn

- **Multi-Region Architecture**: deploy identical infrastructure in two regions
- **Route53 Failover Routing**: automatic DNS failover based on health checks
- **Aurora Global Database**: database replication between regions with <1 second latency
- **S3 Cross-Region Replication (CRR)**: automatic object replication between buckets
- **DR Strategies**: differences between Backup/Restore, Pilot Light, Warm Standby and Multi-Site
- **Terraform Multi-Provider**: use of provider aliases to deploy in multiple regions

## Disaster Recovery Strategies

| Strategy | RPO | RTO | Cost | This Lab |
|------------|-----|-----|-------|----------|
| Backup & Restore | Hours | Hours | $ | No |
| Pilot Light | Minutes | Minutes | $$ | No |
| Warm Standby | Seconds | Minutes | $$$ | **Yes** |
| Multi-Site Active/Active | ~0 | ~0 | $$$$ | No |

This lab implements **Warm Standby**: minimal active infrastructure in the secondary region, ready to scale.

## Deployed Components

| Resource | Primary Region | Secondary Region |
|---------|---------------|-----------------|
| VPC + Subnets | eu-west-1 | us-east-1 |
| ALB | eu-west-1 | us-east-1 |
| ASG (t3.micro, min 1) | eu-west-1 | us-east-1 |
| Aurora Cluster | Writer | Read Replica |
| S3 Bucket | Source | CRR Replica |
| Route53 Health Check | Primary ALB | - |
| Route53 Failover | Primary record | Secondary record |

## Estimated Cost

**~$8-12/day** (duplicated infrastructure in two regions)

> **IMPORTANT**: This lab is expensive due to having active infrastructure in two regions. **DESTROY THE INFRASTRUCTURE AS SOON AS YOU FINISH**.

## How to Deploy

```bash
# Initialize Terraform
terraform init

# View the plan (observe resources in both regions)
terraform plan

# Deploy
terraform apply

# IMPORTANT: Destroy when finished
terraform destroy
```

## Testing Failover

1. **Verify that DNS resolves to the primary region**:
   ```bash
   dig +short your-domain.example.com
   ```

2. **Simulate failure** (stop instances in the primary region):
   ```bash
   # The Route53 health check will detect the failure
   # It will automatically redirect traffic to the secondary region
   ```

3. **Verify failover**:
   ```bash
   # Wait ~60 seconds for Route53 to detect the failure
   dig +short your-domain.example.com
   # Should resolve to the secondary ALB IP
   ```

## Key Concepts for the Exam

1. **Route53 Failover**: requires an active health check on the primary record
2. **Aurora Global Database**: asynchronous replication, typical RPO <1 second
3. **Aurora Failover**: the secondary replica can be promoted to primary (unplanned failover)
4. **S3 CRR**: requires versioning enabled on both buckets, asynchronous replication
5. **RTO vs RPO**: Recovery Time Objective vs Recovery Point Objective
6. **Multi-AZ vs Multi-Region**: Multi-AZ is HA, Multi-Region is DR

## Cleanup

```bash
# DESTROY IMMEDIATELY when finished
terraform destroy
```

> **Warning**: Verify in the AWS console that all resources have been deleted in BOTH regions.
