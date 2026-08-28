# Tailscale subnet router

Creates a small Ubuntu EC2 instance in the base bundle's public subnet and
configures it as a Tailscale subnet router for the private application subnet.
The instance is created through the shared VM module and is configured entirely
with cloud-init.

## Prerequisites

Apply the base bundle first so its local state contains the VPC and subnet
outputs:

~~~sh
cd terraform/bundles/base
tofu init
tofu apply
~~~

Create a Tailscale auth key suitable for unattended provisioning, then apply
this bundle:

~~~sh
cd terraform/bundles/subnet-router
tofu init
tofu apply \
  -var='username=after' \
  -var='ssh_public_key=ssh-rsa AAAA...' \
  -var='tailscale_auth_key=tskey-auth-...'
~~~

The `username` and `ssh_public_key` variables are added to the router through
its cloud-init configuration.

The default router uses the latest Ubuntu 24.04 AMD64 AMI and a t3.micro
instance. Override instance_type, root_disk_size, or the Ubuntu AMI filters
when needed.

The router enables IP forwarding, advertises the base bundle's private subnet,
and disables EC2 source/destination checking. Approve the advertised route in
the Tailscale admin console. Linux tailnet clients may also need to enable
route acceptance.

Private workload security groups must allow the router's security group as an
inbound source for the application ports that should be reachable over
Tailscale. The router security group permits UDP 41641 from the internet and
allows all outbound traffic; it does not expose SSH.

The auth key is sensitive Terraform input, but cloud-init user data is still
stored in Terraform state because EC2 receives it at launch. Protect the state
file and use a short-lived or reusable Tailscale key according to your
tailnet's policy.
