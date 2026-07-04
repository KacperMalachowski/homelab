# scripts

Host-side setup scripts for things that have no cloud API or provider and so
can't live in OpenTofu — raw host OS work on the Proxmox node.

## `pve-backup-setup.sh`

Codifies the pve-host side of the tested-offsite-backups work (#252, ADR 0005):
the local vzdump backup volume + PVE storage, the nightly vzdump job, and the
PVE-privilege-free `backup-ro` account whose SSH key is `rrsync`-pinned to
read-only access of the dump directory (its private key lives in GCP Secret
Manager as `pve-backup-ssh-key`).

Idempotent — safe to re-run. Run as root **on** the pve host:

```sh
scp scripts/pve-backup-setup.sh root@pve:/tmp/ && ssh root@pve bash /tmp/pve-backup-setup.sh
```

The offsite push (restic → GCS, keyless via Workload Identity Federation) is a
scheduled workflow, not part of this script:
`.github/workflows/backup-offsite.yml`.
