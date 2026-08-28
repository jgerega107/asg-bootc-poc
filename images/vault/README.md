# Fedora bootc Vault image

This repository builds a bootable HashiCorp Vault appliance from the latest
official Fedora bootc base. The base supplies systemd, a kernel, initramfs,
bootloader integration, OSTree, and `bootc`; this image adds Vault 2.0.4, a
Consul client, and native systemd services. Cloud-init is installed for
cloud-provider and local NoCloud provisioning.

The Vault archive is pinned and SHA-256 verified for amd64 and arm64 builds.

## Build

```sh
podman build -t localhost/fedora-bootc-vault:latest -f Containerfile .
```

The Fedora base intentionally tracks `latest`. Vault itself is pinned; when
updating `VAULT_VERSION`, update the architecture-specific checksums too.

## Configuration and persistent data

Vault reads `/etc/vault.d/vault.hcl`. The included example uses integrated Raft
storage at `/var/lib/vault/data`; systemd creates and preserves `/var/lib/vault`
through `StateDirectory=vault`.

The Consul client reads `/etc/consul.d/consul.hcl` and its cloud-init-generated
`90-runtime.hcl` join configuration. Vault registers its API as the `vault`
service through the local Consul agent and marks sealed instances unhealthy.
The Consul service waits for `cloud-config.service` before starting.

The example listener disables TLS and is not production-ready. Before deploying,
provide trusted TLS material, set externally reachable `api_addr` and
`cluster_addr` values, and configure a suitable seal or auto-unseal mechanism.

## Install to a machine or VM disk

After pushing the image to a registry accessible from the target environment,
install it with `bootc install to-disk`. This erases the selected disk, so verify
the device name first:

```sh
sudo bootc install to-disk \
  --source-imgref docker://registry.example.com/fedora-bootc-vault:latest \
  /dev/vdX
```

On first boot, inspect and initialize Vault:

```sh
systemctl status vault
journalctl -u vault
vault status
vault operator init
```

Image updates use the normal bootc flow:

```sh
sudo bootc upgrade
sudo systemctl reboot
```
