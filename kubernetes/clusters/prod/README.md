# kubernetes/clusters/prod/

The controller's entrypoint for the prod cluster: its bootstrap (`flux-system` once the
delivery tool is decided in ADR 0004) and the top-level kustomizations that pull in
`infrastructure/` and `apps/`.
