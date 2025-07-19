locals {
  any_api_source = [
    "0.0.0.0/0",
    "::/0"
  ]

  public_domain = "malachowski.me"
  private_domain = "malachowski.local"
}

resource "null_resource" "domain_name" {
  # This resource is used to trigger the Talos module to update the domain name
  # when the public or private domain changes.
  triggers = {
    public_domain  = local.public_domain
    private_domain = local.private_domain
  }
}

module "talos" {
  source = "hcloud-talos/talos/hcloud"
  version = "2.15.13"

  depends_on = [ null_resource.domain_name ]

  talos_version = "v1.9.5"
  kubernetes_version = "1.30.3"
  cilium_version     = "1.16.2"

  hcloud_token = var.hcloud_token

  cluster_name = local.public_domain
  cluster_domain = local.private_domain
  cluster_api_host = "kube.${local.public_domain}"
  enable_alias_ip = true
  output_mode_config_cluster_endpoint = "cluster_endpoint"

  firewall_use_current_ip = false
  firewall_talos_api_source = local.any_api_source
  firewall_kube_api_source = local.any_api_source

  extra_firewall_rules = [
    {
      description = "HTTPS"
      direction = "in"
      protocol  = "tcp"
      port      = "443"
      source_ips = local.any_api_source
    },
    {
      description = "HTTP"
      direction = "in"
      protocol  = "tcp"
      port      = "80"
      source_ips = local.any_api_source
    }
  ]

  datacenter_name = "fsn1-dc14"

  control_plane_count = 1
  control_plane_server_type = "cx22"

  worker_count = 1
  worker_server_type = "cx22"

  disable_arm = true
}

resource "hcloud_load_balancer" "this" {
  name = "malachowski-prod"
  load_balancer_type = "lb11"

  location = "hel1"
  
}

resource "hcloud_load_balancer_target" "this" {
  type = "label_selector"
  load_balancer_id = hcloud_load_balancer.this.id
  label_selector = "role=control-plane"
}