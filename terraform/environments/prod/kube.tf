module "kube_hetzner" {
  providers = {
    hcloud = hcloud
  }

  source  = "kube-hetzner/kube-hetzner/hcloud"
  version = ">= 2.18.0"

  hcloud_token = var.hcloud_token

  ssh_port        = var.ssh_port
  ssh_public_key  = var.ssh_public_key
  ssh_private_key = var.ssh_private_key

  network_region = var.network_region


  control_plane_nodepools = [
    {
      name        = "control-plane"
      count       = 1
      location    = "fsn1"
      server_type = "cx22"
      labels = [
        "k3s/role=control-plane",
      ]
      taints = []
    }
  ]

  # autoscaler_nodepools = [
  #   {
  #     name        = "autoscaler"
  #     server_type = "cx22"
  #     location    = "fsn1"
  #     min_nodes   = 0
  #     max_nodes   = 3
  #     labels = {
  #       "k3s/role" = "worker",
  #       "k3s/type" = "autoscaler",
  #     }
  #     taints = []
  #   }
  # ]


  create_kustomization = false
  create_kubeconfig    = false

  allow_scheduling_on_control_plane = true
}
