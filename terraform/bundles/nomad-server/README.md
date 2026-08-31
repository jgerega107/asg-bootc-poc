# Nomad server bundle

Creates a Nomad server Auto Scaling Group in the base bundle's private subnet,
using the newest self-owned `nomad-server-*` AMI. Instances
have no public IPv4 address. Its security group allows all traffic from the
public subnet, and the instance role grants the read-only EC2
permissions Nomad and the embedded Consul client need for AWS cloud auto-join.

Nomad's HTTP API, RPC, and Serf LAN ports are reachable only from the private
subnet and between Nomad servers. Nomad's Consul integration advertises the
server service and performs health checks, so clients can discover healthy
servers through the local Consul agent without a load balancer.

Cloud-init writes `/etc/nomad.d/90-runtime.hcl` with the Nomad `server_join`
stanza and an AWS cloud-auto-join expression matching the instances' `Name`
tag. This lets
servers discover each other through EC2 instead of depending on ephemeral
private addresses. It also writes a Consul AWS cloud-auto-join expression whose
tag name is read from the Consul-server bundle's local Terraform state. The
instance image's `bootstrap_expect` still controls the cluster size; the
default one-instance ASG is intended for a single-node development cluster.

Apply the base and Consul-server bundles first and create a Nomad server AMI with
`make nomad-server-ami`, then apply this bundle:

~~~sh
cd terraform/bundles/base
tofu init
tofu apply

cd ../nomad-server
tofu init
tofu apply \
  -var='username=after' \
  -var='ssh_public_key=ssh-rsa AAAA...'
~~~

The selected AMI is refreshed automatically when a newer matching AMI exists.
User data is stored in Terraform state, so protect the state file. If the ASG
is scaled above one instance, use an AMI whose Nomad `bootstrap_expect` matches
the intended odd number of servers and consider enabling
`instance_refresh_enabled` only when replacing the cluster state is safe.
