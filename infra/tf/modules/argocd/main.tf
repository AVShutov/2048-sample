#------------------------------------------------------------------------------#
# Deploy ArgoCD server
#------------------------------------------------------------------------------#
terraform {
  required_version = ">= 0.13"

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

variable "k8s_config_path" {}

provider "kubectl" {
  config_path = var.k8s_config_path
}

data "kubectl_file_documents" "namespace" {
  content = file("../argocd/namespace.yaml")
}

data "kubectl_file_documents" "argocd" {
  content = file("../argocd/install.yaml")
}

resource "kubectl_manifest" "namespace" {
  count              = length(data.kubectl_file_documents.namespace.documents)
  yaml_body          = element(data.kubectl_file_documents.namespace.documents, count.index)
  override_namespace = "argocd"
}

resource "kubectl_manifest" "argocd" {
  depends_on = [
    kubectl_manifest.namespace,
  ]
  count              = length(data.kubectl_file_documents.argocd.documents)
  yaml_body          = element(data.kubectl_file_documents.argocd.documents, count.index)
  override_namespace = "argocd"
}

#------------------------------------------------------------------------------#
# Deploy 2048 game app
#------------------------------------------------------------------------------#

data "kubectl_file_documents" "app" {
  content = file("../argocd/2048-app.yaml")
}

resource "kubectl_manifest" "app" {
  depends_on = [
    kubectl_manifest.argocd,
  ]
  count              = length(data.kubectl_file_documents.app.documents)
  yaml_body          = element(data.kubectl_file_documents.app.documents, count.index)
  # override_namespace = "argocd"
}
