# Secret Manager entries the offsite backup workflow reads at runtime (#252).
# Only the containers and access grants are managed here; the secret *values*
# are set out-of-band (gcloud) so they never enter tofu state.

resource "google_secret_manager_secret" "restic_offsite_password" {
  project   = var.gcp_project
  secret_id = "restic-offsite-password"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret" "pve_backup_ssh_key" {
  project   = var.gcp_project
  secret_id = "pve-backup-ssh-key"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_iam_member" "restic_password_accessor" {
  project   = var.gcp_project
  secret_id = google_secret_manager_secret.restic_offsite_password.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.backup_writer.email}"
}

resource "google_secret_manager_secret_iam_member" "pve_ssh_key_accessor" {
  project   = var.gcp_project
  secret_id = google_secret_manager_secret.pve_backup_ssh_key.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.backup_writer.email}"
}
