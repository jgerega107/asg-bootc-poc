# Nomad client bootc image

This image runs Nomad 2.0.5 as a root client, as required for Linux workload
isolation. Docker (`moby-engine`) is installed and enabled, and the bundled
Docker task driver is configured with bind and named-volume support. Cloud-init
can set the Nomad servers and Vault address on first boot.

Cloud-init writes `/etc/nomad.d/90-runtime.hcl` directly with the stable Nomad
server and Vault endpoints. Nomad is ordered after `cloud-final.service` and
does not start unless that runtime configuration file is present and non-empty.
