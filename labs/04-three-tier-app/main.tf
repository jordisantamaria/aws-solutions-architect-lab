# =============================================================================
# Lab 04: Three-Tier Architecture
# ALB (public) -> ECS Fargate (private) -> Aurora PostgreSQL + ElastiCache Redis
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

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      Lab         = "04-three-tier-app"
      ManagedBy   = "terraform"
    }
  }
}

# -----------------------------------------------------------------------------
# Remote State: Read VPC outputs from Lab 01
# -----------------------------------------------------------------------------
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "aws-lab-tfstate-${data.aws_caller_identity.current.account_id}"
    key    = "labs/01-vpc-networking/terraform.tfstate"
    region = var.region
  }
}

data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

# -----------------------------------------------------------------------------
# Local values
# -----------------------------------------------------------------------------
locals {
  name_prefix = "${var.project_name}-${var.environment}"

  vpc_id          = data.terraform_remote_state.vpc.outputs.vpc_id
  public_subnets  = data.terraform_remote_state.vpc.outputs.public_subnet_ids
  private_subnets = data.terraform_remote_state.vpc.outputs.private_subnet_ids
}

# =============================================================================
# SECURITY GROUPS - Layered security for each tier
# =============================================================================

# Security group for ALB: allows HTTP/HTTPS from the internet
resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = local.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-alb-sg"
  }
}

# Security group for ECS tasks: allows traffic only from ALB
resource "aws_security_group" "ecs" {
  name        = "${local.name_prefix}-ecs-sg"
  description = "Security group for ECS Fargate tasks"
  vpc_id      = local.vpc_id

  ingress {
    description     = "HTTP from ALB only"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all outbound traffic (for pulling images, etc.)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-ecs-sg"
  }
}

# Security group for Aurora: allows PostgreSQL traffic only from ECS
resource "aws_security_group" "aurora" {
  name        = "${local.name_prefix}-aurora-sg"
  description = "Security group for Aurora PostgreSQL"
  vpc_id      = local.vpc_id

  ingress {
    description     = "PostgreSQL from ECS tasks only"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-aurora-sg"
  }
}

# Security group for ElastiCache Redis: allows Redis traffic only from ECS
resource "aws_security_group" "redis" {
  name        = "${local.name_prefix}-redis-sg"
  description = "Security group for ElastiCache Redis"
  vpc_id      = local.vpc_id

  ingress {
    description     = "Redis from ECS tasks only"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-redis-sg"
  }
}

# =============================================================================
# APPLICATION LOAD BALANCER (Public Tier)
# =============================================================================

# ALB deployed in public subnets to receive internet traffic
resource "aws_lb" "main" {
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = local.public_subnets

  tags = {
    Name = "${local.name_prefix}-alb"
  }
}

# Target group for ECS Fargate tasks (IP target type required for Fargate)
resource "aws_lb_target_group" "ecs" {
  name        = "${local.name_prefix}-ecs-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200"
  }

  tags = {
    Name = "${local.name_prefix}-ecs-tg"
  }
}

# HTTP listener forwarding traffic to ECS target group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs.arn
  }
}

# =============================================================================
# ECS CLUSTER & SERVICE (Application Tier)
# =============================================================================

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${local.name_prefix}-cluster"
  }
}

# CloudWatch log group for ECS container logs
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${local.name_prefix}"
  retention_in_days = 7

  tags = {
    Name = "${local.name_prefix}-ecs-logs"
  }
}

# IAM role for ECS task execution (pulling images, writing logs)
resource "aws_iam_role" "ecs_task_execution" {
  name = "${local.name_prefix}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-ecs-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM role for the ECS task itself (application permissions)
resource "aws_iam_role" "ecs_task" {
  name = "${local.name_prefix}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-ecs-task-role"
  }
}

# ECS Task Definition for Fargate
resource "aws_ecs_task_definition" "app" {
  family                   = "${local.name_prefix}-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = var.container_image
      cpu       = 256
      memory    = 512
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]

      # Environment variables for database and cache connections
      environment = [
        {
          name  = "DB_HOST"
          value = aws_rds_cluster.aurora.endpoint
        },
        {
          name  = "DB_PORT"
          value = "5432"
        },
        {
          name  = "DB_NAME"
          value = var.db_name
        },
        {
          name  = "REDIS_HOST"
          value = aws_elasticache_cluster.redis.cache_nodes[0].address
        },
        {
          name  = "REDIS_PORT"
          value = "6379"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "app"
        }
      }
    }
  ])

  tags = {
    Name = "${local.name_prefix}-task-def"
  }
}

# ECS Service: runs and maintains desired count of Fargate tasks
resource "aws_ecs_service" "app" {
  name            = "${local.name_prefix}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = local.private_subnets
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs.arn
    container_name   = "app"
    container_port   = var.container_port
  }

  # Ensure ALB listener is created before the service
  depends_on = [aws_lb_listener.http]

  tags = {
    Name = "${local.name_prefix}-service"
  }
}

# =============================================================================
# AURORA POSTGRESQL SERVERLESS V2 (Data Tier)
# =============================================================================

# Subnet group for Aurora: places instances in private subnets
resource "aws_db_subnet_group" "aurora" {
  name        = "${local.name_prefix}-aurora-subnet-group"
  description = "Subnet group for Aurora PostgreSQL cluster"
  subnet_ids  = local.private_subnets

  tags = {
    Name = "${local.name_prefix}-aurora-subnet-group"
  }
}

# Aurora PostgreSQL Serverless v2 cluster
resource "aws_rds_cluster" "aurora" {
  cluster_identifier = "${local.name_prefix}-aurora"
  engine             = "aurora-postgresql"
  engine_mode        = "provisioned"
  engine_version     = "15.4"
  database_name      = var.db_name
  master_username    = "dbadmin"
  master_password    = "ChangeMe123!" # NOTE: In production, use Secrets Manager

  db_subnet_group_name   = aws_db_subnet_group.aurora.name
  vpc_security_group_ids = [aws_security_group.aurora.id]

  # Serverless v2 scaling configuration
  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 2.0
  }

  # Lab settings: allow easy cleanup
  skip_final_snapshot = true
  apply_immediately   = true

  tags = {
    Name = "${local.name_prefix}-aurora"
  }
}

# Aurora instance 1 (AZ-a) - Serverless v2
resource "aws_rds_cluster_instance" "aurora_instances" {
  count = 2

  identifier         = "${local.name_prefix}-aurora-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.aurora.engine
  engine_version     = aws_rds_cluster.aurora.engine_version

  # Distribute instances across availability zones
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${local.name_prefix}-aurora-instance-${count.index + 1}"
  }
}

# =============================================================================
# ELASTICACHE REDIS (Data Tier - Caching Layer)
# =============================================================================

# Subnet group for ElastiCache: places nodes in private subnets
resource "aws_elasticache_subnet_group" "redis" {
  name        = "${local.name_prefix}-redis-subnet-group"
  description = "Subnet group for ElastiCache Redis"
  subnet_ids  = local.private_subnets

  tags = {
    Name = "${local.name_prefix}-redis-subnet-group"
  }
}

# ElastiCache Redis cluster (single node for lab cost optimization)
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${local.name_prefix}-redis"
  engine               = "redis"
  engine_version       = "7.0"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  port                 = 6379
  parameter_group_name = "default.redis7"
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [aws_security_group.redis.id]

  tags = {
    Name = "${local.name_prefix}-redis"
  }
}
