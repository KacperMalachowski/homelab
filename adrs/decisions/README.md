# Architecture Decision Records

Significant architecture decisions for the homelab, recorded in the
[MADR](https://adr.github.io/madr/) format.

## Why

Decisions made during design tend to evaporate, leaving only the *what* and not
the *why*. ADRs capture the context and rationale so future contributors (and
future us) can understand why things are the way they are — and revisit them
deliberately rather than by accident.

ADRs record **decisions, not implementation detail**. Concrete values (subnets,
IDs, ports, labels, tunables) live in the tracking issues and the resulting
Terraform / Ansible / RouterOS config, not here, so an ADR stays valid even as the
implementation changes.

## Process

1. Copy `0000-template.md` to `NNNN-short-title.md` using the next free number.
2. Draft with status **Proposed**.
3. Once agreed, change status to **Accepted**.
4. Never delete an ADR. If a decision changes, write a new ADR and mark the old
   one **Superseded by [NNNN](...)**.

## Index

| ADR | Title | Status |
|-----|-------|--------|
| [0001](0001-network-and-connectivity.md) | Network and connectivity architecture | Accepted |
| [0002](0002-compute-and-workload-placement.md) | Compute and workload placement | Accepted |
| [0003](0003-infrastructure-automation-and-delivery.md) | Infrastructure automation and delivery | Accepted |
