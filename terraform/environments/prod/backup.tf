# Offsite backup infrastructure (#252, ADR 0004): a Coldline bucket holding the
# restic repository, plus keyless GitHub Actions -> GCP Workload Identity
# Federation so the self-hosted runner can write to it without a long-lived
# service-account key.
#
# Retention is managed by restic (forget/prune), NOT by an object-lifecycle
# delete rule: restic dedups, so pack objects are shared across snapshots and
# age-based deletion would corrupt the repository.

resource "google_storage_bucket" "backups" {
  name     = var.backup_bucket_name
  project  = var.gcp_project
  location = var.gcp_region

  storage_class               = "COLDLINE"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  # Only reclaim storage that restic abandoned mid-upload; never delete live
  # objects on age (that is restic prune's job).
  lifecycle_rule {
    action {
      type = "AbortIncompleteMultipartUpload"
    }
    condition {
      age = 7
    }
  }
}

resource "google_service_account" "backup_writer" {
  project      = var.gcp_project
  account_id   = "restic-offsite-backup"
  display_name = "restic offsite backup writer (#252)"
}

resource "google_storage_bucket_iam_member" "backup_writer_object_admin" {
  bucket = google_storage_bucket.backups.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.backup_writer.email}"
}

resource "google_iam_workload_identity_pool" "github" {
  project                   = var.gcp_project
  workload_identity_pool_id = "github-actions"
  display_name              = "GitHub Actions"
  description               = "Keyless federation for GitHub Actions self-hosted runners."
}

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.gcp_project
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github"
  display_name                       = "GitHub"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
  }

  # Only tokens issued for our repository may map into the pool.
  attribute_condition = "assertion.repository == \"${var.github_repository}\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Allow workflows in our repository to impersonate the backup writer SA (keyless).
resource "google_service_account_iam_member" "github_wif_impersonation" {
  service_account_id = google_service_account.backup_writer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repository}"
}
