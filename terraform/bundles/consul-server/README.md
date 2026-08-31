# Consul server bundle

Creates a Consul server Auto Scaling Group in the base bundle's private subnet,
using the newest self-owned `consul-server-*` AMI. Instances have no public
IPv4 address. Its security group allows all traffic from the public subnet,
while Consul's server RPC, LAN gossip, WAN gossip, and DNS ports remain private
from other sources.

The Consul HTTP API and UI listen directly on the private instances at port
8500 and are allowed from the private subnet. Consul performs the service
health checks, while the Auto Scaling Group uses EC2 status checks.

Cloud-init creates the requested SSH user and writes a runtime Consul config
with an AWS `retry_join` expression matching the instances' `Name` tag. The
`bootstrap_expect` variable controls the expected initial server count; leave
it at one for a single-node development cluster and use an odd value for a
multi-server Consul cluster.

Apply the base bundle first and create a Consul server AMI with
`make consul-server-ami`, then apply this bundle before applying the Nomad or
Vault bundles. Those bundles read this bundle's `name` output from local state
to build their own Consul AWS cloud-auto-join expression:

~~~sh
cd terraform/bundles/base
tofu init
tofu apply

cd ../consul-server
tofu init
tofu apply \
  -var='username=after' \
  -var='ssh_public_key=ssh-rsa AAAA...'
~~~

The selected AMI is refreshed automatically when a newer matching AMI exists.
User data is stored in Terraform state, so protect the state file.
