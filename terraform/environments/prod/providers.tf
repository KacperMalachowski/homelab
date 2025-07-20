provider "hcloud" {
  token = var.hcloud_token
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "flux" {
  kubernetes = {
    host = module.talos.kubeconfig_data.host

    client_certificate     = module.talos.kubeconfig_data.client_certificate
    client_key             = module.talos.kubeconfig_data.client_key
    cluster_ca_certificate = module.talos.kubeconfig_data.cluster_ca_certificate
  }

  git = {
    url = "ssh://git@github.com/${data.github_repository.fluxcd.full_name}"
    ssh = {
      username    = "git"
      private_key = tls_private_key.flux_deploy_key.private_key_pem
    }
  }
}