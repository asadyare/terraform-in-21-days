data "terraform_remote_state" "level1" {
  backend = "s3"
  config = {
    bucket         = "min-tf-state-bucket"
    key            = "level1-terraform.tfstate"
    region         = "eu-west-2"
    }
}
