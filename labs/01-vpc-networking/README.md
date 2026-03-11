# Lab 01: VPC Networking

## Objective

Create a production-ready VPC from scratch with public and private subnets, internet gateway, NAT gateway, route tables, NACLs and security groups. This is the network foundation on which we will build the rest of the labs.

## What you will learn

- **VPC:** Virtual Private Cloud, your isolated network in AWS
- **Subnets:** Segment the network into public (accessible from internet) and private (internal access only)
- **Internet Gateway (IGW):** Gateway for public subnets to access the internet
- **NAT Gateway:** Allows private subnets to reach the internet without being accessible from outside
- **Route Tables:** Routing rules to direct traffic
- **NACLs:** Network Access Control Lists, stateless firewall at the subnet level
- **Security Groups:** Stateful firewall at the instance/resource level

## Architecture Diagram

```
                         +------------------+
                         |    INTERNET      |
                         +--------+---------+
                                  |
                         +--------+---------+
                         | Internet Gateway |
                         +--------+---------+
                                  |
                    +-------------+-------------+
                    |                           |
           +--------+--------+        +--------+--------+
           | Public Subnet 1 |        | Public Subnet 2 |
           |   10.0.1.0/24   |        |   10.0.2.0/24   |
           |    (AZ-1)       |        |    (AZ-2)       |
           +--------+--------+        +-----------------+
                    |
              +-----+------+
              | NAT Gateway|
              +-----+------+
                    |
                    |
                    +-------------+-------------+
                    |                           |
          +---------+---------+       +---------+---------+
          | Private Subnet 1  |       | Private Subnet 2  |
          |   10.0.3.0/24     |       |   10.0.4.0/24     |
          |    (AZ-1)         |       |    (AZ-2)         |
          +-------------------+       +-------------------+

  Route Table (Public):             Route Table (Private):
    10.0.0.0/16 -> local              10.0.0.0/16 -> local
    0.0.0.0/0   -> IGW                0.0.0.0/0   -> NAT GW
```

## Deployment Steps

### 1. Initialize and apply

```bash
cd labs/01-vpc-networking

# Initialize (configure remote backend)
terraform init

# Review what will be created
terraform plan

# Apply
terraform apply
```

### 2. Verify the infrastructure

```bash
# Verify VPC
aws ec2 describe-vpcs --filters "Name=tag:Lab,Values=01-vpc-networking"

# Verify subnets
aws ec2 describe-subnets --filters "Name=tag:Lab,Values=01-vpc-networking"

# Verify Internet Gateway
aws ec2 describe-internet-gateways --filters "Name=tag:Lab,Values=01-vpc-networking"

# Verify NAT Gateway
aws ec2 describe-nat-gateways --filter "Name=tag:Lab,Values=01-vpc-networking"

# Verify Route Tables
aws ec2 describe-route-tables --filters "Name=tag:Lab,Values=01-vpc-networking"
```

### 3. Check connectivity (optional)

Launch an EC2 instance in the public subnet and another in the private subnet. Verify that:
- The public instance has internet access
- The private instance can reach the internet (through the NAT Gateway) but is not accessible from outside

---

## Extra Exercises

### Exercise 1: VPC Peering

Create a second VPC (10.1.0.0/16) and establish peering between both. Add the necessary routes so that instances in both VPCs can communicate.

### Exercise 2: VPC Endpoint for S3

Create a Gateway VPC Endpoint for S3, so that traffic to S3 from private subnets does not go through the NAT Gateway (cost savings and better performance).

```hcl
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${var.region}.s3"
  route_table_ids = [aws_route_table.private.id]
}
```

### Exercise 3: Flow Logs

Enable VPC Flow Logs to capture network traffic and send it to CloudWatch Logs.

---

## Estimated Cost

| Resource | Cost |
|---------|-------|
| VPC, Subnets, IGW, Route Tables | Free |
| NAT Gateway | ~$0.048/hour (~$1.15/day) |
| NAT Gateway data processing | $0.048/GB |
| Elastic IP (associated with NAT) | Free (while associated) |

> **Estimated total: ~$1/day** mainly due to the NAT Gateway. Remember to run `terraform destroy` when you are not practicing.

## Cleanup

```bash
terraform destroy
```

> **Important:** Always destroy resources when you finish practicing to avoid unnecessary costs. The NAT Gateway charges per hour.

## File Structure

```
01-vpc-networking/
  main.tf          # Main resources (VPC, subnets, gateways, route tables, NACLs, SGs)
  variables.tf     # Input variables
  outputs.tf       # Output values
  backend.tf       # Remote backend configuration (S3)
  README.md        # This file
```
