# VPC

Creates a single-AZ VPC with one private application subnet and one shared NAT
Gateway. The public subnet exists only to provide internet connectivity for the
NAT Gateway.

```hcl
module "vpc" {
  source = "./modules/vpc"

  name = "bootc"
}
```

The public subnet has a route to the Internet Gateway and contains the NAT
Gateway. No application workloads are placed in this subnet.

The private subnet has a default route through the shared NAT Gateway for
outbound internet access and remains unreachable from the public internet.
`module.vpc.private_route_table_id` exposes its route table for additional
private routes.

Using one Availability Zone avoids cross-AZ data charges and matches the
single-router design. It does not provide zone-level high availability.
