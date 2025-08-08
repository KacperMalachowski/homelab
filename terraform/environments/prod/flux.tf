data "github_repository" "manifests" {
  full_name = "${var.github_organization}/${var.github_manifest_repository}"
}

resource "tls_private_key" "flux_deploy_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "github_repository_deploy_key" "flux" {
  repository = data.github_repository.manifests.name
  title      = "flux"
  key        = tls_private_key.flux_deploy_key.public_key_openssh
  read_only  = false
}

resource "flux_bootstrap_git" "prod" {
  depends_on = [github_repository_deploy_key.flux, module.kube_hetzner]

  embedded_manifests = true
  path               = "clusters/prod"
}
