variable "vpc_name" {
  description = "Name used to tag the core VPC and its resources."
  type        = string
}

variable "bucket_name" {
  description = "Globally unique name for the bootc image bucket."
  type        = string
}
