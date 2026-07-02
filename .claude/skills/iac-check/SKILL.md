---
name: iac-check
description: Run local OpenTofu validation (fmt-check, validate, plan) against terraform/environments/prod for pre-PR feedback. Use before opening an IaC PR or to check a Terraform change locally.
---

# Local IaC check

Give fast local feedback on Terraform/OpenTofu changes, mirroring what CI gates. Run from `terraform/environments/prod/` (the OpenTofu root). If that directory doesn't exist yet, the tree hasn't been rebuilt — say so and stop.

## Steps

1. `tofu fmt -check -recursive` — report any unformatted files (fix with `tofu fmt` only if the owner asks).
2. `tofu init -input=false` if `.terraform/` is absent or providers changed.
3. `tofu validate`.
4. `tofu plan -input=false -lock-timeout=300s` — summarize the diff (creates/updates/destroys). Flag any destroy or replace.
5. If `tflint` is installed, run `tflint --init` then `tflint`. It's CI-only here, so note if it's missing rather than treating that as a failure.

This needs cloud/state credentials (GCS backend, Hetzner/Cloudflare). If `init`/`plan` fails on auth, report it plainly — don't try to fabricate credentials. Never run `apply`.
