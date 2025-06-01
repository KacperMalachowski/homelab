packer {
  required_plugins {
    hcloud = {
      source  = "github.com/hetznercloud/hcloud"
      version = "~> 1"
    }
  }
}

variable "talos_version" {
  type = string
  default = "v1.10.0"
}

variable "arch" {
  type = string
  default = "amd64"
}

variable "server_type" {
  type    = string
  default = "cx22"
}

variable "server_location" {
  type    = string
  default = "hel1"
}

variable "snapshot_suffix" {
  type    = string
  default = ""
}

locals {
  image = "https://factory.talos.dev/image/98b430833db447e791fa9fecb915073eb8a6d85ccf80ca3f67cd3bf56c527f49/${var.talos_version}/hcloud-${var.arch}.raw.xz"
}

source "hcloud" "talos" {
  rescue       = "linux64"
  image        = "debian-12"
  location     = "${var.server_location}"
  server_type  = "${var.server_type}"
  ssh_username = "root"

  snapshot_name   = "talos-${var.talos_version}-${var.arch}-${formatdate("MMDDYY-HHmmss", timestamp())}${var.snapshot_suffix != "" ? "-${var.snapshot_suffix}" : ""}"
  snapshot_labels = {
    type    = "infra",
    os      = "talos",
    version = "${var.talos_version}",
    arch    = "${var.arch}",
    suffix = "${var.snapshot_suffix}"
  }
}

build {
  sources = ["source.hcloud.talos"]

  provisioner "shell" {
    inline = [
      "apt-get install -y wget",
      "wget -O /tmp/talos.raw.xz ${local.image}",
      "xz -d -c /tmp/talos.raw.xz | dd of=/dev/sda && sync",
    ]
  }
}