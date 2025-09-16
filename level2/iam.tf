# resource "aws_iam_policy" "main" {
#   name        = var.env_code
#   description = "S3 Full Access"

#   policy      = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Action = [
#         "s3:*"
#       ]
#       Resource = "*"
#     }]
#   })
  
# }

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
