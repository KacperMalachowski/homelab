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

variable "image_url" {
  type    = string
  default = null
}

variable "arch" {
  type = string
  default = "amd64"
}

variable "server_type" {
  type    = string
  default = "cx22"
}

variable "location" {
  type    = string
  default = "hel1"
}

variable "snapshot_suffix" {
  type    = string
  default = ""
}

locals {
  image = var.image_url != null ? var.image_url : "https://factory.talos.dev/image/98b430833db447e791fa9fecb915073eb8a6d85ccf80ca3f67cd3bf56c527f49/${var.talos_version}/hcloud-${var.arch}.raw.xz"

  download_image = "wget --timeout=5 --waitretry=5 --tries=5 --retry-connrefused -O /tmp/talos.raw.xz"

  write_image = <<-EOT
    set -ex

    echo "Writing Talos image to disk"
    xz -d -c /tmp/talos.raw.xz | dd of=/dev/sda && sync

    echo "Done"
  EOT

  clean_up = <<-EOT
    set -ex

    echo "Cleaning up"
    rm -rf /etc/ssh/ssh_host_*

    echo "Done"
  EOT
}

source "hcloud" "talos" {
  image = "debian-12"
  rescue = "linux64"
  server_type = var.arch == "amd64" ? "cx22" : "cax11"
  location = "${var.location}"

  ssh_username = "root"

  snapshot_name = "talos-${var.talos_version}-${var.arch}${var.snapshot_suffix != "" ? "-${var.snapshot_suffix}" : ""}"
  snapshot_labels = {
    type = "infra"
    os = "talos"
    version = "${var.talos_version}"
    arch = "${var.arch}"
    suffix = "${var.snapshot_suffix}"
  }
}

build {
  sources = [
    "source.hcloud.talos"
  ]

  provisioner "shell" {
    inline = ["${local.download_image} ${local.image}"]
  }

  provisioner "shell" {
    inline = ["${local.write_image}"]
  }

  provisioner "shell" {
    inline = ["${local.clean_up}"]
  }
}
