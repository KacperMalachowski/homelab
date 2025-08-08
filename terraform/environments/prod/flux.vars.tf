variable "github_organization" {
  description = "The GitHub organization name"
  type        = string
  default     = "KacperMalachowski"
}

variable "github_manifest_repository" {
  description = "The GitHub repository name for manifests"
  type        = string
  default     = "homelab-manifests"
}
