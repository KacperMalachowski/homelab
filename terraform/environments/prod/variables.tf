variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
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