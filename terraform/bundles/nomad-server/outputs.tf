output "ami_id" {
  description = "Nomad server AMI selected for the launch template."
  value       = data.aws_ami.nomad_server.id
}

output "autoscaling_group_id" {
  description = "ID of the Nomad server Auto Scaling Group."
  value       = module.nomad_server.autoscaling_group_id
}

output "autoscaling_group_name" {
  description = "Name of the Nomad server Auto Scaling Group."
  value       = module.nomad_server.autoscaling_group_name
}

output "autoscaling_group_arn" {
  description = "ARN of the Nomad server Auto Scaling Group."
  value       = module.nomad_server.autoscaling_group_arn
}

output "security_group_id" {
  description = "Security group ID attached to Nomad server instances."
  value       = aws_security_group.nomad_server.id
}

output "iam_instance_profile_name" {
  description = "IAM instance profile used for Nomad AWS cloud auto-join."
  value       = aws_iam_instance_profile.nomad_server.name
}
