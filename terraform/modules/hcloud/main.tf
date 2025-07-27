resource "hcloud_ssh_key" "this" {
  for_each = var.ssh_public_key

  name       = each.key
  public_key = each.value
}

resource "hcloud_server" "this" {
  count = var.server_number

  name        = "${var.prefix}-${count.index + 1}"
  server_type = var.type
  image       = var.image
  location    = var.location
  backups     = var.backups

  labels = var.labels

  ssh_keys = [for key in hcloud_ssh_key.this : key.id]
}