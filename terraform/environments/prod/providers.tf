provider "hcloud" {
  token = var.hcloud_token
}

provider "helm" {
  kubernetes = {
    host                   = try(module.talos.kubeconfig_data.host, "")
    client_certificate     = try(base64decode(module.talos.kubeconfig_data.client_certificate), "")
    client_key             = try(base64decode(module.talos.kubeconfig_data.client_key), "")
    cluster_ca_certificate = try(base64decode(module.talos.kubeconfig_data.cluster_ca_certificate), "")
  }
}

provider "kubectl" {
  host                   = try(module.talos.kubeconfig_data.host, "")
  client_certificate     = try(base64decode(module.talos.kubeconfig_data.client_certificate), "")
  client_key             = try(base64decode(module.talos.kubeconfig_data.client_key), "")
  cluster_ca_certificate = try(base64decode(module.talos.kubeconfig_data.cluster_ca_certificate), "")
  load_config_file       = false
  apply_retry_count      = 3
}

provider "kubernetes" {
  host                   = try(module.talos.kubeconfig_data.host, "")
  client_certificate     = try(base64decode(module.talos.kubeconfig_data.client_certificate), "")
  client_key             = try(base64decode(module.talos.kubeconfig_data.client_key), "")
  cluster_ca_certificate = try(base64decode(module.talos.kubeconfig_data.cluster_ca_certificate), "")
}

data "kubernetes_secret" "argo_cluster_password" {
  depends_on = [ helm_release.argocd ]

  provider = kubernetes

  metadata {
    name = "argocd-initial-admin-secret"
    namespace = "argocd"
  }
}

provider "argocd" {
  port_forward_with_namespace = "argocd"
  username    = "admin"
  password    = try(data.kubernetes_secret.argo_cluster_password.data["password"], "")

  kubernetes {
    host                   = try(module.talos.kubeconfig_data.host, "")
    client_certificate     = try(base64decode(module.talos.kubeconfig_data.client_certificate), "")
    client_key             = try(base64decode(module.talos.kubeconfig_data.client_key), "")
    cluster_ca_certificate = try(base64decode(module.talos.kubeconfig_data.cluster_ca_certificate), "")
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}