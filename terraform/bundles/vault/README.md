# Vault bundle

Creates one Vault EC2 instance in the base bundle's private subnet using the
newest self-owned AMI whose name matches `vault-*`. The instance has no public
IPv4 address and uses only its root disk for Vault data. Its security group
allows all traffic from the subnet router, so the instance can
be reached through the subnet router without exposing it to the internet.

Apply the base and subnet-router bundles first so their local state contains the
VPC, subnet, and router outputs, apply the Consul-server bundle, then create or
import a Vault AMI with
`make vault-ami`:

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

The bundle selects the newest self-owned `vault-*` AMI automatically. The
default instance type is `t3.micro` and the root disk is 20 GiB.

`username` and `ssh_public_key` are installed through cloud-init. Cloud-init
also configures the embedded Consul client to join the Consul server instances
through AWS cloud auto-join; the server tag name is read from the Consul-server
bundle's local Terraform state. The shared VM module creates a read-only EC2
discovery role (`ec2:DescribeInstances` and `ec2:DescribeRegions`) and attaches
its instance profile for that lookup. User data is stored in Terraform state,
so protect the state file. Because the instance is private, access requires a
path through the subnet router or another private connection. The bundle always
attaches its SSH security group; pass `vpc_security_group_ids` to attach
additional security groups.
