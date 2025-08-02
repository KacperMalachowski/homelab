packer {
  required_plugins {
    hcloud = {
      version = "~> 1"
      source  = "github.com/hetznercloud/hcloud"
    }
  }

  required_version = ">= 1.12.0"
}

variable "hcloud_token" {
  type        = string
  description = "Hetzner Cloud API token"
  default     = env("HCLOUD_TOKEN")
  sensitive   = true
}

variable "opensuse_microos_x86_link" {
  type    = string
  default = "https://download.opensuse.org/tumbleweed/appliances/openSUSE-MicroOS.x86_64-ContainerHost-OpenStack-Cloud.qcow2"
}

variable "opensuse_microos_arm64_link" {
  type    = string
  default = "https://download.opensuse.org/ports/aarch64/tumbleweed/appliances/openSUSE-MicroOS.aarch64-ContainerHost-OpenStack-Cloud.qcow2"
}

variable "packages_to_install" {
  type    = list(string)
  default = []
}

variable "k3s_version" {
  type    = string
  default = "1.6"
}

variable "name_suffix" {
  type    = string
  default = ""
}

locals {
  needed_packages = join(
    " ",
    concat(
      [
        "restorecond",
        "policycoreutils",
        "policycoreutils-python-utils",
        "setools-console",
        "audit",
        "bind-utils",
        "wireguard-tools",
        "open-iscsi",
        "nfs-client",
        "xfsprogs",
        "cryptsetup",
        "lvm2",
        "git",
        "cifs-utils",
        "mtr",
        "tcpdump",
      ],
      var.packages_to_install
    )
  )

  download_image = "wget --timeout=5 --waitretry=5 --tries=5 --retry-connrefused --inet4-only "

  write_image = <<-EOT
    set -ex
    echo "MicroOS image loadad, writing to disk..."
    qemu-img convert -p -f qcow2 -O host_device $(ls -a | grep -ie '^opensuse.*microos.*qcow2$') /dev/sda

    echo "done. Rebooting..."
    sleep 1 && udevadm settle && reboot
  EOT

  install_packages = <<-EOT
    set -ex
    echo "Reboot successful, installing packages..."
    transactional-update --continue pkg install -y ${local.needed_packages}
    transactional-update --continue shell <<- EOF
      setenforce 0
      rpm --import http://rpm.rancher.io/public.key
      zypper install -y https://github.com/k3s-io/k3s-selinux/releases/download/${var.k3s_version}.stable.1/k3s-selinux-${var.k3s_version}-1.sle.noarch.rpm
      zypper addlock k3s-selinux
      restorecon -Rv /etc/selinux/targeted/policy
      restorecon -Rv /var/lib
      setenforce 1
    EOF

    echo "done. Rebooting..."
    sleep 1 && udevadm settle && reboot
  EOT
    
  clean_up = <<-EOT
    set -ex
    echo "Reboot successful, cleaning up..."
    rm -rf /etc/ssh/ssh_host_*

    echo "Make sure to use Network Manager"
    touch /etc/NetworkManager/NetworkManager.conf

    echo "done. Rebooting..."
    sleep 1 && udevadm settle && reboot
  EOT
}

source "hcloud" "microos-x86" {
  image = "ubuntu-22.04"
  rescue = "linux64"
  location = "fsn1"
  server_type = "cx22"
  snapshot_labels = {
    "os" = "microos"
    "k3s" = "true"
    "arch" = "x86"
    # Label required for the snapshot to be recognized as a MicroOS snapshot
    # by https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner
    "microos-snapshot" = "yes"
  }
  snapshot_name = "microos-k3s-x86${var.name_suffix != "" ? "-${var.name_suffix}" : ""}"

  ssh_username = "root"
  token = var.hcloud_token
}

source "hcloud" "microos-arm64" {
  image = "ubuntu-22.04"
  rescue = "linux64"
  location = "fsn1"
  server_type = "cax11"
  snapshot_labels = {
    "os" = "microos"
    "k3s" = "true"
    "arch" = "arm64"
    # Label required for the snapshot to be recognized as a MicroOS snapshot
    # by https://github.com/kube-hetzner/terraform-hcloud-kube-hetzner
    "microos-snapshot" = "yes"
  }
  snapshot_name = "microos-k3s-arm64${var.name_suffix != "" ? "-${var.name_suffix}" : ""}"

  ssh_username = "root"
  token = var.hcloud_token
}

build {
  sources = [
    "source.hcloud.microos-x86"
  ]

  provisioner "shell" {
    inline = ["${local.download_image}${var.opensuse_microos_x86_link}"]
  }

  provisioner "shell" {
    inline            = [local.write_image]
    expect_disconnect = true
  }

  provisioner "shell" {
    pause_before      = "5s"
    inline            = [local.install_packages]
    expect_disconnect = true
  }

  provisioner "shell" {
    pause_before = "5s"
    inline       = [local.clean_up]
  }
}

build {
  sources = [
    "source.hcloud.microos-arm64"
  ]

  provisioner "shell" {
    inline = ["${local.download_image}${var.opensuse_microos_arm64_link}"]
  }

  provisioner "shell" {
    inline            = [local.write_image]
    expect_disconnect = true
  }

  provisioner "shell" {
    pause_before      = "5s"
    inline            = [local.install_packages]
    expect_disconnect = true
  }

  provisioner "shell" {
    pause_before = "5s"
    inline       = [local.clean_up]
  }
}
