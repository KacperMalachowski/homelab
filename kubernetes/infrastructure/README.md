# kubernetes/infrastructure/

Platform services the apps depend on, delivered via the GitOps controller: ingress,
cert-manager, storage, external-secrets (GCP Secret Manager sync), and `monitoring/`
(kube-prometheus-stack + Loki + Alloy). Reconciled before `apps/`.
