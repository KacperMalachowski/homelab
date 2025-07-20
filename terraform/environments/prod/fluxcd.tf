data "github_repository" "fluxcd" {
  full_name = "KacperMalachowski/homelab-manifests"
}

resource "tls_private_key" "flux_deploy_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "github_repository_deploy_key" "fluxcd_manifests" {
  title      = "FluxCD Deploy Key"
  repository = data.github_repository.fluxcd.name
  key        = tls_private_key.flux_deploy_key.public_key_openssh
  read_only  = false
}

resource "flux_bootstrap_git" "manifests_prod" {
  depends_on = [github_repository_deploy_key.fluxcd_manifests]

  embedded_manifests = true
  path               = "clusters/prod"
}
