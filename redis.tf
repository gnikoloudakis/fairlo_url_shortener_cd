# ---------- Random Redis password ----------
resource "random_password" "redis_pass" {
  length  = 32
  special = false
  upper   = true
  lower   = true
}

# ---------- Redis Replication Group with password ----------
resource "aws_elasticache_subnet_group" "redis" {
  name = "redis-subnet"
  subnet_ids = [
    aws_subnet.vpc_private_subnet_1.id,
    aws_subnet.vpc_private_subnet_2.id
  ]
}

# ---------- New dedicated Redis SG ----------
resource "aws_security_group" "redis_sg" {
  vpc_id = aws_vpc.my_aws_vpc.id
  name   = "redis-sg"
}

# ---------- Allow ECS -> Redis traffic ----------
resource "aws_security_group_rule" "redis_ingress_from_ecs" {
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  security_group_id        = aws_security_group.redis_sg.id
  source_security_group_id = aws_security_group.ecs_security_group.id
}
resource "aws_security_group_rule" "redis_egress_to_ecs" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.redis_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow Redis to respond to any request"
}


resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "tf-rep-group-1"
  description          = "Redis with password"
  node_type            = "cache.t2.micro"
  num_cache_clusters   = 1
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [aws_security_group.redis_sg.id]
  engine_version       = "6.x"

  transit_encryption_enabled = true
  # auth_token                 = random_password.redis_pass.result
  auth_token                 = var.REDIS_HOST_PASSWORD
  auth_token_update_strategy = "ROTATE"
}
