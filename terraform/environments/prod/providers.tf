provider "hcloud" {
  token = var.hcloud_token
}

provider "cloudflare" {}

provider "github" {}


provider "helm" {
  kubernetes = {
    host = module.kube_hetzner.kubeconfig_data.host

    client_certificate     = module.kube_hetzner.kubeconfig_data.client_certificate
    client_key             = module.kube_hetzner.kubeconfig_data.client_key
    cluster_ca_certificate = module.kube_hetzner.kubeconfig_data.cluster_ca_certificate
  }
}

provider "kubernetes" {
  host = module.kube_hetzner.kubeconfig_data.host

  cluster_ca_certificate = module.kube_hetzner.kubeconfig_data.cluster_ca_certificate
  client_key             = module.kube_hetzner.kubeconfig_data.client_key
  client_certificate     = module.kube_hetzner.kubeconfig_data.client_certificate

}

provider "flux" {
  kubernetes = {
    host = module.kube_hetzner.kubeconfig_data.host

    cluster_ca_certificate = module.kube_hetzner.kubeconfig_data.cluster_ca_certificate
    client_key             = module.kube_hetzner.kubeconfig_data.client_key
    client_certificate     = module.kube_hetzner.kubeconfig_data.client_certificate
  }

  git = {
    url = "ssh://git@github.com/${var.github_organization}/${var.github_manifest_repository}.git"

    ssh = {
      username    = "git"
      private_key = tls_private_key.flux_deploy_key.private_key_openssh
    }
  }

}
