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
      version = "~> 5"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.9.0"
    }

    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
    }
    
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.0"
    }
  }
}