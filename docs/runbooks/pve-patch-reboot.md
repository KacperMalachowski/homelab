# Runbook: patch & reboot the Proxmox host

Covers the periodic host patch + reboot for the single Proxmox node `pve`
(`192.168.99.100`). The box is an i5 desktop with **no IPMI/remote console** — if
it fails to boot you need physical keyboard/monitor, so run the reboot when you
can reach it. Background: #258 (cadence), feeds #239 (runbooks).

## Before the reboot

1. **Backups are current.** Trigger the nightly job by hand so the newest state is
   captured before touching the kernel:
   ```sh
   ssh root@192.168.99.100 'vzdump 100 101 --storage backup-local --mode snapshot --compress zstd'
   ```
   (Offsite restic copy follows on the next `backup-offsite` workflow run — see
   ADR 0005 / #252.)
2. **Auto-start is set.** All guests that should return after a reboot have
   `onboot=1`: `100` HAOS (VM), `101` pihole, `200` debowa-wp, `201` claude-code,
   `1001` approve-env. Verify:
   ```sh
   ssh root@192.168.99.100 'for id in 101 200 201 1001; do echo -n "$id "; pct config $id | sed -n "s/^onboot: //p"; done; qm config 100 | sed -n "s/^onboot: /100 /p"'
   ```

## Patch + reboot (run from the host console or SSH)

```sh
apt-get update
apt-get -y dist-upgrade      # ~year of updates on first run; pulls a new kernel
reboot
```

If `dist-upgrade` prompts about changed config files, keep the local version
unless you know otherwise. After it completes, `reboot` activates the new kernel.

## After the reboot (checklist)

```sh
ssh root@192.168.99.100 '
  uname -r; uptime -p                       # new kernel, uptime reset
  qm list; pct list                         # all guests running
'
```
Then verify services actually came back:
- **101 Pi-hole** — `pct exec 101 -- systemctl is-active pihole-FTL` (DNS/adblock up).
- **100 HAOS** — Home Assistant UI reachable; radios/integrations online.
- **200 debowa-wp** — `pct exec 200 -- systemctl is-active mariadb nginx php8.3-fpm`; site loads.
- **201 claude-code** — `pct exec 201 -- systemctl is-active claude` then
  `tmux attach -t claude` (the session auto-starts via the `claude.service` unit).
- **DNS** resolves on the LAN (the router is the resolver today; Pi-hole is not
  primary yet — see #253).

If the host does **not** come back: attach a monitor/keyboard, pick the previous
kernel from the GRUB "Advanced options" menu to boot, then investigate.

## Recurring cadence

- **Debian CTs (101/200/201/1001):** `unattended-upgrades` is installed and
  enabled — security updates apply automatically (`apt-daily-upgrade.timer`).
- **Host:** no unattended upgrades on the hypervisor by design; run this runbook
  **monthly-ish** (or when a PVE/security advisory lands).
- **HAOS (100):** check the update policy in the Home Assistant UI (Settings →
  System → Updates); apply core/OS updates on its own cadence.
