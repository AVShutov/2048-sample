# Terraform state will be stored in S3
terraform {
  required_version = ">= 0.13"

  backend "s3" {
    bucket = "tf-state-2048-ashutau"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}

#------------------------------------------------------------------------------#
# Create network
#------------------------------------------------------------------------------#
module "network" {
  source = "./modules/network"
}
#------------------------------------------------------------------------------#
# Deploy Kubernetes cluster
#------------------------------------------------------------------------------#
module "k8s_cluster" {
  source = "./modules/k8s-cluster"

  subnet_id              = module.network.subnet_id
  vpc_security_group_ids = module.network.vpc_security_group_ids
}
#------------------------------------------------------------------------------#
# Deploy ArgoCD server
#------------------------------------------------------------------------------#
module "argocd" {
  source = "./modules/argocd"

  k8s_config_path = module.k8s_cluster.k8s_config_path
}
