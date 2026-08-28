# VM

Creates one EC2 instance with a single configurable root disk. The module does
not create standalone EBS volumes; the root disk is managed through the
instance's root_block_device.

~~~hcl
module "vault_vm" {
  source = "../../modules/vm"

  name           = "vault"
  ami            = var.vault_ami_id
  instance_type  = "t3.small"
  root_disk_size = 30
  subnet_id      = module.vpc.private_subnet_id

  user_data = file("${path.module}/cloud-init/vault.yaml")
}
~~~

user_data accepts rendered cloud-init text, including YAML beginning with
#cloud-config, or any other string accepted by EC2 user data. It can also be
loaded from a file with Terraform's file() function. Changing it replaces the
instance so cloud-init runs with the new content.

The instance and root disk receive a Name tag based on name; additional
tags can be supplied through tags.
