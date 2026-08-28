variable "base_state_path" {
  description = "Path to the local Terraform state for the base bundle."
  type        = string
  default     = "../base/terraform.tfstate"
}

variable "name" {
  description = "Name for the Nomad server ASG, instances, endpoint, and IAM resources."
  type        = string
  default     = "nomad-server"

  validation {
    condition     = can(regex("^[A-Za-z0-9-]+$", var.name)) && length(var.name) <= 24
    error_message = "name must contain only letters, numbers, and hyphens and be at most 24 characters."
  }
}

variable "instance_type" {
  description = "EC2 instance type for Nomad server instances."
  type        = string
  default     = "t3.micro"
}

variable "root_disk_size" {
  description = "Root disk size in GiB. Nomad keeps its data on this disk."
  type        = number
  default     = 20

  validation {
    condition     = var.root_disk_size >= 1 && floor(var.root_disk_size) == var.root_disk_size
    error_message = "root_disk_size must be a positive whole number of GiB."
  }
}

variable "root_disk_encrypted" {
  description = "Whether to encrypt the Nomad root disk with the default EBS key."
  type        = bool
  default     = true
}

variable "username" {
  description = "Username to create through cloud-init."
  type        = string

  validation {
    condition     = trimspace(var.username) != ""
    error_message = "username must not be empty."
  }
}

variable "ssh_public_key" {
  description = "SSH public key to authorize for username through cloud-init."
  type        = string

  validation {
    condition     = trimspace(var.ssh_public_key) != ""
    error_message = "ssh_public_key must not be empty."
  }
}

variable "vpc_security_group_ids" {
  description = "Additional security groups to attach to Nomad server instances."
  type        = list(string)
  default     = []
}

variable "endpoint_cidr_blocks" {
  description = "Additional CIDR blocks allowed to reach the private Nomad endpoint. The VPC CIDR is always allowed."
  type        = list(string)
  default     = ["100.64.0.0/10"]

  validation {
    condition     = alltrue([for cidr in var.endpoint_cidr_blocks : can(cidrhost(cidr, 0))])
    error_message = "endpoint_cidr_blocks must contain valid CIDR blocks."
  }
}

variable "health_check_path" {
  description = "Nomad HTTP API path used by the endpoint target group health check."
  type        = string
  default     = "/v1/agent/health"

  validation {
    condition     = startswith(var.health_check_path, "/")
    error_message = "health_check_path must start with '/'."
  }
}

variable "min_size" {
  description = "Minimum number of Nomad server instances in the Auto Scaling Group."
  type        = number
  default     = 1

  validation {
    condition     = var.min_size >= 0 && floor(var.min_size) == var.min_size
    error_message = "min_size must be a non-negative whole number."
  }
}

variable "desired_capacity" {
  description = "Desired number of Nomad server instances in the Auto Scaling Group."
  type        = number
  default     = 1

  validation {
    condition     = var.desired_capacity >= 0 && floor(var.desired_capacity) == var.desired_capacity
    error_message = "desired_capacity must be a non-negative whole number."
  }
}

variable "max_size" {
  description = "Maximum number of Nomad server instances in the Auto Scaling Group."
  type        = number
  default     = 1

  validation {
    condition     = var.max_size >= 0 && floor(var.max_size) == var.max_size
    error_message = "max_size must be a non-negative whole number."
  }
}

variable "health_check_grace_period" {
  description = "Seconds to wait after launch before the Auto Scaling Group checks load balancer health."
  type        = number
  default     = 300

  validation {
    condition     = var.health_check_grace_period >= 0 && floor(var.health_check_grace_period) == var.health_check_grace_period
    error_message = "health_check_grace_period must be a non-negative whole number of seconds."
  }
}

variable "instance_refresh_enabled" {
  description = "Whether launch template changes trigger a rolling refresh."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags for Nomad resources."
  type        = map(string)
  default     = {}
}
