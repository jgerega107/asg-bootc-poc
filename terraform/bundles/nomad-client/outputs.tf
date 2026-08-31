output "ami_id" {
  description = "Nomad client AMI selected for the launch template."
  value       = data.aws_ami.nomad_client.id
}

output "autoscaling_group_id" {
  description = "ID of the Nomad client Auto Scaling Group."
  value       = module.nomad_client.autoscaling_group_id
}

output "autoscaling_group_name" {
  description = "Name of the Nomad client Auto Scaling Group."
  value       = module.nomad_client.autoscaling_group_name
}

output "autoscaling_group_arn" {
  description = "ARN of the Nomad client Auto Scaling Group."
  value       = module.nomad_client.autoscaling_group_arn
}

output "security_group_id" {
  description = "Security group ID attached to Nomad client instances."
  value       = aws_security_group.nomad_client.id
}

output "iam_instance_profile_name" {
  description = "IAM instance profile used for Nomad and Consul AWS cloud auto-join."
  value       = aws_iam_instance_profile.nomad_client.name
}
