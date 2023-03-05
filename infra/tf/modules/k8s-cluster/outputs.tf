output "public_ip" {
  value = aws_eip.master.public_ip
}

# Set resources order k8s_cluster --> argocd within the cluster
output "k8s_config_path" {
  value = "~/.kube/microk8s"
  depends_on = [null_resource.download_kubeconfig_file]
}