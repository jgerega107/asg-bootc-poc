output "ami_id" {
  description = "Vault AMI used by the instance."
  value       = data.aws_ami.vault.id
}

output "instance_id" {
  description = "ID of the Vault instance."
  value       = module.vault.instance_id
}

output "private_ip" {
  description = "Private IPv4 address of the Vault instance."
  value       = module.vault.private_ip
}

output "root_volume_id" {
  description = "ID of the Vault root disk."
  value       = module.vault.root_volume_id
}

output "iam_instance_profile_name" {
  description = "IAM instance profile attached to the Vault instance."
  value       = module.vault.iam_instance_profile_name
}

output "security_group_id" {
  description = "Security group ID attached to the Vault instance."
  value       = aws_security_group.vault.id
}
