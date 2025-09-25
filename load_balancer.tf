

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
