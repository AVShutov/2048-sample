# output "public_ip" {
#   value = aws_eip.master.public_ip
# }

output "public_ip" {
  value = module.k8s_cluster.public_ip
}