output "kubeconfig" {
  value     = module.kube_hetzner.kubeconfig
  sensitive = true
}
