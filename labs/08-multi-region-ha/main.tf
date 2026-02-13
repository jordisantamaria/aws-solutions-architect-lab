# =============================================================================
# Lab 08: Multi-Region High Availability with Automatic Failover
# =============================================================================
# Architecture:
#   Route53 Failover -> Primary (eu-west-1) + Secondary (us-east-1)
#   Each region: ALB + ASG + Aurora
#   Aurora Global Database for cross-region replication
#   S3 Cross-Region Replication
# =============================================================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# =============================================================================
# Provider Configuration - Two Regions
# =============================================================================

provider "aws" {
  alias  = "primary"
  region = var.primary_region
}

provider "aws" {
  alias  = "secondary"
  region = var.secondary_region
}

# Default provider (primary region)
provider "aws" {
  region = var.primary_region
}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "primary" {
  provider = aws.primary
  state    = "available"
}

data "aws_availability_zones" "secondary" {
  provider = aws.secondary
  state    = "available"
}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# =============================================================================
# VPC - Primary Region (eu-west-1)
# =============================================================================

resource "aws_vpc" "primary" {
  provider             = aws.primary
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "${var.project_name}-primary-vpc"
    Project = var.project_name
    Region  = var.primary_region
  }
}

# Public subnets in primary region (for ALB)
resource "aws_subnet" "primary_public" {
  provider          = aws.primary
  count             = 2
  vpc_id            = aws_vpc.primary.id
  cidr_block        = cidrsubnet("10.0.0.0/16", 8, count.index)
  availability_zone = data.aws_availability_zones.primary.names[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project_name}-primary-public-${count.index + 1}"
    Project = var.project_name
  }
}

# Private subnets in primary region (for EC2 + Aurora)
resource "aws_subnet" "primary_private" {
  provider          = aws.primary
  count             = 2
  vpc_id            = aws_vpc.primary.id
  cidr_block        = cidrsubnet("10.0.0.0/16", 8, count.index + 10)
  availability_zone = data.aws_availability_zones.primary.names[count.index]

  tags = {
    Name    = "${var.project_name}-primary-private-${count.index + 1}"
    Project = var.project_name
  }
}

# Internet Gateway for primary region
resource "aws_internet_gateway" "primary" {
  provider = aws.primary
  vpc_id   = aws_vpc.primary.id

  tags = {
    Name    = "${var.project_name}-primary-igw"
    Project = var.project_name
  }
}

# Route table for primary public subnets
resource "aws_route_table" "primary_public" {
  provider = aws.primary
  vpc_id   = aws_vpc.primary.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.primary.id
  }

  tags = {
    Name    = "${var.project_name}-primary-public-rt"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "primary_public" {
  provider       = aws.primary
  count          = 2
  subnet_id      = aws_subnet.primary_public[count.index].id
  route_table_id = aws_route_table.primary_public.id
}

# =============================================================================
# VPC - Secondary Region (us-east-1)
# =============================================================================

resource "aws_vpc" "secondary" {
  provider             = aws.secondary
  cidr_block           = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "${var.project_name}-secondary-vpc"
    Project = var.project_name
    Region  = var.secondary_region
  }
}

# Public subnets in secondary region
resource "aws_subnet" "secondary_public" {
  provider          = aws.secondary
  count             = 2
  vpc_id            = aws_vpc.secondary.id
  cidr_block        = cidrsubnet("10.1.0.0/16", 8, count.index)
  availability_zone = data.aws_availability_zones.secondary.names[count.index]

  map_public_ip_on_launch = true

  tags = {
    Name    = "${var.project_name}-secondary-public-${count.index + 1}"
    Project = var.project_name
  }
}

# Private subnets in secondary region
resource "aws_subnet" "secondary_private" {
  provider          = aws.secondary
  count             = 2
  vpc_id            = aws_vpc.secondary.id
  cidr_block        = cidrsubnet("10.1.0.0/16", 8, count.index + 10)
  availability_zone = data.aws_availability_zones.secondary.names[count.index]

  tags = {
    Name    = "${var.project_name}-secondary-private-${count.index + 1}"
    Project = var.project_name
  }
}

# Internet Gateway for secondary region
resource "aws_internet_gateway" "secondary" {
  provider = aws.secondary
  vpc_id   = aws_vpc.secondary.id

  tags = {
    Name    = "${var.project_name}-secondary-igw"
    Project = var.project_name
  }
}

# Route table for secondary public subnets
resource "aws_route_table" "secondary_public" {
  provider = aws.secondary
  vpc_id   = aws_vpc.secondary.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.secondary.id
  }

  tags = {
    Name    = "${var.project_name}-secondary-public-rt"
    Project = var.project_name
  }
}

resource "aws_route_table_association" "secondary_public" {
  provider       = aws.secondary
  count          = 2
  subnet_id      = aws_subnet.secondary_public[count.index].id
  route_table_id = aws_route_table.secondary_public.id
}

# =============================================================================
# Security Groups - Primary Region
# =============================================================================

resource "aws_security_group" "primary_alb" {
  provider    = aws.primary
  name_prefix = "${var.project_name}-primary-alb-"
  vpc_id      = aws_vpc.primary.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-primary-alb-sg"
    Project = var.project_name
  }
}

resource "aws_security_group" "primary_app" {
  provider    = aws.primary
  name_prefix = "${var.project_name}-primary-app-"
  vpc_id      = aws_vpc.primary.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.primary_alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-primary-app-sg"
    Project = var.project_name
  }
}

resource "aws_security_group" "primary_db" {
  provider    = aws.primary
  name_prefix = "${var.project_name}-primary-db-"
  vpc_id      = aws_vpc.primary.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.primary_app.id]
  }

  tags = {
    Name    = "${var.project_name}-primary-db-sg"
    Project = var.project_name
  }
}

# =============================================================================
# Security Groups - Secondary Region
# =============================================================================

resource "aws_security_group" "secondary_alb" {
  provider    = aws.secondary
  name_prefix = "${var.project_name}-secondary-alb-"
  vpc_id      = aws_vpc.secondary.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-secondary-alb-sg"
    Project = var.project_name
  }
}

resource "aws_security_group" "secondary_app" {
  provider    = aws.secondary
  name_prefix = "${var.project_name}-secondary-app-"
  vpc_id      = aws_vpc.secondary.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.secondary_alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-secondary-app-sg"
    Project = var.project_name
  }
}

resource "aws_security_group" "secondary_db" {
  provider    = aws.secondary
  name_prefix = "${var.project_name}-secondary-db-"
  vpc_id      = aws_vpc.secondary.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.secondary_app.id]
  }

  tags = {
    Name    = "${var.project_name}-secondary-db-sg"
    Project = var.project_name
  }
}

# =============================================================================
# ALB - Primary Region
# =============================================================================

resource "aws_lb" "primary" {
  provider           = aws.primary
  name               = "${var.project_name}-primary-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.primary_alb.id]
  subnets            = aws_subnet.primary_public[*].id

  tags = {
    Name    = "${var.project_name}-primary-alb"
    Project = var.project_name
  }
}

resource "aws_lb_target_group" "primary" {
  provider = aws.primary
  name     = "${var.project_name}-primary-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.primary.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 10
  }

  tags = {
    Project = var.project_name
  }
}

resource "aws_lb_listener" "primary" {
  provider          = aws.primary
  load_balancer_arn = aws_lb.primary.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.primary.arn
  }
}

# =============================================================================
# ALB - Secondary Region
# =============================================================================

resource "aws_lb" "secondary" {
  provider           = aws.secondary
  name               = "${var.project_name}-secondary-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.secondary_alb.id]
  subnets            = aws_subnet.secondary_public[*].id

  tags = {
    Name    = "${var.project_name}-secondary-alb"
    Project = var.project_name
  }
}

resource "aws_lb_target_group" "secondary" {
  provider = aws.secondary
  name     = "${var.project_name}-secondary-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.secondary.id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 10
  }

  tags = {
    Project = var.project_name
  }
}

resource "aws_lb_listener" "secondary" {
  provider          = aws.secondary
  load_balancer_arn = aws_lb.secondary.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.secondary.arn
  }
}

# =============================================================================
# ASG - Primary Region
# =============================================================================

# Latest Amazon Linux 2023 AMI in primary region
data "aws_ami" "primary_al2023" {
  provider    = aws.primary
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "primary" {
  provider      = aws.primary
  name_prefix   = "${var.project_name}-primary-"
  image_id      = data.aws_ami.primary_al2023.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.primary_app.id]

  # Simple web server to show region information
  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
    AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
    echo "<h1>Primary Region: ${var.primary_region}</h1><p>Instance: $INSTANCE_ID</p><p>AZ: $AZ</p>" > /var/www/html/index.html
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "${var.project_name}-primary-instance"
      Project = var.project_name
    }
  }
}

resource "aws_autoscaling_group" "primary" {
  provider            = aws.primary
  name_prefix         = "${var.project_name}-primary-"
  vpc_zone_identifier = aws_subnet.primary_private[*].id
  target_group_arns   = [aws_lb_target_group.primary.arn]
  min_size            = 1
  max_size            = 3
  desired_capacity    = 1

  launch_template {
    id      = aws_launch_template.primary.id
    version = "$Latest"
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }
}

# =============================================================================
# ASG - Secondary Region
# =============================================================================

# Latest Amazon Linux 2023 AMI in secondary region
data "aws_ami" "secondary_al2023" {
  provider    = aws.secondary
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "secondary" {
  provider      = aws.secondary
  name_prefix   = "${var.project_name}-secondary-"
  image_id      = data.aws_ami.secondary_al2023.id
  instance_type = "t3.micro"

  vpc_security_group_ids = [aws_security_group.secondary_app.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
    AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)
    echo "<h1>Secondary Region: ${var.secondary_region}</h1><p>Instance: $INSTANCE_ID</p><p>AZ: $AZ</p>" > /var/www/html/index.html
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "${var.project_name}-secondary-instance"
      Project = var.project_name
    }
  }
}

resource "aws_autoscaling_group" "secondary" {
  provider            = aws.secondary
  name_prefix         = "${var.project_name}-secondary-"
  vpc_zone_identifier = aws_subnet.secondary_private[*].id
  target_group_arns   = [aws_lb_target_group.secondary.arn]
  min_size            = 1
  max_size            = 3
  desired_capacity    = 1

  launch_template {
    id      = aws_launch_template.secondary.id
    version = "$Latest"
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }
}

# =============================================================================
# Aurora Global Database
# =============================================================================
# Global database spans both regions with async replication (<1s lag).
# Primary cluster handles writes, secondary cluster handles reads.

resource "aws_rds_global_cluster" "main" {
  global_cluster_identifier = "${var.project_name}-global-db"
  engine                    = "aurora-mysql"
  engine_version            = "8.0.mysql_aurora.3.04.0"
  database_name             = "appdb"
  storage_encrypted         = true
}

# DB subnet group in primary region
resource "aws_db_subnet_group" "primary" {
  provider   = aws.primary
  name       = "${var.project_name}-primary-db-subnet"
  subnet_ids = aws_subnet.primary_private[*].id

  tags = {
    Name    = "${var.project_name}-primary-db-subnet"
    Project = var.project_name
  }
}

# Aurora cluster - Primary (writer)
resource "aws_rds_cluster" "primary" {
  provider                  = aws.primary
  cluster_identifier        = "${var.project_name}-primary-cluster"
  global_cluster_identifier = aws_rds_global_cluster.main.id
  engine                    = aws_rds_global_cluster.main.engine
  engine_version            = aws_rds_global_cluster.main.engine_version
  database_name             = "appdb"
  master_username           = "admin"
  master_password           = "ChangeMe123!" # Use Secrets Manager in production
  db_subnet_group_name      = aws_db_subnet_group.primary.name
  vpc_security_group_ids    = [aws_security_group.primary_db.id]
  skip_final_snapshot       = true

  tags = {
    Name    = "${var.project_name}-primary-cluster"
    Project = var.project_name
  }
}

# Aurora instance in primary cluster
resource "aws_rds_cluster_instance" "primary" {
  provider             = aws.primary
  identifier           = "${var.project_name}-primary-instance-1"
  cluster_identifier   = aws_rds_cluster.primary.id
  instance_class       = "db.r6g.large"
  engine               = aws_rds_global_cluster.main.engine
  engine_version       = aws_rds_global_cluster.main.engine_version
  db_subnet_group_name = aws_db_subnet_group.primary.name

  tags = {
    Name    = "${var.project_name}-primary-db-instance"
    Project = var.project_name
  }
}

# DB subnet group in secondary region
resource "aws_db_subnet_group" "secondary" {
  provider   = aws.secondary
  name       = "${var.project_name}-secondary-db-subnet"
  subnet_ids = aws_subnet.secondary_private[*].id

  tags = {
    Name    = "${var.project_name}-secondary-db-subnet"
    Project = var.project_name
  }
}

# Aurora cluster - Secondary (read replica)
resource "aws_rds_cluster" "secondary" {
  provider                  = aws.secondary
  cluster_identifier        = "${var.project_name}-secondary-cluster"
  global_cluster_identifier = aws_rds_global_cluster.main.id
  engine                    = aws_rds_global_cluster.main.engine
  engine_version            = aws_rds_global_cluster.main.engine_version
  db_subnet_group_name      = aws_db_subnet_group.secondary.name
  vpc_security_group_ids    = [aws_security_group.secondary_db.id]
  skip_final_snapshot       = true

  # Secondary cluster does not need master credentials
  # It replicates from the primary automatically

  depends_on = [aws_rds_cluster_instance.primary]

  tags = {
    Name    = "${var.project_name}-secondary-cluster"
    Project = var.project_name
  }
}

# Aurora instance in secondary cluster
resource "aws_rds_cluster_instance" "secondary" {
  provider             = aws.secondary
  identifier           = "${var.project_name}-secondary-instance-1"
  cluster_identifier   = aws_rds_cluster.secondary.id
  instance_class       = "db.r6g.large"
  engine               = aws_rds_global_cluster.main.engine
  engine_version       = aws_rds_global_cluster.main.engine_version
  db_subnet_group_name = aws_db_subnet_group.secondary.name

  tags = {
    Name    = "${var.project_name}-secondary-db-instance"
    Project = var.project_name
  }
}

# =============================================================================
# Route53 - Health Check and Failover Records
# =============================================================================
# Health check monitors the primary ALB. If it fails, Route53 routes
# traffic to the secondary region automatically.

resource "aws_route53_health_check" "primary" {
  fqdn              = aws_lb.primary.dns_name
  port               = 80
  type               = "HTTP"
  resource_path      = "/"
  failure_threshold  = 3
  request_interval   = 10

  tags = {
    Name    = "${var.project_name}-primary-health-check"
    Project = var.project_name
  }
}

# Route53 hosted zone (must exist or be created)
resource "aws_route53_zone" "main" {
  name = var.domain_name

  tags = {
    Project = var.project_name
  }
}

# Primary failover record - routes to primary ALB when healthy
resource "aws_route53_record" "primary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.${var.domain_name}"
  type    = "A"

  failover_routing_policy {
    type = "PRIMARY"
  }

  alias {
    name                   = aws_lb.primary.dns_name
    zone_id                = aws_lb.primary.zone_id
    evaluate_target_health = true
  }

  set_identifier  = "primary"
  health_check_id = aws_route53_health_check.primary.id
}

# Secondary failover record - routes to secondary ALB when primary is unhealthy
resource "aws_route53_record" "secondary" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.${var.domain_name}"
  type    = "A"

  failover_routing_policy {
    type = "SECONDARY"
  }

  alias {
    name                   = aws_lb.secondary.dns_name
    zone_id                = aws_lb.secondary.zone_id
    evaluate_target_health = true
  }

  set_identifier = "secondary"
}

# =============================================================================
# S3 Cross-Region Replication
# =============================================================================
# Source bucket in primary region replicates to destination bucket
# in secondary region. Requires versioning on both buckets.

# Source bucket (primary region)
resource "aws_s3_bucket" "primary" {
  provider      = aws.primary
  bucket        = "${var.project_name}-primary-${local.account_id}"
  force_destroy = true

  tags = {
    Name    = "${var.project_name}-primary-bucket"
    Project = var.project_name
  }
}

resource "aws_s3_bucket_versioning" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Destination bucket (secondary region)
resource "aws_s3_bucket" "secondary" {
  provider      = aws.secondary
  bucket        = "${var.project_name}-secondary-${local.account_id}"
  force_destroy = true

  tags = {
    Name    = "${var.project_name}-secondary-bucket"
    Project = var.project_name
  }
}

resource "aws_s3_bucket_versioning" "secondary" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.secondary.id
  versioning_configuration {
    status = "Enabled"
  }
}

# IAM role for S3 replication
resource "aws_iam_role" "s3_replication" {
  name = "${var.project_name}-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Project = var.project_name
  }
}

# Policy allowing S3 to replicate objects between buckets
resource "aws_iam_role_policy" "s3_replication" {
  name = "${var.project_name}-s3-replication"
  role = aws_iam_role.s3_replication.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.primary.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Resource = "${aws_s3_bucket.primary.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = "${aws_s3_bucket.secondary.arn}/*"
      }
    ]
  })
}

# Replication configuration on the source bucket
resource "aws_s3_bucket_replication_configuration" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id
  role     = aws_iam_role.s3_replication.arn

  rule {
    id     = "replicate-all"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.secondary.arn
      storage_class = "STANDARD"
    }
  }

  # Versioning must be enabled before replication
  depends_on = [
    aws_s3_bucket_versioning.primary,
    aws_s3_bucket_versioning.secondary
  ]
}
