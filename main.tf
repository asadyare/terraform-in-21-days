resource "aws_instance" "app_server" {
  ami           = "ami-0cfb394ad3c3ac699"
  instance_type = "t3.nano"

  tags = {
    Name   = "TerraformAppServer"
    Owner  = "ASAD"
  }
}