# Vault bundle

Creates one Vault EC2 instance in the base bundle's private subnet using the
newest self-owned AMI whose name matches `vault-*`. The instance has no public
IPv4 address and uses only its root disk for Vault data. Its security group
allows SSH only from the base bundle's public subnet, so the instance can be
reached through the subnet router without exposing SSH to the internet.

Apply the base bundle first so its local state contains the VPC and subnet
outputs, then create or import a Vault AMI with `make vault-ami`:

~~~sh
cd terraform/bundles/base
tofu init
tofu apply

cd ../vault
tofu init
tofu apply \
  -var='username=after' \
  -var='ssh_public_key=ssh-rsa AAAA...'
~~~

The bundle selects the newest matching AMI automatically. Override
`ami_name_pattern` when using a different naming prefix. The default instance
type is `t3.micro` and the root disk is 20 GiB.

`username` and `ssh_public_key` are installed through cloud-init. User data is
stored in Terraform state, so protect the state file. Because the instance is
stored in Terraform state, so protect the state file. Because the instance is
private, access requires a path through the subnet router or another private
connection. The bundle always attaches its SSH security group; pass
`vpc_security_group_ids` to attach additional security groups.
