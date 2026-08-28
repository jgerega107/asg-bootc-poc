variable "bucket_name" {
  description = "Globally unique name for the S3 bucket that stores bootc disk images."
  type        = string
}

variable "vmimport_role_name" {
  description = "Name of the IAM service role used by EC2 VM Import/Export."
  type        = string
  default     = "vmimport"

  validation {
    condition     = trimspace(var.vmimport_role_name) != ""
    error_message = "vmimport_role_name must not be empty."
  }
}

variable "tags" {
  description = "Additional tags to apply to the bucket."
  type        = map(string)
  default     = {}
}
