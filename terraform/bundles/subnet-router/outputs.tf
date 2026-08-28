output "instance_id" {
  description = "ID of the Tailscale subnet-router instance."
  value       = module.subnet_router.instance_id
}

output "private_ip" {
  description = "Private IPv4 address of the subnet router."
  value       = module.subnet_router.private_ip
}

output "public_ip" {
  description = "Public IPv4 address of the subnet router."
  value       = module.subnet_router.public_ip
}

output "security_group_id" {
  description = "Security group ID attached to the subnet router."
  value       = aws_security_group.tailscale_router.id
}

output "advertised_route" {
  description = "Private subnet CIDR advertised to Tailscale."
  value       = data.terraform_remote_state.base.outputs.private_subnet_cidr
}
