output "bucket_id" {
  description = "Name of the bootc image bucket."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN of the bootc image bucket."
  value       = aws_s3_bucket.this.arn
}

output "bucket_region" {
  description = "AWS Region containing the bootc image bucket."
  value       = aws_s3_bucket.this.region
}

output "vmimport_role_name" {
  description = "Name of the VM Import/Export service role."
  value       = aws_iam_role.vmimport.name
}

output "vmimport_role_arn" {
  description = "ARN of the VM Import/Export service role."
  value       = aws_iam_role.vmimport.arn
}
