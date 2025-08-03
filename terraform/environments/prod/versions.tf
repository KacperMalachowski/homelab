terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.45.0"
    }


    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 2.0.0"
    }
  }

  required_version = ">= 1.3.0"
}
