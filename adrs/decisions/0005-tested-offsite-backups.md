# 0005. Tested offsite backups

- Status: Proposed
- Date: 2026-07-04

## Context and problem statement

A single Proxmox host runs the home workloads, and it has **no backups at all** and
no proven recovery path — a state we do not want to carry into the first reboot in a
year, let alone a disk failure. A backup nobody has ever restored is not a backup. We
want a cheap, honest 3-2-1 now, ahead of a fuller backup build-out later, without
standing up new infrastructure or holding long-lived cloud credentials on the host,
and while the site has no reliable inbound path from the internet. How do we get a
trustworthy backup-and-restore story on the cheap that we can grow into?

## Decision drivers

- A backup is only real once a restore into a scratch target has actually succeeded —
  proving restore has to be part of "done", not assumed.
- 3-2-1 on the cheap: a local copy for fast recovery and an encrypted offsite copy for
  disaster recovery, reusing what we already run rather than buying or building new.
- Keep the offsite copy encrypted, bounded in size, and cheap at rest.
- Avoid a long-lived cloud credential sitting on the host, and avoid standing up our own
  internet-facing identity provider just to avoid one.
- Databases must be captured consistently, not as a live-file copy that can be torn.
- Don't over-build ahead of the fuller backup effort; this should *seed* it, not pre-empt it.

## Considered options

- Local engine: Proxmox `vzdump` (built-in) vs. a dedicated Proxmox Backup Server vs.
  running the offsite tool directly against live guests.
- Offsite target: Backblaze B2 vs. Google Cloud Storage vs. Google Drive/Dropbox vs. a
  Hetzner Storage Box.
- Offsite transport/encryption: an encrypting, deduplicating backup tool vs. an
  encrypt-and-sync of plain image files.
- Offsite authentication: a service-account key on the host vs. keyless federation from
  an existing CI runner vs. a self-hosted OIDC issuer feeding cloud federation.
- Offsite retention: object-lifecycle deletion by age vs. retention managed by the
  backup engine.

## Decision outcome

- **Two tiers.** A local, native `vzdump` copy on a dedicated on-box disk gives a fast,
  first-class restore path; an **encrypted, deduplicating** copy is then pushed **offsite
  to object storage**. This is deliberately the cheap seed of the fuller backup build-out,
  not a competing design.
- **Offsite target is our existing cloud object storage**, on a cold storage class —
  we already depend on that provider, so no new vendor, and cold class keeps it cheap at
  rest. Drive/Dropbox-style consumer storage is rejected as not being an object store.
- **The offsite push is keyless.** It runs from the **existing self-hosted CI runner**,
  which federates its CI-native OIDC identity to a cloud identity — so there is **no
  long-lived key on the host** and **no new identity provider** to stand up. The runner
  reads the local backup copy over the management network.
- **Retention is managed by the backup engine, not by object-lifecycle deletion.** The
  offsite copy is a deduplicating repository whose objects are shared across snapshots, so
  age-based bucket deletion would corrupt it; pruning is the engine's job.
- **Consistency before imaging.** Where a workload has a database, it is dumped by its own
  consistent mechanism before the image snapshot rather than captured live. (Today the
  only such case is Home Assistant's native backup; there is no external database in the
  current set.)
- **Restore is the acceptance test.** The work is not done until a backup has been
  restored into a scratch target and verified.

### Consequences

- Good — a fast local restore path plus an encrypted, bounded offsite copy; no long-lived
  cloud key on the host and no new identity provider; reuses the compute, runner, and cloud
  account we already have; consistent database capture; and a restore we have actually
  performed rather than hoped for.
- Bad — the nightly offsite copy now depends on the CI runner and CI availability; the
  cold storage class imposes a minimum-storage duration that bounds how often we can prune;
  and the tofu state backend has to be bootstrapped before any of this can be codified.
- Note / follow-up — concrete bucket name, region and class, the guest include-list,
  retention counts, federation pool/provider IDs and runner labels live in the tracking
  issue (#252) and the resulting config, not here. This seeds the fuller restic build-out
  (Epic F, #238); Vaultwarden is out of scope (the owner uses a local KeePass file, not a
  server database).
