# 0008. Security monitoring

- Status: Accepted
- Date: 2026-07-03

## Context and problem statement

The home network is segmented into trust zones with a default-deny posture (ADR 0002),
but nothing actively watches for trouble: no signal when a device is compromised, when a
service is being brute-forced or scanned, when a host is tampered with, or when a workload
reaches out to a known-bad destination. The estate is small and run by a single
administrator on modest hardware — one 16 GB compute host, a low-power always-on box, and
the router. How should security be monitored and responded to, without the monitoring
outweighing what it protects?

## Decision drivers

- Proportionality: the monitoring must be sized to a single modest host and one
  administrator — it cannot claim a large share of the box it runs on, nor demand ongoing
  tuning effort nobody has.
- Detection *and* response: seeing an attack is only half the value; the common cases
  (brute force, scanning) should be blocked automatically at the network edge.
- Reuse existing signals: DNS (Pi-hole), router firewall logs and host auth logs already
  exist — a solution should consume them rather than stand up parallel collection.
- Preserve zero-inbound (ADR 0002): notifications go outbound; no dashboard or listener is
  exposed.
- Contain blast radius on a segmented network: a new device, or lateral movement between
  zones, should be observable.
- Keep a clean upgrade path to a heavier stack later, without paying for it now.

## Considered options

- A full SIEM / XDR (e.g. Wazuh: manager + OpenSearch indexer + dashboard + agents).
- A lightweight, log- and host-based approach: a behavioural IPS (CrowdSec) plus targeted
  host and image checks, feeding on signals already present.
- Nothing beyond the firewall / defer entirely.

## Decision outcome

Adopt the **lightweight, log- and host-based approach**, and explicitly reject a full SIEM
at the current scale.

- **CrowdSec is the detection-and-response core.** It parses host and service logs, detects
  malicious behaviour (brute force, scanning, probing), and enforces via a **bouncer on the
  router**, blocking offenders at the edge. It notifies **outbound**.
- **Host integrity** is watched with a file-integrity tool on the compute host and the
  always-on box; **container/OS images** are scanned for known vulnerabilities on a schedule.
- **Existing signals are consumed, not duplicated**: Pi-hole hits on known-bad domains (a
  compromised-device tripwire), router firewall drops, and host auth events (SSH/sudo), plus
  a new-device-on-VLAN alert.
- Only if and when the observability stack is built (as a learning exercise) are these
  signals routed into it for dashboards; the security posture does not depend on that stack
  existing.
- **A full SIEM (Wazuh) is rejected now** as disproportionate — its indexer alone would
  claim a large fraction of the 16 GB host to watch a handful of services — and **deferred to
  Phase 2** (dedicated rack hardware) or to occasional, throwaway learning spikes.

### Consequences

- Good — real detection and automatic edge-blocking at a few hundred MB of footprint;
  leverages logs and DNS already present; no inbound exposure; fits one administrator's
  tuning budget; a SIEM stays cleanly deferred until hardware and need justify it.
- Bad — no centralised long-term log retention, correlation or forensics until the
  observability stack (or a Phase-2 SIEM) exists; CrowdSec's automatic blocking needs an
  admin-network safelist to avoid self-lockout; several small tools to maintain rather than
  one platform.
- Note / follow-up — concrete CrowdSec collections/scenarios, the bouncer, notification
  targets, file-integrity and image-scan schedules, and the new-device alert live in the
  epic G tracking issues (#244, sub-issues #245–#248) and config, not here. Uses ADR number
  0008; 0003–0007 are reserved by the roadmap (compute, GitOps, secrets, observability, DR).
