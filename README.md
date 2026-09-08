# ASG bootc

Bootable container images and Terraform infrastructure for running Consul, Nomad, and Vault on AWS Auto Scaling Groups.

## Repository layout

- `cloud-init/` - Cloud-init configurations for Nomad servers and clients.
- `compose/` - Runtime configuration used by the local Compose setup.
- `examples/` - Example Nomad job files.
- `images/` - Bootc image definitions and service configuration for Consul, Nomad, and Vault.
- `output/` - Generated disk images and manifests. This directory is ignored by Git.
- `terraform/` - OpenTofu/Terraform bundles and reusable infrastructure modules.

Root-level files provide the Compose configuration (`compose.yaml`), image-builder settings (`config.toml`), and build targets (`Makefile`).
