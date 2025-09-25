

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

resource "aws_security_group_rule" "alb_egress_to_ecs" {
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb_security_group.id
  source_security_group_id = aws_security_group.ecs_security_group.id
  description              = "Load balancer to target"
}

resource "aws_security_group_rule" "ecs_ingress_from_alb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_security_group.id
  source_security_group_id = aws_security_group.alb_security_group.id
  description              = "Load balancer to target"
}
# Security Group Rule: Allow HTTPS ingress to ALB
resource "aws_security_group_rule" "alb_https_ingress" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_security_group.id
}

# # Security Group Rule: Allow ECS to access Redis
# resource "aws_security_group_rule" "ecs_to_redis" {
#   type                     = "egress"
#   from_port                = 6379
#   to_port                  = 6379
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.ecs_security_group.id
#   source_security_group_id = aws_security_group.redis_sg.id
#   description              = "Allow ECS to connect to Redis"
# }