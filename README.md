# 2048-sample

An example of deploying a sample application using the GitOps approach.

CI: GitHub Actions

CD: Terraform, Kubernetes, Helm, ArgoCD

Cloud: AWS

## Install

1. Clone the repo
2. Deploy infrastructure (Network --> Microk8s on AWS EC2 instance --> ArgoCD --> 2048 App Helm Chart)
  
    ``` bash
    cd ./infra/tf
    terraform init
    terraform plan
    terraform apply
    ```

Note. In case you have your own domain you can attach it to AWS Elastic ip you'll get from the terraform output. Cert-manager will take care of the TLS certificates.
