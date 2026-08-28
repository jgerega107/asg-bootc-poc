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
  description = "ID of the subnet intended for the VPN instance."
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "ID of the isolated application subnet."
  value       = aws_subnet.private.id
}

output "private_subnet_cidr" {
  description = "IPv4 CIDR block of the isolated application subnet."
  value       = aws_subnet.private.cidr_block
}

output "public_route_table_id" {
  description = "ID of the public route table."
  value       = aws_route_table.public.id
}

output "private_route_table_id" {
  description = "ID of the private route table. Add a route through the VPN instance when it is created."
  value       = aws_route_table.private.id
}
