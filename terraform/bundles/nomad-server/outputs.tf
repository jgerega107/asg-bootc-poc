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

output "load_balancer_dns_name" {
  description = "Stable private DNS name of the Nomad Network Load Balancer."
  value       = aws_lb.nomad.dns_name
}

output "load_balancer_arn" {
  description = "ARN of the Nomad Network Load Balancer."
  value       = aws_lb.nomad.arn
}

output "api_endpoint" {
  description = "Nomad HTTP API endpoint through the private Network Load Balancer."
  value       = "http://${aws_lb.nomad.dns_name}:4646"
}

output "health_check_path" {
  description = "Nomad HTTP API path used for load balancer health checks."
  value       = var.health_check_path
}

output "security_group_id" {
  description = "Security group ID attached to Nomad server instances."
  value       = aws_security_group.nomad_server.id
}

output "load_balancer_security_group_id" {
  description = "Security group ID attached to the Nomad Network Load Balancer."
  value       = aws_security_group.nomad_nlb.id
}

output "iam_instance_profile_name" {
  description = "IAM instance profile used for Nomad AWS cloud auto-join."
  value       = aws_iam_instance_profile.nomad_server.name
}
