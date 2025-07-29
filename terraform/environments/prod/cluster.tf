module "masters" {
  source = "../../modules/hcloud"

  server_number = var.master_count

  ssh_public_key = var.ssh_public_key
  prefix         = "malachowski"

  labels = {
    "role" = "master"
  }
}


