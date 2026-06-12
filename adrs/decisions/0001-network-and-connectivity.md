# 0001. Network and connectivity architecture

- Status: Accepted
- Date: 2026-06-11

## Context and problem statement

A single MikroTik router serves the home network, which has two internet uplinks:
a primary cable connection and an LTE backup. Devices of differing trust —
personal, IoT, guests, and travel devices — share the same hardware. The site has
no reliable inbound path from the internet, and remote/travel access must work
anyway. How should the network be structured to be secure and reliable?

## Decision drivers

- Isolate trust zones so IoT/guest devices cannot reach trusted ones.
- Survive a primary-uplink outage automatically, without wasting backup data.
- Reach the network remotely, and onboard travel devices, with no per-device setup
  and no exposure to the internet.
- Keep it on the single existing router for now, without precluding future gear.

## Considered options

- Flat network vs. trust-zone segmentation.
- Automatic uplink failover vs. load-balancing vs. manual switching.
- Inbound exposure (port-forwarding) vs. outbound-only remote access.

## Decision outcome

- **Segment the LAN into separate trust zones** on a single segmentation-aware
  router, with a **default-deny policy** between zones.
- **Automatic failover** from the primary uplink to the LTE backup (no
  load-balancing), keeping the upstream router's existing NAT. Failover is driven
  by real internet-reachability checks, not merely link or gateway state, because
  the immediate gateway can stay up when its upstream is down.
- Keep the network **zero-inbound**: remote access and the travel router both ride
  **outbound-initiated WireGuard** (MikroTik Back To Home), so nothing is exposed.
  Travel devices are onboarded by a dedicated travel router and land in their own
  trust zone.

### Consequences

- Good — contained blast radius between zones; resilient to primary-WAN loss;
  remote/travel access works behind double-NAT/CGNAT with no open ports.
- Bad — inbound hosting is impossible by this path (public services are handled
  separately, see [0002](0002-compute-and-workload-placement.md)); the backup path
  is constrained and outbound-only; enabling segmentation and default-deny must be
  staged carefully to avoid locking out management.
- Note — concrete subnets, zone/VLAN IDs, reachability targets, ports and firewall
  rules live in the tracking issues and the resulting RouterOS config.
