# Load Balancer Security Group
resource "aws_security_group" "load_balancer" {
  name        = "${var.env_code}-load-balancer"
  description = "Allow port 80 TCP inbound to Load Balancer"
  vpc_id      = try(data.terraform_remote_state.level1.outputs["vpc_id"], null)

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
  subnets            = try(data.terraform_remote_state.level1.outputs["public_subnet_ids"], null)

  tags = {
    Name = var.env_code
  }
}

# Target Group
resource "aws_lb_target_group" "main" {
  name     = var.env_code
  port     = 80
  protocol = "HTTP"
  vpc_id   = try(data.terraform_remote_state.level1.outputs["vpc_id"], null)

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

# target group attachment
# resource "aws_lb_target_group_attachment" "main" {
#   count              = 2
#   target_group_arn   = aws_lb_target_group.main.arn
#   target_id          = aws_instance.private[count.index].id
#   port               = 80
# }

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
