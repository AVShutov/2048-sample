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

3. kubeconfig will be copied to your local `~/.kube/microk8s`

4. (Optional) Build and push to ghcr.io the new docker container tag with [GitHub Action](https://github.com/AVShutov/2048-sample/actions/workflows/docker-image.yml). The new image tag will be redeployed automatically via ArgoCD.

Note. In case you have your own domain you can attach it to AWS Elastic ip you'll get from the terraform output. Cert-manager will take care of the TLS certificates.
