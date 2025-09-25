# ECS Cluster
resource "aws_ecs_cluster" "ECS_cluster" {
  name = "ecs-cluster"

  tags = {
    Name = "ECSCluster"
  }
}


# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "service_log_group" {
  name              = "/service/log-group"
  retention_in_days = 7

  tags = {
    Name = "Service/LogGroup"
  }
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
          name = "REDIS_HOST_PASSWORD"
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

