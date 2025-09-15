data "aws_ami" "amazonlinux" {
  most_recent = true
  owners      = ["amazon"]

  filter {

    name   = "name"
    values = ["amzn2-ami-kernel-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# resource "aws_instance" "public" {
#   count                       = 2
#   ami                         = data.aws_ami.amazonlinux.id
#   associate_public_ip_address = true
#   instance_type               = "t3.micro"
#   key_name                    = "warsan"
#   vpc_security_group_ids      = [aws_security_group.public.id]
#   subnet_id                   = try(data.terraform_remote_state.level1.outputs["public_subnet_ids"][count.index], null)
#   user_data                   = file("user-data.sh")

#   tags = {
#     Name = "${var.env_code}-Public"
#   }
# }

# resource "aws_security_group" "public" {
#   name        = "${var.env_code}-Public"
#   description = "Allow Inbound traffic"
#   vpc_id      = try(data.terraform_remote_state.level1.outputs["vpc_id"], null)

#   ingress {
#     description = "SSH from public"
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["82.42.201.216/32"]
#   }

#   ingress {
#     description = "HTTP from public"
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     security_groups = [aws_security_group.load_balancer.id]
#   }

#   ingress {
#     description = "HTTP from load balancer"
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "${var.env_code}-Public"
#   }
# }

# resource "aws_instance" "private" {
#   count                  = 2
#   ami                    = data.aws_ami.amazonlinux.id
#   instance_type          = "t3.micro"
#   key_name               = "warsan"
#   vpc_security_group_ids = [aws_security_group.private.id]
#   subnet_id              = try(data.terraform_remote_state.level1.outputs["private_subnet_ids"][count.index], null)
#   user_data              = file("user-data.sh")

#   tags = {
#     Name = "${var.env_code}-Private"
#   }
# }

resource "aws_security_group" "private" {
  name        = "${var.env_code}-Private"
  description = "Allow vpc traffic"
  vpc_id      = try(data.terraform_remote_state.level1.outputs["vpc_id"], null)

  ingress {
    description = "SSH from vpc"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = try([data.terraform_remote_state.level1.outputs["vpc_cidr"]], [])
  }

  ingress {
    description = "HTTP from load balancer"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.load_balancer.id]
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
  name_prefix   = "${var.env_code}-"
  image_id      = data.aws_ami.amazonlinux.id
  instance_type = "t3.micro"
  key_name      = "warsan"

  vpc_security_group_ids = [aws_security_group.private.id]

  user_data = base64encode(file("user-data.sh"))

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
  vpc_zone_identifier  = try(data.terraform_remote_state.level1.outputs["private_subnet_ids"], null)
  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }
  target_group_arns = [aws_lb_target_group.main.arn]

  tag {
    key                 = "Name"
    value               = var.env_code
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

