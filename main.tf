resource "aws_ecr_repository" "my_ecr_repo" {
  name = "my_ecr_repo"
  # lifecycle {
  #   prevent_destroy = true
  # }
}

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Get current AWS region
data "aws_region" "current" {}

# VPC
resource "aws_vpc" "my_aws_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags = {
    Name = "VPC network for internal services to communicate securely"
  }
}

# Internet Gateway | It gives internet access to public subnets
resource "aws_internet_gateway" "vpc_igw" {
  vpc_id = aws_vpc.my_aws_vpc.id

  tags = {
    Name = "AWS internal services VPC Internet Gateway"
  }
}

# Public Subnet 1 | use two subnets for high availability
resource "aws_subnet" "vpc_public_subnet_1" {
  vpc_id                  = aws_vpc.my_aws_vpc.id
  availability_zone       = data.aws_availability_zones.available.names[0]
  cidr_block              = "10.0.0.0/18"
  map_public_ip_on_launch = true

  tags = {
    "aws-tutorial:subnet-name" = "Public"
    "aws-tutorial:subnet-type" = "Public"
    Name                       = "VPC/PublicSubnet1"
  }
}

# Public Subnet 2
resource "aws_subnet" "vpc_public_subnet_2" {
  vpc_id                  = aws_vpc.my_aws_vpc.id
  availability_zone       = data.aws_availability_zones.available.names[1]
  cidr_block              = "10.0.64.0/18"
  map_public_ip_on_launch = true

  tags = {
    "aws-tutorial:subnet-name" = "Public"
    "aws-tutorial:subnet-type" = "Public"
    Name                       = "VPC/PublicSubnet2"
  }
}

# Private Subnet 1
resource "aws_subnet" "vpc_private_subnet_1" {
  vpc_id                  = aws_vpc.my_aws_vpc.id
  availability_zone       = data.aws_availability_zones.available.names[0]
  cidr_block              = "10.0.128.0/18"
  map_public_ip_on_launch = false

  tags = {
    "aws-tutorial:subnet-name" = "Private"
    "aws-tutorial:subnet-type" = "Private"
    Name                       = "VPC/PrivateSubnet1"
  }
}

# Private Subnet 2
resource "aws_subnet" "vpc_private_subnet_2" {
  vpc_id                  = aws_vpc.my_aws_vpc.id
  availability_zone       = data.aws_availability_zones.available.names[1]
  cidr_block              = "10.0.192.0/18"
  map_public_ip_on_launch = false

  tags = {
    "aws-tutorial:subnet-name" = "Private"
    "aws-tutorial:subnet-type" = "Private"
    Name                       = "VPC/PrivateSubnet2"
  }
}

# Public Route Table 1
resource "aws_route_table" "vpc_public_subnet_1_route_table" {
  vpc_id = aws_vpc.my_aws_vpc.id

  tags = {
    Name = "VPC/PublicSubnet1/RouteTable"
  }
}

# Public Route Table 2
resource "aws_route_table" "vpc_public_subnet_2_route_table" {
  vpc_id = aws_vpc.my_aws_vpc.id

  tags = {
    Name = "VPC/PublicSubnet2/RouteTable"
  }
}

# Private Route Table 1
resource "aws_route_table" "vpc_private_subnet_1_route_table" {
  vpc_id = aws_vpc.my_aws_vpc.id

  tags = {
    Name = "VPC/PrivateSubnet1/RouteTable"
  }
}

# Private Route Table 2
resource "aws_route_table" "vpc_private_subnet_2_route_table" {
  vpc_id = aws_vpc.my_aws_vpc.id

  tags = {
    Name = "VPC/PrivateSubnet2/RouteTable"
  }
}

# Route Table Associations
resource "aws_route_table_association" "vpc_public_subnet_1_route_table_association" {
  route_table_id = aws_route_table.vpc_public_subnet_1_route_table.id
  subnet_id      = aws_subnet.vpc_public_subnet_1.id
}

resource "aws_route_table_association" "vpc_public_subnet_2_route_table_association" {
  route_table_id = aws_route_table.vpc_public_subnet_2_route_table.id
  subnet_id      = aws_subnet.vpc_public_subnet_2.id
}

resource "aws_route_table_association" "vpc_private_subnet_1_route_table_association" {
  route_table_id = aws_route_table.vpc_private_subnet_1_route_table.id
  subnet_id      = aws_subnet.vpc_private_subnet_1.id
}

resource "aws_route_table_association" "vpc_private_subnet_2_route_table_association" {
  route_table_id = aws_route_table.vpc_private_subnet_2_route_table.id
  subnet_id      = aws_subnet.vpc_private_subnet_2.id
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "vpc_public_subnet_1_eip" {
  domain = "vpc"

  tags = {
    Name = "VPC/PublicSubnet1/ElasticIP"
  }

  depends_on = [aws_internet_gateway.vpc_igw]
}

resource "aws_eip" "vpc_public_subnet_2_eip" {
  domain = "vpc"

  tags = {
    Name = "VPC/PublicSubnet2/ElasticIP"
  }

  depends_on = [aws_internet_gateway.vpc_igw]
}

# NAT Gateways
resource "aws_nat_gateway" "vpc_public_subnet_1_nat_gateway" {
  subnet_id     = aws_subnet.vpc_public_subnet_1.id
  allocation_id = aws_eip.vpc_public_subnet_1_eip.id

  tags = {
    Name = "VPC/PublicSubnet1/NATGateway"
  }

  depends_on = [aws_internet_gateway.vpc_igw]
}

resource "aws_nat_gateway" "vpc_public_subnet_2_nat_gateway" {
  subnet_id     = aws_subnet.vpc_public_subnet_2.id
  allocation_id = aws_eip.vpc_public_subnet_2_eip.id

  tags = {
    Name = "VPC/PublicSubnet2/NATGateway"
  }

  depends_on = [aws_internet_gateway.vpc_igw]
}

# Routes
resource "aws_route" "vpc_public_subnet_1_default_route" {
  route_table_id         = aws_route_table.vpc_public_subnet_1_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.vpc_igw.id
}

resource "aws_route" "vpc_public_subnet_2_default_route" {
  route_table_id         = aws_route_table.vpc_public_subnet_2_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.vpc_igw.id
}

resource "aws_route" "vpc_private_subnet_1_default_route" {
  route_table_id         = aws_route_table.vpc_private_subnet_1_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.vpc_public_subnet_1_nat_gateway.id
}

resource "aws_route" "vpc_private_subnet_2_default_route" {
  route_table_id         = aws_route_table.vpc_private_subnet_2_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.vpc_public_subnet_2_nat_gateway.id
}

# ECS Cluster
resource "aws_ecs_cluster" "ECS_cluster" {
  name = "ecs-cluster"

  tags = {
    Name = "ECSCluster"
  }
}

# Application Load Balancer Security Group
resource "aws_security_group" "alb_security_group" {
  name_prefix = "security-group-alb-"
  description = "Security group for the ALB"
  vpc_id      = aws_vpc.my_aws_vpc.id

  ingress {
    description = "Allow from anyone on port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ALB/SecurityGroup"
  }
}

# ECS Service Security Group
resource "aws_security_group" "ecs_security_group" {
  name_prefix = "security-group-ecs-"
  description = "Security group for the ECS service"
  vpc_id      = aws_vpc.my_aws_vpc.id

  egress {
    description = "Allow all outbound traffic by default"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ECS/SecurityGroup"
  }
}

resource "aws_security_group_rule" "alb_to_ecs" {
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb_security_group.id
  source_security_group_id = aws_security_group.ecs_security_group.id
  description              = "Load balancer to target"
}

resource "aws_security_group_rule" "ecs_from_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_security_group.id
  source_security_group_id = aws_security_group.alb_security_group.id
  description              = "Load balancer to target"
}
# # Security Group Rule: Allow HTTPS ingress to ALB
# resource "aws_security_group_rule" "alb_https_ingress" {
#   type              = "ingress"
#   from_port         = 443
#   to_port           = 443
#   protocol          = "tcp"
#   cidr_blocks       = ["0.0.0.0/0"]
#   security_group_id = aws_security_group.alb_security_group.id
# }

# Security Group Rule: Allow ECS to access Redis
resource "aws_security_group_rule" "ecs_to_redis" {
  type                          = "egress"
  from_port                     = 6379
  to_port                       = 6379
  protocol                      = "tcp"
  security_group_id             = aws_security_group.ecs_security_group.id
  source_security_group_id = aws_security_group.redis_sg.id
  description                   = "Allow ECS to connect to Redis"
}

# Application Load Balancer
resource "aws_lb" "application_lb" {
  name               = "application-lb"
  load_balancer_type = "application"
  internal           = false

  enable_deletion_protection = false

  security_groups = [aws_security_group.alb_security_group.id]
  subnets = [
    aws_subnet.vpc_public_subnet_1.id,
    aws_subnet.vpc_public_subnet_2.id
  ]

  tags = {
    Name = "ALB"
  }
}

# ALB Target Group
resource "aws_lb_target_group" "alb_target_group" {
  name        = "alb-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.my_aws_vpc.id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/"
    matcher             = "200"
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  tags = {
    Name = "ALB/TargetGroup"
  }
}

# ALB Listener
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.application_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
}

# resource "aws_lb_listener" "alb_https_listener" {
#   load_balancer_arn = aws_lb.applications_lb.arn
#   port              = "443"
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
#   certificate_arn   = aws_acm_certificate.cert.arn  # You'd need to create this
#
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.alb_targets_group.arn
#   }
# }

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "service_log_group" {
  name              = "/service/log-group"
  retention_in_days = 7

  tags = {
    Name = "Service/LogGroup"
  }
}

# ECS Task Execution Role
resource "aws_iam_role" "task_def_execution_role" {
  name = "task-def-execution-role"

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
    Name = "IAM/TaskDef/ExecutionRole"
  }
}

# ECS Task Role
resource "aws_iam_role" "service_task_def_task_role" {
  name = "service-task-role"

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
    Name = "IAM/TaskDef/TaskRole"
  }
}

resource "aws_iam_role_policy" "service_task_role_policy" {
  name = "service-task-role-policy"
  role = aws_iam_role.service_task_def_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "elasticache:DescribeCacheClusters",
          "elasticache:DescribeReplicationGroups"
        ]
        Effect   = "Allow"
        Resource = aws_elasticache_replication_group.redis.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_execution_role_policy" {
  role       = aws_iam_role.task_def_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Policy for ECS Task Execution Role
resource "aws_iam_role_policy" "service_task_def_execution_role_policy" {
  name = "service-task-def-execution-role-policy"
  role = aws_iam_role.task_def_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = aws_cloudwatch_log_group.service_log_group.arn
      }
    ]
  })
}

# ECS Task Definition
resource "aws_ecs_task_definition" "td_url_shortener" {
  family                   = "url-shortener-task-def"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.task_def_execution_role.arn
  task_role_arn            = aws_iam_role.service_task_def_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "web"
      image     = "${aws_ecr_repository.my_ecr_repo.repository_url}:${var.service_version_tag}"
      essential = true

      # Environment variables for Redis connection
      environment = [
        {
          name  = "REDIS_HOST"
          value = aws_elasticache_replication_group.redis.primary_endpoint_address # should be the primary endpoint for non clustered redis
        },
        {
          name  = "REDIS_PORT"
          value = "6379"
        },
        {
          name  = "REDIS_HOST_PASSWORD"
          # value = random_password.redis_pass.result
          value = var.REDIS_HOST_PASSWORD
        },
        {
          name  = "REDIS_TLS_ENABLED"
          value = "true"
        }
      ]

      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.service_log_group.name
          "awslogs-stream-prefix" = "sce-logs"
          "awslogs-region"        = data.aws_region.current.id
        }
      }
    }
  ])

  tags = {
    Name = "URLShortener/TaskDefinition"
  }
}

# ECS Service
resource "aws_ecs_service" "url_shortener_ecs_service" {
  name            = "url-shortener-service"
  cluster         = aws_ecs_cluster.ECS_cluster.id
  task_definition = aws_ecs_task_definition.td_url_shortener.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  # deployment_configuration {
  #   maximum_percent         = 200
  #   minimum_healthy_percent = 50
  # }

  network_configuration {
    assign_public_ip = false
    security_groups = [
      aws_security_group.ecs_security_group.id
    ]
    subnets = [
      aws_subnet.vpc_private_subnet_1.id,
      aws_subnet.vpc_private_subnet_2.id
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.alb_target_group.arn
    container_name   = "web"
    container_port   = 80
  }

  health_check_grace_period_seconds = 60
  enable_ecs_managed_tags           = false

  depends_on = [
    aws_lb_listener.alb_listener,
    aws_iam_role_policy.service_task_def_execution_role_policy
  ]

  tags = {
    Name = "URLShortener/ECSService"
  }
}

