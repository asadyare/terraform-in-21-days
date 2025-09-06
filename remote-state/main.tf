resource "aws_s3_bucket" "remote_state" {
  bucket = "min-tf-state-bucket"

  tags = {
    Name = "min-tf-state-bucket"
  }
}

resource "aws_dynamodb_table" "remote_state_lock" {
  name         = "my-tf-state-lock"
  billing_mode = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name = "my-tf-state-lock"
  }
}
