resource "aws_eks_node_group" "this" {
    cluster_name    = aws_eks_cluster.this.name
    node_group_name = "${var.cluster_name}-workers"
    node_role_arn   = aws_iam_role.managed_nodes.arn
    subnet_ids      = data.terraform_remote_state.level-1.outputs.private_subnet_id
    ami_type        = "AL2023_x86_64_STANDARD"
    capacity_type   = "ON_DEMAND"
    disk_size       = 30
    instance_types  = ["t3.medium"]

    scaling_config {
      min_size     = 3
      max_size     = 3
      desired_size = 3
    }

  
}
