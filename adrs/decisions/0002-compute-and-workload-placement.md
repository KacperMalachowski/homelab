# 0002. Compute and workload placement

- Status: Accepted
- Date: 2026-06-11

## Context and problem statement

Workloads run on a Proxmox host alongside a couple of Raspberry Pis, and we want an
on-prem Kubernetes cluster consistent with the existing Hetzner one. Some workloads
have special needs: Home Assistant requires USB radios and high uptime, and some
services must be reachable from the public internet despite the site being
zero-inbound (see [0001](0001-network-and-connectivity.md)). Where should each
class of workload run?

## Decision drivers

- Footprint and hands-on operability on a single, modest (16 GB) host.
- Consistency with the existing Talos/Hetzner cluster and tooling.
- Security-by-default and reliability of critical home services.
- Ability to host public services without inbound exposure.
- Blast-radius containment for anything internet-facing.

## Considered options

- On-prem Kubernetes distribution: Talos vs. a lighter distro (k3s).
- Home Assistant in Kubernetes vs. a dedicated VM.
- Public services: dedicated isolated pool vs. separate DMZ cluster; isolation by
  network policy vs. by separate network/cluster.

## Decision outcome

- **Run the on-prem Kubernetes cluster on Proxmox VMs using k3s.** Talos (as used
  on Hetzner) was the alternative; k3s was chosen for its lighter footprint on the
  modest host, simpler hands-on operation, and easier Raspberry Pi integration. The
  trade-off is accepted: the on-prem cluster diverges from the Hetzner Talos model,
  and its node OS must be managed (patched/hardened) rather than being immutable.
- **Run Home Assistant as a dedicated VM, not in Kubernetes**, so it keeps USB
  radio passthrough and its add-on ecosystem and is insulated from cluster churn.
- **Host public-facing services on a dedicated, isolated worker pool** within the
  cluster, exposed only via an **outbound Cloudflare Tunnel** (no inbound), with
  workload isolation enforced by **network policy** rather than a separate cluster.

### Consequences

- Good — light footprint leaves ample headroom on the host; easy to operate and
  extend (incl. SBC/RPi nodes); critical smart-home infra decoupled from the
  cluster lifecycle; public services with zero open ports and contained reach.
- Bad — diverges from the Hetzner Talos model (two operational paradigms); the node
  OS lifecycle (patching, hardening, SSH) must be managed via Ansible, and the
  setup is less immutable/secure-by-default than Talos — mitigated by hardening and
  keeping the host minimal. Home Assistant sits outside GitOps and needs its own
  backup path; soft (policy-based) isolation still leaves node-level cluster reach
  if a public workload is compromised — accepted for this threat model, upgradeable
  to a separate DMZ cluster later.
- Note — distribution version, node counts, sizing, pool labels/taints, namespaces
  and policies live in the tracking issues and config.
