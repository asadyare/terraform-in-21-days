output "public_subnet_id" {
  description = "The IDs of the public subnets"
  value       = module.vpc.public_subnets
  
}

output "private_subnet_id" {
  description = "The IDs of the private subnets"
  value       = module.vpc.private_subnets
}
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}
