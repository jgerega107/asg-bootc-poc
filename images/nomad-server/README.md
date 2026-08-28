# Nomad server bootc image

This image runs Nomad 2.0.5 as a single bootstrap server on Fedora bootc. Set
`bootstrap_expect` to the intended odd server count for production. Cloud-init
is installed; use the repository's `cloud-init/nomad-server.yaml` example to
set the Vault address and other first-boot configuration.

The example writes the stable Nomad peer endpoint directly to
`/etc/nomad.d/90-runtime.hcl`. Servers do not receive a Vault address. Nomad is
ordered after `cloud-config.service` and requires the runtime HCL file.
