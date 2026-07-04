# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal homelab infrastructure-as-code. The working tree was deliberately reset (`A new start`) and is being rebuilt; most structure below currently lives in git history and is being reintroduced. Intended stack:

- **OpenTofu** (`tofu`, not the `terraform` CLI) — state in a GCS backend (`state.infra.malachowski.me`, prefix `prod`). `required_version >= 1.3.0`.
- **Packer** — builds openSUSE MicroOS + k3s snapshots on Hetzner Cloud.
- **Ansible** — node OS baseline and RouterOS (`community.routeros`).
- **Flux** — GitOps in-cluster delivery (chosen over ArgoCD, see ADR 0003).
- **k3s** on Hetzner Cloud; **Cloudflare** for DNS/edge. Secrets live in **GCP Secret Manager**.

Intended top-level layout (referenced by `.github/labeler.yml`): `terraform/environments/prod/`, `terraform/modules/`, `packer/`, `ansible/`, `adrs/decisions/`.

## Commands

A `Makefile` wraps the commands CI runs (`make help` lists them). Key targets: `make plan`, `make check` (fmt-check + validate + tflint), `make apply`, `make drift`, `make lint-ansible`, `make snapshot`. Override dirs via `TF_DIR`/`PKR_DIR`/`ANSIBLE_DIR`.

Underlying commands, if run by hand:

- `tofu init -input=false` / `tofu validate` / `tofu plan -input=false -lock-timeout=300s` / `tofu apply -auto-approve -lock-timeout=300s` — run inside `terraform/environments/prod/` (or `tofu -chdir=...`).
- Drift check: `tofu plan -detailed-exitcode`.
- `tflint --init` then `tflint`. Lint Ansible with `ansible-lint`.
- `packer init .` then `packer build -var "name_suffix=..."` inside `packer/<snapshot>/`.

## Workflow conventions

- **Everything lands via a PR.** No direct commits to `main` — branch first, let CI gate it. This applies to IaC, manifests, docs, and ADRs alike.
- **Never commit without an explicit order** from the owner.
- **Conventional Commits** with semantic scopes: `docs(adr):`, `chore(deps):`, `feat:`, `fix:`, `refactor:`.
- **Working-first, then codify**: get a change working by hand (CLI/Winbox) first, then capture it as self-deploying code with the *why* in the commit message. A dead config export committed just to have it in git is not codification.
- Secrets stay out of the repo (GCP Secret Manager, GitHub Actions secrets) — never suggest committing them.
- Renovate manages dependency bumps (minor/patch/digest + github-actions auto-merge; majors gated).

## ADRs

Format is **MADR** (adr.github.io/madr), stored in `adrs/decisions/`. Copy `0000-template.md` to `NNNN-short-title.md` (next free number), start as Proposed, then Accepted. Never delete an ADR — supersede it with a new one. Keep ADRs **decision-level, not detailed**: concrete values (subnets, IDs, ports) belong in tracking issues/config, not the ADR. One ADR per PR. Use `/new-adr` to scaffold.
