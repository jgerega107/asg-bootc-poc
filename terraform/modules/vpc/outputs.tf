output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "IPv4 CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "availability_zone" {
  description = "Availability Zone containing the subnets."
  value       = local.availability_zone
}

output "public_subnet_id" {
  description = "ID of the public subnet containing the NAT Gateway and Tailscale router."
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "ID of the private application subnet."
  value       = aws_subnet.private.id
}

output "private_subnet_cidr" {
  description = "IPv4 CIDR block of the private application subnet."
  value       = aws_subnet.private.cidr_block
}

output "public_route_table_id" {
  description = "ID of the public route table containing the NAT Gateway."
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID of the private route table that routes internet traffic through the NAT Gateway."
  value       = aws_route_table.private.id
}

output "nat_gateway_id" {
  description = "ID of the single NAT Gateway."
  value       = aws_nat_gateway.this.id
}
