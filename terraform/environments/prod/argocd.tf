locals {
  argocd_release_name = "argocd"
  argocd_namespace    = "argocd"
}

resource "helm_release" "argocd" {

  name             = local.argocd_release_name
  namespace        = local.argocd_namespace
  create_namespace = true
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "5.35.0"

  timeout = 800 # 10 minutes

  values = [fileexists("${path.root}/${var.argocd_values_file}") == true ? file("${path.root}/${var.argocd_values_file}") : ""]

  set_sensitive {
    name  = "configs.secret.argocdServerAdminPassword"
    value = var.argocd_admin_password
  }

  set {
    name  = "configs.params.server\\.insecure"
    value = false
  }

  set {
    name  = "dex.enabled"
    value = true
  }

  set {
    name  = "nodeSelector.run"
    value = "application"
  }

}

resource "helm_release" "argocd_image_updater" {
  depends_on = [helm_release.argocd]

  namespace        = local.argocd_namespace
  create_namespace = true
  name             = "${local.argocd_release_name}-image-updater"

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-image-updater"
  version    = "0.12.3"

  values = [fileexists("${path.root}/${var.argocd_image_updater_values_file}") == true ? file("${path.root}/${var.argocd_image_updater_values_file}") : ""]
}
