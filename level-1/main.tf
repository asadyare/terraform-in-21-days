data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.2"

  name               = "${var.env_code}-vpc"
  cidr               = var.vpc_cidr
  azs                = data.aws_availability_zones.available.names[*]
  public_subnets     = var.public_cidr
  private_subnets    = var.private_cidr
  enable_nat_gateway = true

  private_subnet_tags = {
    "name"                                      = "private"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-alb"           = "1"
  }

  public_subnet_tags = {
    "name"                                      = "public"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/alb"                    = "1"
  }
}

