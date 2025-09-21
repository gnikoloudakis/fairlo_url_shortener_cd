output "redis_endpoint" {
  description = "Redis primary endpoint"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "redis_password" {
  description = "Redis password"
  value       = random_password.redis_pass.result
  sensitive   = true
}

output "public_api_url" {
  description = "Public API URL accessible from internet"
  value       = "http://${aws_lb.application_lb.dns_name}"
}

output "alb_dns_name" {
  description = "ALB DNS name"
  value       = aws_lb.application_lb.dns_name
}