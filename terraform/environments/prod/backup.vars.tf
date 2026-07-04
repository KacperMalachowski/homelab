variable "gcp_project" {
  description = "GCP project that owns the offsite backup bucket and workload-identity federation."
  type        = string
  default     = "malachowski"
}

variable "gcp_region" {
  description = "Region for the offsite backup bucket."
  type        = string
  default     = "europe-central2"
}

variable "backup_bucket_name" {
  description = "Name of the Coldline bucket holding the offsite restic repository."
  type        = string
  default     = "malachowski-backups"
}

variable "github_repository" {
  description = "owner/name of the repository whose Actions runner may write backups via WIF."
  type        = string
  default     = "KacperMalachowski/homelab"
}
