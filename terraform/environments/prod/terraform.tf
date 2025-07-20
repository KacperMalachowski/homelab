terraform {
  required_version = ">= 1.8.0"

  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.1.3"
    }

    google = {
      source  = "hashicorp/google"
      version = ">= 3.5.0"
    }

     argocd = {
      source = "claranet/argocd"
      version = "5.6.0-claranet0"
    }

    kubernetes = {
      source = "hashicorp/kubernetes"
      version = ">= 2.35.1"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 5.7.1"
    }
  }
}