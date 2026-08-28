# Fedora bootc Consul server image

This image runs Consul 2.0.3 as a single bootstrap server on Fedora bootc.
Cloud-init is installed so a bundle can add first-boot settings such as
`retry_join`, node metadata, TLS, and ACL configuration.

The Consul service is based on HashiCorp's packaged systemd unit. It uses
`Type=notify`, the Consul agent config directory, a graceful `SIGTERM`, and the
service restart and file-descriptor limits from the upstream unit. The base
configuration retries joining its own dynamically selected private address so
that a single server can complete the LAN join required for the systemd
readiness notification. A runtime `retry_join` file can override this for a
multi-server deployment:

<https://github.com/hashicorp/consul/blob/main/.release/linux/package/usr/lib/systemd/system/consul.service>

The base configuration enables server mode with `bootstrap_expect = 1`, uses
`/var/lib/consul` for persistent state, selects the private address on the
default route for gossip, enables the Consul UI, and lets Consul choose the
instance name from the host name. For a multi-server deployment, override
`bootstrap_expect` and add an AWS `retry_join` stanza in a runtime HCL file.

The Consul archive is pinned and SHA-256 verified for amd64 and arm64 builds.
When updating `CONSUL_VERSION`, update the architecture-specific checksums in
the `Containerfile` too.

## Build

```sh
podman build -t localhost/fedora-bootc-consul-server:latest -f Containerfile .
```

## Configuration and persistent data

Consul reads `/etc/consul.d/consul.hcl` and any additional files in that
directory. The service creates and preserves `/var/lib/consul` through
`StateDirectory=consul`.

The base image does not enable TLS or ACLs. Configure both before exposing the
HTTP, DNS, or gossip ports outside a trusted network.
