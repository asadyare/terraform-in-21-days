# Load Balancer Security Group
resource "aws_security_group" "load_balancer" {
  name        = "${var.env_code}-ALB"
  description = "Allow inbound HTTP to ALB"
  vpc_id      = try(data.terraform_remote_state.level1.outputs["vpc_id"], null)

  ingress {
    description = "Allow HTTP from anywhere"
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
    Name = "${var.env_code}-ALB"
  }
}

# Application Load Balancer
resource "aws_lb" "public_alb" {
  name               = "${var.env_code}-public-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.load_balancer.id]
  subnets            = try(data.terraform_remote_state.level1.outputs["public_subnet_ids"], [])

  tags = {
    Name = "${var.env_code}-Public-ALB"
  }
}

# Target Group for EC2 instances
resource "aws_lb_target_group" "public_tg" {
  name     = "${var.env_code}-public-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = try(data.terraform_remote_state.level1.outputs["vpc_id"], null)

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name = "${var.env_code}-Public-TG"
  }
}

# Attach Public EC2 instances to Target Group
resource "aws_lb_target_group_attachment" "public_instances" {
  count            = length(aws_instance.public)
  target_group_arn = aws_lb_target_group.public_tg.arn
  target_id        = aws_instance.public[count.index].id
  port             = 80
}

# ALB Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.public_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public_tg.arn
  }
}

# Security group rule to allow ALB to talk to EC2s
resource "aws_security_group_rule" "allow_alb_to_public" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.public.id
  source_security_group_id = aws_security_group.load_balancer.id
}
