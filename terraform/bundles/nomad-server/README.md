# Nomad server bundle

Creates a Nomad server Auto Scaling Group in the base bundle's private subnet,
using the newest self-owned `nomad-server-*` AMI. Instances
have no public IPv4 address. SSH is allowed from the base bundle's public
subnet, and the instance role grants the read-only EC2 permissions Nomad needs
for AWS cloud auto-join.

The bundle also creates an internal Network Load Balancer with a stable private
DNS name. It exposes Nomad's HTTP API on port 4646. The target group checks the
Nomad agent health API at `/v1/agent/health`; the Auto Scaling Group uses that
load balancer check for instance health. RPC and Serf LAN traffic remains
private between server instances. The default endpoint rules allow the VPC and Tailscale's
standard `100.64.0.0/10` range when the local `terraform.tfvars` is present;
override `endpoint_cidr_blocks` for another tailnet range. Without that
override, only the VPC CIDR is allowed.

Cloud-init writes `/etc/nomad.d/90-runtime.hcl` with an AWS `server_join`
cloud-auto-join expression matching the instances' `Name` tag. This lets
servers discover each other through EC2 instead of depending on ephemeral
private addresses. The instance image's `bootstrap_expect` still controls the
cluster size; the default one-instance ASG is intended for a single-node
development cluster.

Apply the base bundle first and create a Nomad server AMI with
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
