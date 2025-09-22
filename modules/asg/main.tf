resource "aws_security_group" "private" {
  name        = "${var.env_code}-Private"
  description = "Allow vpc traffic"
  vpc_id      = var.vpc_id

  

  ingress {
    description = "HTTP from load balancer"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    security_groups = [var.lb_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env_code}-Private"
  }
}

# launch template
resource "aws_launch_template" "main" {
  name_prefix     = "${var.env_code}-"
  image_id        = var.ami_id
  instance_type   = "t3.micro"
  vpc_security_group_ids = [aws_security_group.private.id]

  user_data = base64encode(file("${path.module}/user-data.sh"))
  iam_instance_profile {
    name = aws_iam_instance_profile.main.name
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${var.env_code}-"
    }
  }
}

# autoscaling group
resource "aws_autoscaling_group" "main" {
  name                 = var.env_code
  min_size             = 2
  desired_capacity     = 2
  max_size             = 4


  vpc_zone_identifier  = var.private_subnet_ids
  launch_template {
    id    = aws_launch_template.main.id
    version = "$Latest"
  }
  target_group_arns    = [var.target_group_arns]

  tag {
    key                 = "Name"
    value               = var.env_code
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role" "main" {
  name = var.env_code
  

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "main" {
  role       = aws_iam_role.main.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "main" {
  name = var.env_code
  role = aws_iam_role.main.name
}

