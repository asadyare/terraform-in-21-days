# Configure the AWS Provider

terraform {
  backend "s3" {
    bucket         = "min-terraform-remote-state"
    key            = "terraform.tfstate"
    region        = "eu-west-2"
  }
}
provider "aws" {
  region = "eu-west-2"
}
