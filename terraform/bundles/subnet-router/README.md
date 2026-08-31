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

The router enables IP forwarding, advertises only the base bundle's private
subnet, and disables EC2 source/destination checking. It also runs a Consul
client using the version and AMD64 checksum from the Consul-server image. The
client discovers servers through the `Role=consul-server` EC2 tag and listens
for DNS only on `127.0.0.1:8600`.

`systemd-resolved` forwards only `*.service.consul` queries to that local
Consul DNS listener and listens for DNS requests on port 53 on the router's
interfaces; all other queries continue using the normal resolver. The router
receives an ephemeral public IPv4 address and permits inbound UDP 41641 for
direct Tailscale connections; no Elastic IP is allocated. The address may
change after the instance is stopped or replaced. No `--hostname` is supplied
to Tailscale, so it uses the AWS/OS hostname and Tailscale generates the
machine name automatically.

Advertised routes require approval unless the tailnet policy grants automatic
approval. For example, create a tagged auth key for `tag:subnet-router` and
add the private subnet CIDR to the tailnet policy:

~~~json
{
  "tagOwners": {
    "tag:subnet-router": ["autogroup:admin"]
  },
  "autoApprovers": {
    "routes": {
      "10.0.1.0/24": ["tag:subnet-router"]
    }
  }
}
~~~

Replace the example CIDR with the actual private subnet if it differs.
Otherwise, approve the route in the Tailscale admin console. Linux tailnet
clients may also need to enable route acceptance.

Because subnet routes use source NAT by default, private workload security
groups allow all traffic from the base bundle's public subnet CIDR. This
includes the subnet router, but also any other instances placed in that public
subnet. The router security group permits Tailscale WireGuard traffic, all
traffic from the private subnet, and outbound traffic; it does not expose
public SSH. The workload bundles read the public subnet directly from the base
bundle and do not depend on the subnet-router state.

Verify the local DNS setup on the router with:

~~~sh
systemctl is-active consul systemd-resolved
resolvectl domain
resolvectl query <service>.service.consul
~~~

The auth key is sensitive Terraform input, but cloud-init user data is still
stored in Terraform state because EC2 receives it at launch. Protect the state
file and use a short-lived or reusable Tailscale key according to your
tailnet's policy.
