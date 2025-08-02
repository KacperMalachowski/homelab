variable "hcloud_token" {
  type        = string
  description = "Hetzner Cloud API token"
  sensitive   = true
}

variable "ssh_port" {
  type        = number
  description = "SSH port to be used for the Hetzner Cloud instances"
  default     = 2222
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key to be used for the Hetzner Cloud instances"
  default     = ""
}

variable "ssh_private_key" {
  type        = string
  description = "SSH private key to be used for the Hetzner Cloud instances"
  default     = ""
  sensitive   = true
}

variable "network_region" {
  type        = string
  description = "Hetzner Cloud network region"
  default     = "eu-central"
}
