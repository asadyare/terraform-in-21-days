# Load Balancer Security Group
resource "aws_security_group" "load_balancer" {
  name        = "${var.env_code}-load-balancer"
  description = "Allow port 80 TCP inbound to Load Balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP to load balancer"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env_code}-Load-Balancer"
  }
}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = var.env_code
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load_balancer.id]
  subnets            = var.public_subnet_ids

  tags = {
    Name = var.env_code
  }
}

# Target Group
resource "aws_lb_target_group" "main" {
  name     = var.env_code
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    path                = "/"
    port                = "80"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }

  tags = {
    Name = var.env_code
  }
}

# Listener
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# data "aws_route53_zone" "main" {
#   name         = asaddevsecopsengineer.co.za
#   }

# resource "aws_route53_record" "www" {
#   zone_id = data.aws_route53_zone.main.zone_id
#   name    = "www.${data.aws_route53_zone.main.name}"
#   type    = "CNAME"
#   ttl     = 300
#   records = [aws_lb.main.dns_name]
#   alias {
#     name                   = aws_lb.main.dns_name
#     zone_id                = aws_lb.main.zone_id
#     evaluate_target_health = true
#   }
# }
