terraform {
  required_version = ">= 1.8.0"

  required_providers {

    google = {
      source  = "hashicorp/google"
      version = ">= 3.5.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.7.1"
    }

    github = {
      source  = "integrations/github"
      version = ">= 6.0"
    }

    flux = {
      source  = "fluxcd/flux"
      version = ">= 1.6.4"
    }
  }
}