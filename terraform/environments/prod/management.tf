# Management identity for the CT 201 ops workstation (#266). Scoped for
# `tofu plan` only: refresh (viewer) + state locking (objectAdmin on the state
# bucket). It deliberately has NO resource-mutating roles (apply stays in CI,
# #212/#111) and NO secretAccessor, so it cannot read Secret Manager values.

resource "google_service_account" "homelab_ops" {
  project      = var.gcp_project
  account_id   = "homelab-ops-workstation"
  display_name = "Homelab ops workstation (CT 201, plan-only)"
}

resource "google_project_iam_member" "ops_viewer" {
  project = var.gcp_project
  role    = "roles/viewer"
  member  = "serviceAccount:${google_service_account.homelab_ops.email}"
}

# Read-only view of IAM policies so `tofu plan` can refresh iam_member resources
# (basic viewer lacks *.getIamPolicy). Still cannot modify IAM.
resource "google_project_iam_member" "ops_security_reviewer" {
  project = var.gcp_project
  role    = "roles/iam.securityReviewer"
  member  = "serviceAccount:${google_service_account.homelab_ops.email}"
}

resource "google_storage_bucket_iam_member" "ops_state_object_admin" {
  bucket = "state.infra.malachowski.me"
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.homelab_ops.email}"
}
