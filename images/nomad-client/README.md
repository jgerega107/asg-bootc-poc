# Nomad client bootc image

This image runs Nomad 2.0.5 as a root client, as required for Linux workload
isolation. Docker (`moby-engine`) is installed and enabled, and the bundled
Docker task driver is configured with bind and named-volume support. A Consul
client is installed alongside Nomad. Cloud-init can set the Nomad servers,
Vault address, and Consul AWS auto-join settings on first boot.

Cloud-init writes `/etc/nomad.d/90-runtime.hcl` directly with the stable Nomad
server and Vault endpoints, and writes the Consul client join settings to
`/etc/consul.d/90-runtime.hcl`. Nomad and Consul are ordered after
`cloud-config.service` and do not start unless their runtime configuration is
present and non-empty. Clients leave the Nomad cluster and drain allocations
for up to five minutes when they receive a shutdown signal.
