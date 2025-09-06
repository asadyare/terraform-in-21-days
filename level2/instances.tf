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

resource "aws_instance" "public" {
  ami                         = data.aws_ami.amazonlinux.id
  associate_public_ip_address = true
  instance_type               = "t3.micro"
  key_name                    = "warsan"
  vpc_security_group_ids      = [aws_security_group.public.id]
  subnet_id                   = try(data.terraform_remote_state.level1.outputs["public_subnet_ids"][0], null)
  user_data                   = file("user-data.sh")

  tags = {
    Name = "${var.env_code}-Public"
  }
}

resource "aws_security_group" "public" {
  name        = "${var.env_code}-Public"
  description = "Allow Inbound traffic"
  vpc_id      = try(data.terraform_remote_state.level1.outputs["vpc_id"], null)

  ingress {
    description = "SSH from public"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["82.42.201.216/32"]
  }

  ingress {
    description = "HTTP from public"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env_code}-Public"
  }
}

resource "aws_instance" "private" {
  ami                    = data.aws_ami.amazonlinux.id
  instance_type          = "t3.micro"
  key_name               = "warsan"
  vpc_security_group_ids = [aws_security_group.private.id]
  subnet_id              = try(data.terraform_remote_state.level1.outputs["private_subnet_ids"][0], null)

  tags = {
    Name = "${var.env_code}-Private"
  }
}

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
