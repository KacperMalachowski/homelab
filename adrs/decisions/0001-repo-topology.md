# 0001. Repository topology: a single monorepo

- Status: Accepted
- Date: 2026-07-02

## Context and problem statement

The homelab is built as code spanning a home network, on-premises compute, in-cluster
workloads, CI and a decision log. Provisioning lives in this repository while the cluster
manifests live in a separate repository consumed by the in-cluster GitOps controller. The
primary driver for how that code is organised is disaster recovery and portability —
restoring the whole homelab quickly, including after a physical move to a new home. How
should the code be organised across repositories?

## Decision drivers

- Disaster recovery / move: a rebuild under stress should follow a single ordered,
  step-by-step procedure — an aviation-style quick-reference handbook — not a
  reconciliation of versions across several repositories.
- Maintainability for a single administrator: a cross-cutting change (e.g. a new
  network zone plus the workload that lives in it) should be reviewable and revertable
  as one unit.
- Scalability of the process: one CI harness, one dependency-update configuration and
  one decision log covering every layer.
- GitOps controllers reconcile a repository path, so any layout must still give the
  controller a narrow, stable scope.

## Considered options

- Single monorepo — network, provisioning, cluster manifests, CI, ADRs and runbooks
  in one repository.
- Split repositories — infrastructure in one repository and cluster manifests in a
  separate GitOps repository (the prior arrangement).

## Decision outcome

Adopt a single monorepo. One clone at one commit reconstitutes the entire stack, which
directly serves the disaster-recovery and move goal, and cross-layer changes land
atomically in a single reviewed change. The GitOps controller is pointed at one
path-scoped directory so infrastructure commits it does not own are filtered out, and
that manifests directory is kept self-contained so a future public-facing cluster can
be extracted into its own repository later without disturbing the infrastructure roots.
The one property a separate manifests repository still buys — a narrow reconcile scope
for the controller — is provided just as well by path scoping, so it does not justify the
overhead of a second repository for a single-administrator setup.

### Consequences

- Good — a single source of truth; atomic cross-layer changes; one CI, dependency-bot
  and ADR log; the bootstrap sequence references a single revision.
- Good — a clean seam is preserved: the manifests directory can later be extracted for
  a public edge without touching the infrastructure roots.
- Bad — the read-only GitOps deploy credential can see the whole repository (acceptable
  for a private, single-administrator repository), and infrastructure commits produce
  churn the controller must path-filter away.
- Note / follow-up — the delivery tool and the exact watched path are decided
  separately (see the forthcoming GitOps delivery ADR); the concrete directory layout
  lives in the scaffold task and config, not in this ADR. Restates, for the rebuilt
  tree, the intent of historical ADR 0003 (git ref `8a6961d`).
