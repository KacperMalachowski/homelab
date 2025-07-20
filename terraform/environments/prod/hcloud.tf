locals {
  any_api_source = [
    "0.0.0.0/0",
    "::/0"
  ]
}

module "talos" {
  source  = "hcloud-talos/talos/hcloud"
  version = "2.13.1"

  hcloud_token = var.hcloud_token

  talos_version = "v1.8.1"

  cluster_name    = "edplanes-prod"
  datacenter_name = "hel1-dc2"

  control_plane_count       = 1
  control_plane_server_type = "cx22"

  firewall_talos_api_source = local.any_api_source
  firewall_kube_api_source  = local.any_api_source

  disable_arm = true
}
resource "hcloud_load_balancer" "this" {
  name = "edplanes-prod"
  load_balancer_type = "lb11"
  location = "hel1"
}

resource "hcloud_load_balancer_target" "this" {
  type = "label_selector"
  load_balancer_id = hcloud_load_balancer.this.id
  label_selector = "role=control-plane"
  use_private_ip = true
}