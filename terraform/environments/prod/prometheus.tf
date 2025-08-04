locals {
  prometheus_release_name = "prometheus"
  prometheus_namespace    = "monitoring"
}

resource "helm_release" "promstack" {
  name             = local.prometheus_release_name
  namespace        = local.prometheus_namespace
  create_namespace = true
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "75.15.2"
  timeout          = 800 # 10 minutes

  # If values file specified by the var.values_file input variable exists then apply the values from this file
  # else apply the default values from the chart
  values = [fileexists("${path.root}/${var.promstack_values_file}") == true ? file("${path.root}/${var.promstack_values_file}") : ""]
}
