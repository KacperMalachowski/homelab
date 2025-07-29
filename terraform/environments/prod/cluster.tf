module "managers" {
  source = "../../modules/hcloud"

  server_number = var.manager_count

  ssh_public_key = var.ssh_public_key
  prefix         = "malachowski"

  labels = {
    "role" = "manager"
  }
}