output "launch_template_id" {
  value = aws_launch_template.main.id
}

output "security_group_id" {
  value = aws_security_group.private.id
  
}