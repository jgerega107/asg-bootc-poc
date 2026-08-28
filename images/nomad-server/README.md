# Nomad server bootc image

This image runs Nomad 2.0.5 as a single bootstrap server on Fedora bootc. Set
`bootstrap_expect` to the intended odd server count for production. Cloud-init
is installed; use the repository's `cloud-init/nomad-server.yaml` example to
set the Vault address and other first-boot configuration.

The example writes the Nomad server join settings to
`/etc/nomad.d/90-runtime.hcl` and joins the Consul servers through an AWS
`retry_join` expression in `/etc/consul.d/90-runtime.hcl`. Nomad uses its local
Consul agent for automatic server discovery and advertises a health-checked
`nomad` service there. Servers do not receive a Vault address. Nomad and its
Consul client are ordered after `cloud-config.service` and require their
runtime HCL files.
