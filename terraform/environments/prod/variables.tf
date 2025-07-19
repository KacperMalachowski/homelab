variable "argo_github_token" {
  description = "GitHub token for ArgoCD to access repositories"
  type        = string
  sensitive   = true
}

variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

variable "public_domain" {
  description = "Public domain name for the cluster"
  type        = string
  default     = "malachowski.me"
}

variable "private_domain" {
  description = "Private domain name for the cluster"
  type        = string
  default     = "malachowski.local"
}