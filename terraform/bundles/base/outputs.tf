output "vpc_id" {
  description = "ID of the test-bootc VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_id" {
  description = "ID of the public VPN subnet."
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

output "private_route_table_id" {
  description = "ID of the route table to use when routing through the VPN instance."
  value       = module.vpc.private_route_table_id
}

output "bootc_images_bucket_id" {
  description = "Name of the bootc image bucket."
  value       = module.ami_bucket.bucket_id
}

output "bootc_images_bucket_arn" {
  description = "ARN of the bootc image bucket."
  value       = module.ami_bucket.bucket_arn
}
