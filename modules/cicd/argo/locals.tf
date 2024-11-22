locals {

  argocd_url =  data.terraform_remote_state.helm_argocd.outputs.argocd_url
  admin_token =  data.terraform_remote_state.helm_argocd.outputs.admin_token
  context_prefix = "terraform-workshop"
  github_repo_url = "git@github.com:biaggiogz/EKS-ARGOCD01.git"
  ssh_key_basepath = "/home/aniking/.ssh"
  ssh_host = "github.com"
  common_tags = {
    environment                    = data.terraform_remote_state.global-variables.outputs.environment_name
    "app.kubernetes.io/managed-by"  = "Terraform"
    "app.kubernetes.io/part-of"   = data.terraform_remote_state.global-variables.outputs.environment_name
    "cluster_name" = data.terraform_remote_state.eks.outputs.cluster_name
  }

}