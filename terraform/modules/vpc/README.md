# VPC

Creates a single-AZ VPC with one private application subnet and one shared NAT
Gateway. The public subnet hosts the NAT Gateway and the Tailscale subnet
router; other application workloads remain private.

```hcl
module "vpc" {
  source = "./modules/vpc"

  name = "bootc"
}
```

The public subnet has a route to the Internet Gateway and contains the NAT
Gateway. The Tailscale router may also be placed there when direct inbound
Tailscale UDP is required.

The private subnet has a default route through the shared NAT Gateway for
outbound internet access and remains unreachable from the public internet.
`module.vpc.private_route_table_id` exposes its route table for additional
private routes.

Using one Availability Zone avoids cross-AZ data charges and matches the
single-router design. It does not provide zone-level high availability.
