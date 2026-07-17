# Runbook: migrate the offsite restic bucket to a single region

Moves the offsite backup repository off the **EU multi-region** Coldline bucket
onto a **single EU region** (`europe-west1`) one, to drop the cross-region
replication transfer the multi-region tier bills on every written byte. Refs
#252, ADR 0004.

## Why this is a runbook, not a `tofu apply`

A bucket's `location` and `name` are immutable — Terraform would **destroy and
recreate** the bucket, taking the restic repository with it. GCS in-place
relocation is not an option here (it requires a paid Storage Intelligence
subscription in both locations). So this is a **copy-and-cutover**: stand up a
new bucket beside the old one, copy the repository, repoint the workflow,
verify, then delete the old bucket. The old bucket is untouched until the very
last step, so rollback is trivial.

## Cost reality check (read before doing this)

The big "64% of the bill" replication figure predates the newest-per-guest
change, which already cut weekly writes ~85% (~20 GiB → ~3 GiB). The residual
replication is now ~small change per month, versus a **one-time copy cost of
~$1–2** (Coldline retrieval on the old bucket + early-delete when it is
deleted). This migration is now **hygiene, not savings** — payback is months.
Do it for correctness, not to move the needle on the bill.

## Preconditions

- The sshfs / weekly / newest-per-guest workflow (PR #278) is merged and a run
  is green on `main`.
- `gcloud` authenticated against project `malachowski` with rights to create
  buckets, set IAM, and read the restic password secret.
- The new bucket name is a dotted (domain-style) name under an already
  domain-verified zone (`*.infra.malachowski.me`), so no new verification.

Names/locations used below (match `terraform/environments/prod/backup.vars.tf`):

| | value |
|---|---|
| old bucket | `gs://backup.infra.malachowski.me` (EU multi-region) |
| new bucket | `gs://offsite.infra.malachowski.me` (`europe-west1`) |
| repo path | `/pve` (unchanged) |
| writer SA | `restic-offsite-backup@malachowski.iam.gserviceaccount.com` |

> Region choice: `europe-west1` (Belgium) is geographically separated from the
> Poland on-prem host — the right disaster domain for a DR copy — and among the
> cheapest EU regions. Use `europe-central2` (Warsaw) instead only if data
> residency in Poland outweighs DR separation; it is co-located with the primary.

## Procedure

### 1. (optional) Shrink the repo before copying

Copy cost scales with repo size. If the repo still carries oversized
whole-directory test snapshots, forget them first so the copy moves only live
data:

```sh
export RESTIC_REPOSITORY="gs:backup.infra.malachowski.me:/pve"
export RESTIC_PASSWORD="$(gcloud secrets versions access latest --secret=restic-offsite-password)"
restic snapshots --compact
restic forget <oversized-snapshot-ids> --prune
```

### 2. Create the new bucket (working-first)

Mirror every setting Terraform will later assert, so the eventual `import`
produces a clean plan:

```sh
gcloud storage buckets create gs://offsite.infra.malachowski.me \
  --project=malachowski \
  --location=europe-west1 \
  --default-storage-class=COLDLINE \
  --uniform-bucket-level-access \
  --public-access-prevention=enforced

# AbortIncompleteMultipartUpload after 7 days (matches backup.tf lifecycle_rule)
printf '{"rule":[{"action":{"type":"AbortIncompleteMultipartUpload"},"condition":{"age":7}}]}' \
  | gcloud storage buckets update gs://offsite.infra.malachowski.me --lifecycle-file=/dev/stdin

# Writer SA needs objectAdmin (matches the google_storage_bucket_iam_member)
gcloud storage buckets add-iam-policy-binding gs://offsite.infra.malachowski.me \
  --member="serviceAccount:restic-offsite-backup@malachowski.iam.gserviceaccount.com" \
  --role="roles/storage.objectAdmin"
```

### 3. Copy the repository

Raw object copy preserves the restic repo exactly (same packs, index, keys) — no
re-encryption, no re-init. restic identifies a repo by its objects, not the
bucket name.

```sh
gcloud storage rsync -r \
  gs://backup.infra.malachowski.me/pve \
  gs://offsite.infra.malachowski.me/pve
```

### 4. Verify the new repo before cutover

```sh
export RESTIC_REPOSITORY="gs:offsite.infra.malachowski.me:/pve"
export RESTIC_PASSWORD="$(gcloud secrets versions access latest --secret=restic-offsite-password)"
restic snapshots --compact     # same snapshots as the old repo
restic check                   # structural integrity of the copy
```

Do **not** proceed unless `check` is clean.

### 5. Cut over

Merge this PR (workflow `RESTIC_REPOSITORY` and tofu vars now point at the new
bucket), then prove the live path against the new bucket:

```sh
gh workflow run backup-offsite.yml --ref main
gh run watch <run-id> --exit-status
```

A green run writes a fresh snapshot to the new bucket. If it fails, **roll back**
by reverting the `RESTIC_REPOSITORY` change — the old bucket is still intact and
current.

### 6. Reconcile Terraform state (no destroy/recreate)

`google_storage_bucket.backups` still points state at the old bucket. Adopt the
hand-created new bucket so `apply` is a no-op instead of a destroy+create:

```sh
cd terraform/environments/prod
tofu state rm google_storage_bucket.backups
tofu import google_storage_bucket.backups offsite.infra.malachowski.me
tofu plan   # expect: no changes to the bucket (IAM/lifecycle already match)
```

### 7. Delete the old bucket

Only after at least one green run against the new bucket and a verified
`restic check`:

```sh
gcloud storage rm -r gs://backup.infra.malachowski.me/**
gcloud storage buckets delete gs://backup.infra.malachowski.me
```

Deleting Coldline objects younger than 90 days incurs a one-time early-delete
charge — expected and small.

## Rollback

At any point before step 7, revert `RESTIC_REPOSITORY` (and, if state was
already reconciled, re-import the old bucket). No data is lost: the old bucket is
only removed in the final step.

## Post-migration

- Confirm the next scheduled weekly run is green against the new bucket.
- Re-affirm ADR 0004's acceptance test: a `restic restore` from the new bucket
  into a scratch target.
- Mirror of the restic password in KeePass is unchanged (same secret).
