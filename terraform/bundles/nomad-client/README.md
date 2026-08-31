# Nomad client bundle

Creates a Nomad client Auto Scaling Group in the base bundle's private subnet,
using the newest self-owned `nomad-client-*` AMI. Instances have no public IPv4
address. The security group allows all traffic from the public subnet for the
Tailscale subnet router, Nomad API and RPC traffic plus the default dynamic
allocation range from the private subnet, and Consul LAN gossip from the
private subnet. The public-subnet rule also permits any other EC2 instances
placed in that subnet.

The shared ASG module manages the launch template and Auto Scaling Group. Each
instance receives an IAM role with the read-only EC2 permissions required for
Nomad and Consul AWS cloud auto-join. Cloud-init writes runtime configuration
that discovers Nomad servers through `Role=nomad-server` and Consul servers
through `Role=consul-server`; no server IPs are pinned.

Apply the base, Consul-server, and Nomad-server bundles first, and create a
Nomad client AMI with `make nomad-client-ami`, then apply this bundle:

~~~sh
cd terraform/bundles/base
tofu init
tofu apply

cd ../nomad-client
tofu init
tofu apply \
  -var='username=after' \
  -var='ssh_public_key=ssh-rsa AAAA...'
~~~

The selected AMI is refreshed automatically when a newer matching AMI exists.
User data is stored in Terraform state, so protect the state file. If the ASG
is scaled above one instance, ensure the Nomad and Consul server capacity is
ready to accept the clients. System allocations are drained last and are not
replaced on the draining client; Nomad places them on another eligible client.
