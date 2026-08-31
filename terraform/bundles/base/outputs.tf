output "vpc_id" {
  description = "ID of the test-bootc VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_id" {
  description = "ID of the public subnet containing the NAT Gateway and Tailscale router."
  value       = module.vpc.public_subnet_id
}

output "private_subnet_id" {
  description = "ID of the private application subnet."
  value       = module.vpc.private_subnet_id
}

output "private_subnet_cidr" {
  description = "IPv4 CIDR block of the private application subnet."
  value       = module.vpc.private_subnet_cidr
}

output "vpc_dns_resolver_ip" {
  description = "IPv4 address of the Amazon-provided Route 53 Resolver for the VPC."
  value       = cidrhost(module.vpc.vpc_cidr, 2)
}

output "private_route_table_id" {
  description = "ID of the private route table that routes internet traffic through the NAT Gateway."
  value       = module.vpc.private_route_table_id
}

output "nat_gateway_id" {
  description = "ID of the single NAT Gateway."
  value       = module.vpc.nat_gateway_id
}

output "bootc_images_bucket_id" {
  description = "Name of the bootc image bucket."
  value       = module.ami_bucket.bucket_id
}

output "bootc_images_bucket_arn" {
  description = "ARN of the bootc image bucket."
  value       = module.ami_bucket.bucket_arn
}
