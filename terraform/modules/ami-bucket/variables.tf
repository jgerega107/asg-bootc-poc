variable "bucket_name" {
  description = "Globally unique name for the S3 bucket that stores bootc disk images."
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to the bucket."
  type        = map(string)
  default     = {}
}
