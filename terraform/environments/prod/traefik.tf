resource "argocd_application" "traefik" {
  metadata {
    name = "argo-traefik-chart"
  }

  wait = true

  spec {
    destination {
      server = "https://kubernetes.default.svc"
    }

    source {
      repo_url        = "https://github.com/traefik/traefik-helm-chart.git"
      path            = "traefik"
      target_revision = "v35.4.0"

      helm {
        values = <<EOF
logs:
  general:
    level: INFO
  access:
    enabled: true
service:
  annotations:
    load-balancer.hetzner.cloud/location: hel1
    load-balancer.hetzner.cloud/name: ${hcloud_load_balancer.this.name}
EOF
      }
    }


    sync_policy {
      automated {
        prune     = true
        self_heal = true
      }

      sync_options = [
        "CreateNamespace=true",
      ]
    }
  }
}
