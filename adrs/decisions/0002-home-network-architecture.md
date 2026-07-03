# 0002. Home network architecture

- Status: Accepted
- Date: 2026-07-03

## Context and problem statement

A single segmentation-aware MikroTik router serves the home network, which has two
internet uplinks: a primary cable connection and an LTE backup. Differently-trusted
devices share that one network — personal, IoT, guest and travel are separate device
categories — while self-hosted service workloads share a single compute host. The site
has no reliable inbound path from the internet, yet remote and travel access must work
anyway. How should the home network be structured so that a compromise stays contained,
remote and travel access work without exposure, and connectivity survives an uplink
outage?

## Decision drivers

- Contain blast radius: a compromised, internet-exposed or integration-heavy workload
  must not reach infrastructure (management) or user devices (trusted).
- Survive a primary-uplink outage automatically, without wasting constrained backup data.
- Reach the network remotely, and onboard travel devices, with no per-device setup and
  no exposure to the internet.
- Segment on the axis that actually drives blast radius — internet exposure — rather than
  on what a device *is* (server, appliance, IoT).
- Keep each zone carrying a distinct, maintainable policy; a VLAN nobody can write a
  durable rule for is sprawl, and a misconfigured rule is itself a risk.
- Keep it on the single existing router for now, without precluding future gear.

## Considered options

- Flat network vs. trust-zone segmentation.
- Automatic uplink failover vs. load-balancing vs. manual switching.
- Inbound exposure (port-forwarding) vs. outbound-only remote access.
- Segmentation axis: by device role vs. by internet exposure.
- Public exposure: a home DMZ/public-facing zone vs. keeping the home network zero-public.

## Decision outcome

- **Segment the LAN into separate trust zones** on the single segmentation-aware router,
  with a **default-deny** policy between zones and one-way trust toward less-privileged
  zones.
- **Segment and assign zones by internet exposure, not by role.** Exposure is the axis that
  drives blast radius, so it is the axis we segment on. Self-hosted service workloads get
  a `services` tier **distinct from management**, so an integration-heavy appliance never
  sits in the most-privileged zone alongside the router and hypervisor.
- **Automatic failover** from the primary uplink to the LTE backup (no load-balancing),
  driven by **real internet-reachability checks** rather than mere link or gateway state —
  the immediate gateway can stay up when its upstream is down.
- Keep the network **zero-inbound**: remote access and the travel router both ride
  **outbound-initiated WireGuard**, so nothing is exposed. Travel devices are onboarded by
  a dedicated travel router and land in their own zone.
- Keep the home network **zero-public** — no public-facing or DMZ zone is exposed at
  home, and nothing is served inbound, so public-service availability never depends on
  the home WAN. Public workloads therefore cannot be hosted at home; where they and
  other home workloads actually run is a placement decision (see the forthcoming compute
  & workload-placement ADR).

### Consequences

- Good — contained blast radius between zones; a compromised service workload cannot pivot
  to the router, hypervisor or laptops; resilient to primary-WAN loss; remote/travel
  access works behind double-NAT/CGNAT with no open ports; the zone set maps one-to-one to
  policies actually maintained; no internet exposure on the home LAN.
- Bad — public services cannot be hosted at home and must be placed elsewhere (their
  placement is deferred to the compute & workload-placement ADR); the backup path is
  constrained and outbound-only; enabling segmentation and default-deny must be staged
  carefully to avoid locking out management; cross-VLAN device discovery needs an mDNS
  reflector between zones.
- Note / follow-up — concrete subnets, zone/VLAN IDs, the trust matrix, reachability
  targets, ports and firewall rules live in the tracking issues and the resulting RouterOS
  config, not here. Restates, for the rebuilt tree, the network intent of historical ADR
  0001 (git ref `a1efde8`) and ADR 0006 (git ref `cb2a8e3`); 0006's workload-placement
  half (public workloads off-home) is carried by the forthcoming compute &
  workload-placement ADR.
