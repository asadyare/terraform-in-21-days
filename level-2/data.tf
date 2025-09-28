data "terraform_remote_state" "level-1" {
  backend = "s3"

  config = {
    bucket = "min-tf-state-bucket"
    key    = "level-1terraform.tfstate"
    region = "eu-west-2"
  }
}