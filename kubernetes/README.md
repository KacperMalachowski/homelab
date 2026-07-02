# kubernetes/

GitOps root. The in-cluster controller reconciles this path and only this path (ADR 0001);
infrastructure commits elsewhere in the repo are filtered out. Kept self-contained so a
future public-facing cluster can be extracted to its own repository.

- `clusters/prod/` — controller entrypoint (bootstrap + cluster-level kustomizations).
- `infrastructure/` — platform services (ingress, cert-manager, storage, external-secrets, monitoring).
- `apps/` — one directory per workload.
