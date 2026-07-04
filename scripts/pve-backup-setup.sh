#!/usr/bin/env bash
#
# Codifies the pve-host side of the tested-offsite-backups work (#252, ADR 0005).
# Idempotent: safe to re-run. Run as root ON the Proxmox host (pve):
#
#     scp scripts/pve-backup-setup.sh root@pve:/tmp/ && ssh root@pve bash /tmp/pve-backup-setup.sh
#
# What it sets up:
#   1. A dedicated ext4 backup volume on the idle 1TB HDD pool -> PVE `dir` storage.
#   2. A nightly vzdump job (snapshot mode) with local retention.
#   3. A PVE-privilege-free OS account `backup-ro` whose SSH key is pinned, via
#      rrsync, to read-only access of the dump directory — this is what the
#      offsite GitHub Actions workflow pulls with (its private key lives in GCP
#      Secret Manager: `pve-backup-ssh-key`).
#
# It intentionally does NOT touch guests or existing storage. The offsite push
# (restic -> GCS, keyless WIF) lives in .github/workflows/backup-offsite.yml.
set -euo pipefail

# ---- configuration ----------------------------------------------------------
THIN_POOL="hdd_sata/hdd_sata"      # <vg>/<thinpool> of the idle HDD
LV_NAME="backup"
LV_SIZE="600G"
LV_DEV="/dev/hdd_sata/backup"
MOUNT="/mnt/pve/backup-local"
STORAGE="backup-local"
BACKUP_VMIDS="100,101"             # HAOS + Pi-hole
SCHEDULE="02:00"
PRUNE="keep-daily=7,keep-weekly=4"
JOB_MARKER="managed-by:pve-backup-setup"
BACKUP_USER="backup-ro"
# Public half of the offsite pull key; private half is in GCP SM pve-backup-ssh-key.
PULL_PUBKEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIObT5YPhI8eKuBtxTotu5y2jvWUaznBM5rWCTN03ODTf pve-backup-ro-pull"
# -----------------------------------------------------------------------------

log() { printf '[pve-backup-setup] %s\n' "$*"; }

# 1. Backup filesystem on the idle HDD pool -----------------------------------
if ! lvs "${THIN_POOL%/*}/$LV_NAME" >/dev/null 2>&1; then
  log "creating thin LV $LV_NAME (${LV_SIZE}) on $THIN_POOL"
  lvcreate -T "$THIN_POOL" -V "$LV_SIZE" -n "$LV_NAME" >/dev/null
fi
if ! blkid "$LV_DEV" >/dev/null 2>&1; then
  log "formatting $LV_DEV ext4"
  mkfs.ext4 -q -m 0 -L "$STORAGE" "$LV_DEV"
fi
mkdir -p "$MOUNT"
# nofail: a missing/unmounted backup disk must never block boot.
if ! grep -qs "[[:space:]]$MOUNT[[:space:]]" /etc/fstab; then
  log "adding fstab entry for $MOUNT"
  echo "$LV_DEV $MOUNT ext4 defaults,nofail 0 2" >>/etc/fstab
fi
mountpoint -q "$MOUNT" || { log "mounting $MOUNT"; mount "$MOUNT"; }

# 2. PVE dir storage ----------------------------------------------------------
if ! pvesm status --storage "$STORAGE" >/dev/null 2>&1; then
  log "registering PVE storage $STORAGE"
  pvesm add dir "$STORAGE" --path "$MOUNT" --content backup --is_mountpoint 1
fi

# 3. Nightly vzdump job (reconciled by marker comment) ------------------------
existing_job=$(pvesh get /cluster/backup --output-format json 2>/dev/null \
  | python3 -c 'import json,sys
m=sys.argv[1]
print(next((j["id"] for j in json.load(sys.stdin) if j.get("comment")==m), ""))' "$JOB_MARKER")
if [ -z "$existing_job" ]; then
  log "creating nightly vzdump job ($BACKUP_VMIDS @ $SCHEDULE)"
  pvesh create /cluster/backup \
    --comment "$JOB_MARKER" \
    --schedule "$SCHEDULE" \
    --storage "$STORAGE" \
    --vmid "$BACKUP_VMIDS" \
    --mode snapshot \
    --compress zstd \
    --notes-template "{{guestname}}" \
    --prune-backups "$PRUNE" \
    --enabled 1 >/dev/null
else
  log "reconciling existing vzdump job $existing_job"
  pvesh set "/cluster/backup/$existing_job" \
    --schedule "$SCHEDULE" --storage "$STORAGE" --vmid "$BACKUP_VMIDS" \
    --mode snapshot --compress zstd --notes-template "{{guestname}}" \
    --prune-backups "$PRUNE" --enabled 1 >/dev/null
fi

# 4. Read-only pull account (no Proxmox privileges) ---------------------------
id "$BACKUP_USER" >/dev/null 2>&1 || {
  log "creating OS user $BACKUP_USER"
  useradd -r -m -d "/home/$BACKUP_USER" -s /bin/bash "$BACKUP_USER"
}
install -d -m 700 -o "$BACKUP_USER" -g "$BACKUP_USER" "/home/$BACKUP_USER/.ssh"
# Pin the key to rrsync, read-only, confined to the dump dir — nothing else.
printf 'command="/usr/bin/rrsync -ro %s/dump",no-agent-forwarding,no-port-forwarding,no-pty,no-user-rc,no-X11-forwarding %s\n' \
  "$MOUNT" "$PULL_PUBKEY" >"/home/$BACKUP_USER/.ssh/authorized_keys"
chown "$BACKUP_USER:$BACKUP_USER" "/home/$BACKUP_USER/.ssh/authorized_keys"
chmod 600 "/home/$BACKUP_USER/.ssh/authorized_keys"

log "done."
