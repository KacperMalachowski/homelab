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

resource "kubernetes_manifest" "argocd_ingressroute" {
  depends_on = [helm_release.argocd]

  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"
    metadata = {
      name      = "argocd-server"
      namespace = local.argocd_namespace
    }
    spec = {
      entryPoints = ["websecure"]
      routes = [
        {
          kind     = "Rule"
          match    = "Host(`argocd.${var.domain}`)"
          priority = 10
          services = [
            {
              name = "argocd-server"
              port = 80
            }
          ]
        },
        {
          kind     = "Rule"
          match    = "Host(`argocd.${var.domain}`) && Headers(`Content-Type`, `application/grpc`)"
          priority = 11
          services = [
            {
              name   = "argocd-server"
              port   = 80
              scheme = "h2c"
            }
          ]
        }
      ]
      tls = {
        certResolver = "default"
      }
    }
  }
}
