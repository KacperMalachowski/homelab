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
  wait             = true
  wait_for_jobs    = true
  timeout          = 600  # 10 minutes
  
  # Add cleanup on fail to avoid partial deployments
  cleanup_on_fail = true
  
  # Configure ArgoCD to ensure proper initialization
  values = [
    <<-EOT
    configs:
      secret:
        # Ensure the initial admin secret is created
        createSecret: true
      params:
        # Enable insecure mode for internal communication
        server.insecure: true
        # Disable TLS for gRPC-Web
        server.grpc.web: false
    server:
      # Configure server settings
      config:
        url: "https://argocd.${var.public_domain}"
      # Ensure server accepts insecure connections
      extraArgs:
        - --insecure
      ingress:
        enabled: false
    EOT
  ]
}

resource "time_sleep" "wait_for_argocd" {
  depends_on = [helm_release.argocd, kubectl_manifest.wait_for_argocd_server]
  
  create_duration = "120s"  # Increased to 2 minutes
}

resource "kubectl_manifest" "wait_for_argocd_server" {
  depends_on = [helm_release.argocd]
  
  yaml_body = <<YAML
apiVersion: batch/v1
kind: Job
metadata:
  name: wait-for-argocd
  namespace: argocd
spec:
  template:
    spec:
      serviceAccountName: default
      containers:
      - name: wait
        image: bitnami/kubectl:latest
        command:
        - /bin/bash
        - -c
        - |
          echo "Waiting for ArgoCD server to be ready..."
          kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
          echo "ArgoCD server is ready!"
      restartPolicy: Never
  backoffLimit: 3
YAML
}

resource "argocd_application" "cluster_config" {
  depends_on = [ kubectl_manifest.argo_private_repo_token, helm_release.argocd, time_sleep.wait_for_argocd ]

  metadata {
    name      = "cluster-config"
    namespace = "argocd"
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

