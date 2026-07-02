# terraform/environments/prod/

Root module for the prod environment — wires the modules together and holds this
installation's values as tfvars (IPs, CIDRs, hostnames; secret *references*, not secrets).
State in the GCS backend (`malachowski-state`, prefix `prod`). Run with `tofu` (not
`terraform`); `make plan` / `make apply` target this directory.
