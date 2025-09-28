# Configure the AWS Provider

terraform {
  backend "s3" {
    bucket               = "min-tf-state-bucket"
    key                  = "level1-terraform.tfstate"
    region               = "eu-west-2"
    dynamodb_table       = "my-tf-state-lock"
    encrypt              = true

  }
}
provider "aws" {
  region = "eu-west-2"
}
