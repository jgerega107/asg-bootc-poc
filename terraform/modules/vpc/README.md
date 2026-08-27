# VPC

Creates a cost-conscious, single-AZ VPC for a public VPN instance and private
application instances. It creates no NAT gateway and no billable networking
resources.

```hcl
module "vpc" {
  source = "./modules/vpc"

  name = "bootc"
}
```

The public subnet has a route to the internet gateway. Instances do not receive
public addresses from the subnet automatically, so assign a public or Elastic
IP specifically to the VPN instance.

The private subnet starts isolated, with only the VPC's implicit local route.
After creating the VPN instance, disable source/destination checking on it and
add a default route to `module.vpc.private_route_table_id` targeting the VPN
instance or its network interface if private instances should use it for
internet egress.

Using one Availability Zone avoids cross-AZ data charges and matches the single
VPN-instance design. It does not provide zone-level high availability.
