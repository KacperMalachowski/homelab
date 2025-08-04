locals {
  grafana_release_name = "grafana"
  grafana_namespace    = "monitoring"
}

resource "helm_release" "grafana" {
  namespace        = local.grafana_namespace
  create_namespace = true
  name             = local.grafana_release_name

  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"

  version = "9.3.1"

  timeout = 800 # 10 minutes

  values = [fileexists("${path.root}/${var.grafana_values_file}") == true ? file("${path.root}/${var.grafana_values_file}") : ""]

  set = [{
    name  = "persistence.enabled"
    value = var.grafana_enable_persistence
    },
    {
      name  = "persistence.storageClassName"
      value = var.grafana_storageclass_name
    },
    {
      name  = "persistence.size"
      value = var.grafana_storage_size
    },
    {
      name  = "adminPassword"
      value = var.grafana_admin_password
    }
  ]
}

resource "kubernetes_manifest" "grafana_dashboard_ingressroute" {
  depends_on = [helm_release.grafana]

  manifest = {
    apiVersion = "traefik.io/v1alpha1",
    kind       = "IngressRoute",
    metadata = {
      name      = "grafana",
      namespace = local.grafana_namespace
    },
    spec = {
      entryPoints = ["websecure"],
      routes = [
        {
          kind     = "Rule",
          match    = "Host(`grafana.${var.public_domain}`)",
          priority = 10
          services = [
            {
              name = "grafana",
              port = 80
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
