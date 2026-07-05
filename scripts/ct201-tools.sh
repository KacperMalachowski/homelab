#!/usr/bin/env bash
# Idempotent tooling install for the CT 201 ops workstation (#266). amd64 Debian 12.
# Run as root inside the CT:  bash ct201-tools.sh
# Installs the toolchain only; credentials (management SA key, PVE API token) and
# GitHub auth are wired separately and never live in the repo.
set -uo pipefail
export DEBIAN_FRONTEND=noninteractive
export PATH="/usr/local/bin:$PATH"   # tofu/gcloud/tflint land here
log(){ printf '[ct201-tools] %s\n' "$*"; }

log "apt base packages"
apt-get update -qq
apt-get install -y -qq git make python3 python3-venv jq curl unzip ca-certificates gnupg restic

if ! command -v tofu >/dev/null 2>&1; then
  log "OpenTofu (standalone)"
  curl -fsSL https://get.opentofu.org/install-opentofu.sh -o /tmp/install-opentofu.sh
  chmod +x /tmp/install-opentofu.sh
  /tmp/install-opentofu.sh --install-method standalone
fi

if ! command -v gh >/dev/null 2>&1; then
  log "GitHub CLI (apt repo)"
  install -d -m 0755 /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
  chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list
  apt-get update -qq && apt-get install -y -qq gh
fi

if ! command -v tflint >/dev/null 2>&1; then
  log "tflint"
  curl -fsSL https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
fi

if ! command -v gcloud >/dev/null 2>&1; then
  log "Google Cloud CLI"
  curl -fsSL https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz -o /tmp/gcloud.tgz
  tar -xf /tmp/gcloud.tgz -C /opt
  /opt/google-cloud-sdk/install.sh --quiet --path-update true >/dev/null
  ln -sf /opt/google-cloud-sdk/bin/gcloud /usr/local/bin/gcloud
  ln -sf /opt/google-cloud-sdk/bin/gsutil /usr/local/bin/gsutil
fi

log "versions:"
for t in git make python3 jq tofu gh tflint gcloud restic; do
  printf '  %-8s %s\n' "$t" "$(command -v "$t" >/dev/null 2>&1 && "$t" --version 2>/dev/null | head -1 || echo MISSING)"
done
log "done"
