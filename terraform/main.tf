locals {
  ecr_image = "${var.aws_account}.dkr.ecr.${var.aws_region}.amazonaws.com/otel-collector:latest"
}

terraform {
  required_providers {
    aws = {
      source        = "hashicorp/aws"
      version       = "~> 5.97.0"
    }
  }
  backend s3 {
    bucket          = "fargate-ecr-otel-poc-tfstate"
    key             = "terraform.tfstate"
    region          = "us-east-1"
    encrypt         = false
  }
}

provider aws {
  region            = var.aws_region
}

resource aws_security_group otel_sg {
  name              = "otel-collector-sg"
  description       = "Allow OTLP traffic"
  vpc_id            = var.vpc_id
  ingress {
    description     = "Allow OTLP HTTP"
    from_port       = 4318
    to_port         = 4318
    protocol        = "tcp"
    cidr_blocks     = var.vpc_cidr_ranges
  }
  ingress {
    description     = "Allow OTLP gRPC"
    from_port       = 4317
    to_port         = 4317
    protocol        = "tcp"
    cidr_blocks     = var.vpc_cidr_ranges
  }
  egress {
    description     = "Allow all outbound traffic"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  tags = {
    Name            = "otel-collector-sg"
  }
}

resource aws_ecs_cluster otel_cluster {
  name              = "otel-collector-cluster"
}

resource aws_cloudwatch_log_group otel_log_group {
  name              = "fargate-ecr-otel-poc-logs"
  retention_in_days = 1
}

resource aws_iam_role execution_role {
  name = "otel-execution-role"
  assume_role_policy= jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource aws_iam_role task_role {
  name = "otel-task-role"
  assume_role_policy  = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# Policy which gives permission to create logs and metrics within CloudWatch
resource aws_iam_policy otel_policy {
  name = "otel-cloudwatch-access"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
        Effect = "Allow",
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "cloudwatch:PutMetricData"
        ],
        Resource = "*"
      }]
  })
}

# Attaches AWS' built-in ECS task execution role policy to the execution role
resource aws_iam_role_policy_attachment execution_role_attachment {
  role        = aws_iam_role.execution_role.name
  policy_arn  = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Attaches above policy (for creating stuff in CloudWatch) to the task role
resource aws_iam_policy_attachment attach_task_policy {
  name        = "otel-task-policy-attach"
  roles       = [aws_iam_role.task_role.name]
  policy_arn  = aws_iam_policy.otel_policy.arn
}

# This is the task definition used by ECS to launch our OpenTelemetry Collector
resource aws_ecs_task_definition otel_task {
  family                   = "otel-collector"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn = aws_iam_role.execution_role.arn
  task_role_arn = aws_iam_role.task_role.arn
  container_definitions = jsonencode([{
      name = "otel-collector",
      image = local.ecr_image,
      essential = true,
      portMappings = [
        { containerPort = 4317, protocol = "tcp" }, # gRPC endpoint
        { containerPort = 4318, protocol = "tcp" }  # HTTP (Protobuf) endpoint
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group = aws_cloudwatch_log_group.otel_log_group.name,
          awslogs-region = var.aws_region,
          awslogs-stream-prefix = "otel"
        }
      }
    }])
}

resource aws_ecs_service otel_service {
  name                          = "otel-collector-service"
  cluster                       = aws_ecs_cluster.otel_cluster.id
  task_definition               = aws_ecs_task_definition.otel_task.arn
  desired_count                 = 1
  launch_type                   = "FARGATE"
  network_configuration {
    subnets                     = var.subnets
    security_groups             = [aws_security_group.otel_sg.id]
    assign_public_ip            = true
  }
}