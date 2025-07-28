terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 2.0.0"
    }

    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.30.0"
    }
  }

  required_version = ">= 1.9.0"
}