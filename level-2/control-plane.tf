

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids = data.terraform_remote_state.level-1.outputs.private_subnet_id
  }
}