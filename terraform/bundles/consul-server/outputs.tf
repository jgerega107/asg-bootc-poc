output "name" {
  description = "Name tag used by Consul server instances and AWS cloud auto-join."
  value       = var.name
}

output "ami_id" {
  description = "Consul server AMI selected for the launch template."
  value       = data.aws_ami.consul_server.id
}

output "autoscaling_group_id" {
  description = "ID of the Consul server Auto Scaling Group."
  value       = module.consul_server.autoscaling_group_id
}

output "autoscaling_group_name" {
  description = "Name of the Consul server Auto Scaling Group."
  value       = module.consul_server.autoscaling_group_name
}

output "autoscaling_group_arn" {
  description = "ARN of the Consul server Auto Scaling Group."
  value       = module.consul_server.autoscaling_group_arn
}

output "security_group_id" {
  description = "Security group ID attached to Consul server instances."
  value       = aws_security_group.consul_server.id
}

output "iam_instance_profile_name" {
  description = "IAM instance profile used for Consul AWS cloud auto-join."
  value       = aws_iam_instance_profile.consul_server.name
}
