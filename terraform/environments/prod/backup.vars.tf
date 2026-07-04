variable "gcp_project" {
  description = "GCP project that owns the offsite backup bucket and workload-identity federation."
  type        = string
  default     = "malachowski"
}

variable "gcp_region" {
  description = "Default region for regional GCP resources."
  type        = string
  default     = "europe-central2"
}

variable "backup_bucket_location" {
  description = "Location of the offsite backup bucket. Multi-region EU for disaster-recovery geo-redundancy across separated EU locations (a single region shares a disaster domain with the on-prem host)."
  type        = string
  default     = "EU"
}

variable "backup_bucket_name" {
  description = "Name of the Coldline bucket holding the offsite restic repository."
  type        = string
  default     = "backup.infra.malachowski.me"
}

variable "github_repository" {
  description = "owner/name of the repository whose Actions runner may write backups via WIF."
  type        = string
  default     = "KacperMalachowski/homelab"
}
