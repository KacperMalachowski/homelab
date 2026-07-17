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
  description = "Location of the offsite backup bucket. Single EU region (europe-west1, geographically separated from the Poland on-prem host) rather than EU multi-region: the multi-region tier bills cross-region replication transfer on every written byte — the largest line on the backup bill — for geo-redundancy an offsite DR copy does not need on top of single-region's 11-nines durability. See docs/runbooks/offsite-bucket-single-region-migration.md."
  type        = string
  default     = "europe-west1"
}

variable "backup_bucket_name" {
  description = "Name of the Coldline bucket holding the offsite restic repository. Region-neutral name so a future relocation never forces another rename."
  type        = string
  default     = "offsite.infra.malachowski.me"
}

variable "github_repository" {
  description = "owner/name of the repository whose Actions runner may write backups via WIF."
  type        = string
  default     = "KacperMalachowski/homelab"
}
