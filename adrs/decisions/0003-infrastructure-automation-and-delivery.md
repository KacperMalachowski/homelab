# 0003. Infrastructure automation and delivery

- Status: Accepted
- Date: 2026-06-11

## Context and problem statement

The homelab should be managed as code and applied from GitHub. Reaching the LAN
requires a self-hosted runner, but the repository is **public** — a dangerous
combination, since untrusted fork code could otherwise execute next to the
network, hypervisor, and secrets. An existing pattern already works well:
Terraform plus a cloud secret manager via OIDC, with plan/apply/drift workflows.
How should home infrastructure be automated and delivered?

## Decision drivers

- Reach on-prem devices safely from CI.
- Eliminate the public-repo remote-code-execution path.
- Reuse existing patterns; minimise new tools.
- Never lock the automation out of the device it is changing.

## Considered options

- Runner safety: harden the public repo vs. a private automation repo vs. make the
  whole repo private.
- Tooling: a single tool (all-Terraform) vs. Terraform + Ansible + ArgoCD.
- Network-device changes from CI: apply directly vs. apply with auto-rollback.

## Decision outcome

- **Manage everything as code with a small toolset**: Terraform for provisioning,
  Ansible for device/OS configuration, and ArgoCD for in-cluster delivery.
- **Run a self-hosted, ephemeral runner inside the network** on a node decoupled
  from the workloads it manages, and **harden the public repo** so untrusted code
  can never execute on it — with making the repo private as the escape hatch if
  that upkeep proves too costly.
- **Guard network-device changes applied from CI with automatic rollback**, so a
  bad apply self-heals instead of locking out the router and the runner.
- **Keep no long-lived secrets on the runner**; fetch them at run time via the
  existing OIDC / secret-manager pattern.

### Consequences

- Good — safe LAN automation; reuses proven secret handling; the control plane
  survives reconfiguring the workload host; risky network changes have a safety net.
- Bad — hardening a public repo is ongoing, mechanical upkeep that must stay
  correct (private is the escape hatch); Ansible is one added tool.
- Note — specific workflow triggers, environment/approval settings, runner
  placement and rollback mechanics live in the tracking issues and config.
