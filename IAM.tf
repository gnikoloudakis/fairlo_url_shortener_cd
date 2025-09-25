

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

# resource "aws_iam_role_policy" "service_task_role_policy" {
#   name = "service-task-role-policy"
#   role = aws_iam_role.service_task_def_task_role.id
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "elasticache:DescribeCacheClusters",
#           "elasticache:DescribeReplicationGroups"
#         ]
#         Effect   = "Allow"
#         Resource = aws_elasticache_replication_group.redis.arn
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "task_execution_role_policy" {
#   role       = aws_iam_role.task_def_execution_role.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
# }

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
