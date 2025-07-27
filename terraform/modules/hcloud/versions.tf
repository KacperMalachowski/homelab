terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.30.0"
    }
  }

  required_version = ">= 1.9"
}