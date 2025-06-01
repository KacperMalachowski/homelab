resource "kubectl_manifest" "argocd_namespace" {
  depends_on = [ module.talos ]
  yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: argocd
  labels:
    name: argocd
    pod-security.kubernetes.io/enforce: privileged
YAML
}

resource "kubectl_manifest" "argo_private_repo_token" {
  depends_on = [ module.talos, kubectl_manifest.argocd_namespace ]
  yaml_body = <<YAML
apiVersion: v1
kind: Secret
metadata:
 name: argo-private-repo-secret
 namespace: argocd
 labels:
   argocd.argoproj.io/secret-type: repo-creds
stringData:
  type: git
  url: https://github.com/KacperMalachowski/homelab
  username: kacpermalachowski_argo_repo
  password: ${var.argo_github_token}
YAML
}

resource "helm_release" "argocd" {
  depends_on = [ kubectl_manifest.argo_private_repo_token, module.talos]
  name = "argocd"

  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"
  version    = "7.7.11"

  create_namespace = true
}

resource "argocd_application" "cluster_config" {
  depends_on = [ kubectl_manifest.argo_private_repo_token, helm_release.argocd ]

  metadata {
    name      = "cluster-config"
  }

  wait = true

  spec {
    destination {
      server   = "https://kubernetes.default.svc"
    }

    source {
      repo_url = "https://github.com/KacperMalachowski/homelab"
      path = "manifests/prod"
      target_revision = "HEAD"
      directory {
        recurse = true
      }
    }

    sync_policy {
      automated {
        prune = true
        self_heal = true
      }

      sync_options = [
        "ServerSideApply=true",
        "CreateNamespace=true"
      ]
    }
  }
}

