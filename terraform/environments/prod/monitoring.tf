locals {
  promstack_release_name = "prometheus"
  promstack_namespace    = "monitoring"
}

resource "helm_release" "promstack" {
  name             = local.promstack_release_name
  namespace        = local.promstack_namespace
  create_namespace = true
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = "75.16.0"
  timeout          = 800 # 10 minutes

  # If values file specified by the var.values_file input variable exists then apply the values from this file
  # else apply the default values from the chart
  values = [fileexists("${path.root}/${var.promstack_values_file}") == true ? file("${path.root}/${var.promstack_values_file}") : ""]
}


resource "kubernetes_manifest" "grafana_dashboard_ingressroute" {
  depends_on = [helm_release.promstack]

  manifest = {
    apiVersion = "traefik.io/v1alpha1",
    kind       = "IngressRoute",
    metadata = {
      name      = "grafana",
      namespace = local.promstack_namespace
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
              name = "prometheus-grafana",
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
