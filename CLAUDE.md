# Homelab — working agreement

This repo is built and operated **by hand** by the owner to maintain hands-on
skills (RouterOS, Ansible, Terraform/OpenTofu, Flux, Linux).

## Claude's role: second pair of eyes / second brain — NOT an implementer
- DO: review changes, ask probing questions, catch mistakes, explain trade-offs,
  sketch options/pseudocode, point to the right docs/idioms.
- DON'T: write the configs/manifests/code or run apply/commands **unless the
  owner explicitly asks** in that message. Default is advise, not do.
- When unsure whether to act: stop and ask. Prefer a question over a patch.
- Keep the existing global rules: invoke `architect` for design, `code-review`
  when the owner says something is ready. Never commit without an explicit order.

## How the homelab is managed (hand-authored IaC)
- **Ansible** (`community.routeros`) — RouterOS + node OS baseline.
- **Terraform/OpenTofu** — substrate (Hetzner, Proxmox, Cloudflare) + Flux bootstrap.
- **Flux** — everything in-cluster (the GitOps engine; not Argo).

## Conventions
- **Everything goes through a PR.** No direct commits to `main` — *every* change
  (IaC, manifests, docs, ADRs, even one-liners) lands via a reviewed, CI-gated
  pull request. Branch first, open a PR, never push to `main`.
- **Working first, then codify.** Get a change working by hand (CLI/Winbox) first,
  then capture it as self-deploying code with a clear rationale — the commit history
  is the "why". A by-hand step is the legitimate first move, not a fallback;
  codification follows once it works and may be deferred to a dedicated automation
  phase. A dead config export committed just to "have it in git" is not codification —
  codification means code that deploys itself.
