output "subnet_id" {
  value = aws_subnet.main.id
}

output "vpc_security_group_ids" {
  value = [aws_security_group.k8s_sg.id]
}