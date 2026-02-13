# ============================================================================
# Lab 02: Web Server with High Availability
# ALB + Auto Scaling Group + EC2 instances in private subnets
# ============================================================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# AWS Provider configuration
provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
      Lab         = "02-web-server"
    }
  }
}

# ============================================================================
# Remote State Data Source
# Reads outputs from Lab 01 (VPC, subnets, security groups)
# ============================================================================

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "aws-lab-dev-terraform-state"
    key    = "lab-01-vpc-networking/terraform.tfstate"
    region = var.region
  }
}

# Fetch the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
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

# ============================================================================
# Security Groups
# ============================================================================

# ALB Security Group: allows HTTP from the internet
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Security group for the Application Load Balancer"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-alb-sg"
  }
}

# EC2 Security Group: allows HTTP only from the ALB security group
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-${var.environment}-ec2-sg"
  description = "Security group for EC2 instances (allows traffic only from ALB)"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    description     = "HTTP from ALB only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all outbound (needed for package installation)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-sg"
  }
}

# ============================================================================
# Launch Template
# Defines the EC2 instance configuration used by the Auto Scaling Group
# ============================================================================

resource "aws_launch_template" "web" {
  name_prefix   = "${var.project_name}-${var.environment}-web-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type

  # User data script to install and configure nginx
  user_data = base64encode(file("${path.module}/user_data.sh"))

  vpc_security_group_ids = [aws_security_group.ec2.id]

  # Enable detailed monitoring for better scaling decisions
  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-${var.environment}-web"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ============================================================================
# Application Load Balancer
# Distributes incoming HTTP traffic across EC2 instances
# ============================================================================

resource "aws_lb" "web" {
  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.terraform_remote_state.vpc.outputs.public_subnet_ids

  tags = {
    Name = "${var.project_name}-${var.environment}-alb"
  }
}

# Target Group: defines where the ALB sends traffic
resource "aws_lb_target_group" "web" {
  name     = "${var.project_name}-${var.environment}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.vpc.outputs.vpc_id

  # Health check configuration
  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-tg"
  }
}

# ALB Listener: routes incoming requests on port 80 to the target group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

# ============================================================================
# Auto Scaling Group
# Manages the fleet of EC2 instances
# ============================================================================

resource "aws_autoscaling_group" "web" {
  name                = "${var.project_name}-${var.environment}-asg"
  min_size            = var.min_capacity
  max_size            = var.max_capacity
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = data.terraform_remote_state.vpc.outputs.private_subnet_ids
  target_group_arns   = [aws_lb_target_group.web.arn]

  # Use the latest version of the launch template
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  # Wait for instances to pass ELB health check before considering them healthy
  health_check_type         = "ELB"
  health_check_grace_period = 300

  # Instance refresh: gradually replace instances when launch template changes
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-web"
    propagate_at_launch = true
  }
}

# ============================================================================
# Auto Scaling Policy
# Target Tracking: automatically adjusts capacity to maintain 60% CPU
# ============================================================================

resource "aws_autoscaling_policy" "cpu_target_tracking" {
  name                   = "${var.project_name}-${var.environment}-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0

    # Disable scale in to prevent aggressive downscaling (optional)
    # disable_scale_in = true
  }
}
