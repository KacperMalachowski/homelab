output "backup_bucket" {
  description = "Name of the offsite restic backup bucket."
  value       = google_storage_bucket.backups.name
}

output "backup_service_account_email" {
  description = "Service account the runner impersonates to write backups."
  value       = google_service_account.backup_writer.email
}

output "backup_workload_identity_provider" {
  description = "Full WIF provider resource name for google-github-actions/auth."
  value       = google_iam_workload_identity_pool_provider.github.name
}
