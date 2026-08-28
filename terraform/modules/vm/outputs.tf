output "instance_id" {
  description = "ID of the EC2 instance."
  value       = aws_instance.this.id
}

output "instance_arn" {
  description = "ARN of the EC2 instance."
  value       = aws_instance.this.arn
}

output "private_ip" {
  description = "Private IPv4 address of the instance."
  value       = aws_instance.this.private_ip
}

output "public_ip" {
  description = "Public IPv4 address of the instance, if assigned."
  value       = aws_instance.this.public_ip
}

output "root_volume_id" {
  description = "ID of the instance's root disk."
  value       = aws_instance.this.root_block_device[0].volume_id
}
