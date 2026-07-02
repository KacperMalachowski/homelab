# terraform/modules/

Reusable OpenTofu modules. Map-driven where scale matters (add a node / VLAN / record =
add a map entry). No hard-coded addresses — values arrive as variables; the environment
root supplies this installation's values from its tfvars.

Planned: `routeros-network`, `proxmox-node`, `k3s-vm`, `k3s-cluster`,
`homeassistant-vm`, `dns-records`.
