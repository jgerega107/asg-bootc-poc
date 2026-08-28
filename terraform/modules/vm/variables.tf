variable "ami" {
  description = "AMI ID to use for the instance."
  type        = string

  validation {
    condition     = trimspace(var.ami) != ""
    error_message = "ami must not be empty."
  }
}

variable "name" {
  description = "Name tag for the instance and its root disk."
  type        = string

  validation {
    condition     = trimspace(var.name) != ""
    error_message = "name must not be empty."
  }
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t3.micro"
}

variable "root_disk_size" {
  description = "Root disk size in GiB."
  type        = number
  default     = 20

  validation {
    condition     = var.root_disk_size >= 1 && floor(var.root_disk_size) == var.root_disk_size
    error_message = "root_disk_size must be a positive whole number of GiB."
  }
}

variable "root_disk_encrypted" {
  description = "Whether to encrypt the root disk with the default EBS key."
  type        = bool
  default     = true
}

variable "subnet_id" {
  description = "Subnet in which to launch the instance. The default VPC subnet is used when unset."
  type        = string
  default     = null
}

variable "vpc_security_group_ids" {
  description = "Security groups to attach to the instance."
  type        = list(string)
  default     = []
}

variable "associate_public_ip_address" {
  description = "Whether to associate a public IPv4 address with the instance."
  type        = bool
  default     = false
}

variable "source_dest_check" {
  description = "Whether AWS should perform source/destination checking on the instance. Disable this for routers or firewalls."
  type        = bool
  default     = true
}

variable "user_data" {
  description = "Cloud-init user data passed to the instance. Pass rendered cloud-config text or file(...)."
  type        = string
  default     = null
  nullable    = true
  sensitive   = true
}

variable "tags" {
  description = "Additional tags for the instance and its root disk."
  type        = map(string)
  default     = {}
}
