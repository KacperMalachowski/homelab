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

  version = ""

  timeout = 800 # 10 minutes

  values = [fileexists("${path.root}/${var.grafana_values_file}") == true ? file("${path.root}/${var.grafana_values_file}") : ""]

  set {
    name  = "persistence.enabled"
    value = var.grafana_enable_persistence
  }

  set {
    name  = "persistence.storageClassName"
    value = var.grafana_storageclass_name
  }

  set {
    name  = "persistence.size"
    value = var.grafana_storage_size
  }

  set {
    name  = "adminPassword"
    value = var.grafana_admin_password
  }
}
