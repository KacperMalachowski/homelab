# 0006. Trust tiers and workload exposure placement

- Status: Accepted
- Date: 2026-06-30

## Context and problem statement

ADR [0001](0001-network-and-connectivity.md) segments the LAN into trust zones;
ADR [0002](0002-compute-and-workload-placement.md) places workloads. Operating the
lab surfaced two gaps. First, self-hosted services (Home Assistant) had no zone of
their own and ended up in **management** — the most-privileged zone — giving a fat,
integration-heavy appliance a path to the router and hypervisor if it were ever
compromised. Second, "where does a workload go?" was being answered by what a
workload *is* (server, appliance, IoT) rather than by its **internet exposure**,
which is what actually drives blast radius. How should we tier trust and place
workloads so that a compromise stays contained?

## Decision drivers

- Contain blast radius — a compromised, internet-exposed, or integration-heavy
  workload must not reach infra (mgmt) or user devices (trusted).
- Keep the zone count to segments that each carry a **distinct, maintained policy**;
  a VLAN nobody can write a durable rule for is sprawl, and a misconfigured rule is
  itself a risk.
- Client-facing services should stay up independently of the home WAN.
- Stay simple and hand-operable — refine the live design in place, do not redesign.

## Considered options

- Service placement: leave services in `mgmt` vs. a dedicated `services` tier vs.
  fold them into `trusted`.
- Segmentation axis: by **role** (server / appliance / IoT) vs. by **internet
  exposure**.
- Public-facing workloads: a home DMZ/public pool (per ADR 0002) vs. exile to the
  existing cloud cluster.
- Home Assistant (a VM) + private k3s: separate tiers vs. co-located in `services`.

## Decision outcome

- **Introduce a `services` trust tier, distinct from `mgmt`.** Self-hosted apps
  (Home Assistant, private k3s and the addresses it exposes) live there; `mgmt`
  returns to infra-only. `services` may reach IoT/NoT to control devices and the
  internet for updates, but **not** `mgmt` or `trusted` — one-way trust.
- **Segment and place by internet exposure, not by role.** Exposure is the axis
  that drives blast radius, so it is the axis we segment on.
- **Public-facing workloads run in the cloud** (the existing Hetzner cluster), not
  at home — so the home network stays zero-public and client-facing uptime does not
  depend on the home WAN. ADR 0002's home DMZ/public pool is **deferred** until
  there is a real reason to host public services at home.
- **Home Assistant and private k3s co-locate in `services`** (a single VLAN). With
  the exposed tier no longer at home, there is nothing untrusted for HAOS to share a
  broadcast domain with; the k3s nodes are hardened host-side (API/kubelet
  restricted to the cluster) as defence in depth.
- The **active trust tiers are `mgmt`, `trusted`, `services`, `iot`, `not`,
  `guest`** (six), with **`lab` and `travel` defined but dormant** until populated.
  `NoT` (internet-denied) stays a VLAN rather than a per-device rule — the VLAN is
  the scalable, default-contained policy boundary.

### Consequences

- Good — a compromised Home Assistant or home workload cannot pivot to the router,
  hypervisor, or laptops; internet exposure is off the home network entirely; the
  zone set maps one-to-one to policies we actually maintain.
- Bad — cross-VLAN device discovery now needs an mDNS reflector between `services`
  and IoT/NoT; public hosting depends on the cloud cluster; ADR 0002's home public
  pool is shelved rather than built.
- Note / follow-up — this **refines** ADR [0001](0001-network-and-connectivity.md)
  (adds the `services` tier) and ADR
  [0002](0002-compute-and-workload-placement.md) (public → cloud; home pool
  deferred); neither is fully superseded. Concrete VLAN IDs, subnets, the trust
  matrix, and the Proxmox trunk change live in the tracking issues and the resulting
  RouterOS / Proxmox config, not here.
