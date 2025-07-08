resource aws_security_group otel_sg {
  name              = "otel-collector-sg"
  description       = "Allow OTLP traffic"
  vpc_id            = var.vpc_id
  ingress {
    description     = "Allow OTLP Health Checks"
    from_port       = 13133
    to_port         = 13133
    protocol        = "tcp"
    cidr_blocks     = var.cidr_ranges
  }
  ingress {
    description     = "Allow OTLP HTTP"
    from_port       = 4318
    to_port         = 4318
    protocol        = "tcp"
    cidr_blocks     = var.cidr_ranges
  }
  ingress {
    description     = "Allow OTLP gRPC"
    from_port       = 4317
    to_port         = 4317
    protocol        = "tcp"
    cidr_blocks     = var.cidr_ranges
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
        "cloudwatch:PutMetricData",
        "xray:PutTraceSegments",
        "xray:PutTelemetryRecords",
        "xray:GetSamplingRules",
        "xray:GetSamplingTargets",
        "xray:GetSamplingStatisticSummaries"
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
      { containerPort = 13133, protocol = "tcp" }, # Health check endpoint
      { containerPort = 4317,  protocol = "tcp" }, # gRPC endpoint
      { containerPort = 4318,  protocol = "tcp" }  # HTTP (Protobuf) endpoint
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
  desired_count                 = 2
  launch_type                   = "FARGATE"
  network_configuration {
    subnets                     = var.subnets
    security_groups             = [aws_security_group.otel_sg.id]
    assign_public_ip            = false
  }

// todo - debug stuff below this point
  load_balancer {
    target_group_arn = aws_lb_target_group.otel_lb_tg.arn
    container_name = "otel-collector"
    container_port = 4318 # HTTP (Protobuf)
  }
}

resource aws_lb otel_lb {
  name               = "otel-collector-lb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.otel_sg.id]
  subnets            = var.subnets
  tags = {
    Name = "otel-collector-lb"
  }
}

resource aws_lb_target_group otel_lb_tg {
  name     = "otel-collector-lb-target-group"
  port     = 4318 # HTTP (Protobuf)
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  target_type = "ip"
  health_check {
    protocol            = "HTTP"
    port                = 13133 # otel collector's default health check port
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  tags = {
    Name = "otel-collector-lb-target-group"
  }
}

resource aws_lb_listener otel_lb_listener {
  load_balancer_arn = aws_lb.otel_lb.arn
  port              = 4318 # HTTP (Protobuf)
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.otel_lb_tg.arn
  }
}

# manually created this zone via the AWS console - using data source to reference it from here (within the Terraform)
data aws_route53_zone ea_nonprod_zone {
  name         = "ea-nonprod.idexx.com"
}

# this record creates an intelligible DNS name for our OpenTelemetry Collector's load balancer, so we don't have to
# rely on the auto-generated DNS name that AWS provides
resource aws_route53_record otel_alias {
  zone_id = data.aws_route53_zone.ea_nonprod_zone.zone_id
  name    = "otel-collector"
  type    = "A"
  alias {
    name                   = aws_lb.otel_lb.dns_name
    zone_id                = aws_lb.otel_lb.zone_id
    evaluate_target_health = true
  }
}
