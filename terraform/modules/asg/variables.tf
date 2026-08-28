variable "ami" {
  description = "AMI ID to use for instances."
  type        = string

  validation {
    condition     = trimspace(var.ami) != ""
    error_message = "ami must not be empty."
  }
}

variable "name" {
  description = "Name for the Auto Scaling Group, launch template, instances, and root disks."
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

variable "root_device_name" {
  description = "Root device name from the AMI block device mapping."
  type        = string
  default     = "/dev/sda1"
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
  description = "Whether to encrypt root disks with the default EBS key."
  type        = bool
  default     = true
}

variable "subnet_ids" {
  description = "Subnets in which Auto Scaling Group instances may launch."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) > 0 && alltrue([for id in var.subnet_ids : trimspace(id) != ""])
    error_message = "subnet_ids must contain at least one non-empty subnet ID."
  }
}

variable "vpc_security_group_ids" {
  description = "Security groups to attach to instances."
  type        = list(string)
  default     = []
}

variable "associate_public_ip_address" {
  description = "Whether to associate public IPv4 addresses with instances."
  type        = bool
  default     = false
}

variable "user_data" {
  description = "Cloud-init user data passed to instances. Pass rendered cloud-config text or file(...)."
  type        = string
  default     = null
  nullable    = true
  sensitive   = true
}

variable "iam_instance_profile_name" {
  description = "Optional IAM instance profile name to attach to launched instances."
  type        = string
  default     = null
  nullable    = true

  validation {
    condition     = var.iam_instance_profile_name == null || trimspace(var.iam_instance_profile_name) != ""
    error_message = "iam_instance_profile_name must be null or non-empty."
  }
}

variable "min_size" {
  description = "Minimum number of instances in the Auto Scaling Group."
  type        = number
  default     = 1

  validation {
    condition     = var.min_size >= 0 && floor(var.min_size) == var.min_size
    error_message = "min_size must be a non-negative whole number."
  }
}

variable "max_size" {
  description = "Maximum number of instances in the Auto Scaling Group."
  type        = number
  default     = 1

  validation {
    condition     = var.max_size >= 0 && floor(var.max_size) == var.max_size
    error_message = "max_size must be a non-negative whole number."
  }
}

variable "desired_capacity" {
  description = "Desired number of instances in the Auto Scaling Group."
  type        = number
  default     = 1

  validation {
    condition     = var.desired_capacity >= 0 && floor(var.desired_capacity) == var.desired_capacity
    error_message = "desired_capacity must be a non-negative whole number."
  }
}

variable "health_check_type" {
  description = "Health check type for the Auto Scaling Group."
  type        = string
  default     = "EC2"

  validation {
    condition     = contains(["EC2", "ELB"], var.health_check_type)
    error_message = "health_check_type must be EC2 or ELB."
  }
}

variable "health_check_grace_period" {
  description = "Seconds to wait after launch before checking instance health."
  type        = number
  default     = 300

  validation {
    condition     = var.health_check_grace_period >= 0 && floor(var.health_check_grace_period) == var.health_check_grace_period
    error_message = "health_check_grace_period must be a non-negative whole number of seconds."
  }
}

variable "default_instance_warmup" {
  description = "Seconds before a newly launched instance contributes to Auto Scaling metrics."
  type        = number
  default     = 300

  validation {
    condition     = var.default_instance_warmup >= 0 && floor(var.default_instance_warmup) == var.default_instance_warmup
    error_message = "default_instance_warmup must be a non-negative whole number of seconds."
  }
}

variable "instance_refresh_enabled" {
  description = "Whether launch template changes trigger a rolling instance refresh."
  type        = bool
  default     = true
}

variable "instance_refresh_min_healthy_percentage" {
  description = "Minimum healthy percentage during an instance refresh."
  type        = number
  default     = 50

  validation {
    condition     = var.instance_refresh_min_healthy_percentage >= 0 && var.instance_refresh_min_healthy_percentage <= 100 && floor(var.instance_refresh_min_healthy_percentage) == var.instance_refresh_min_healthy_percentage
    error_message = "instance_refresh_min_healthy_percentage must be a whole number between 0 and 100."
  }
}

variable "instance_refresh_warmup" {
  description = "Seconds to wait for each instance during a rolling refresh."
  type        = number
  default     = 300

  validation {
    condition     = var.instance_refresh_warmup >= 0 && floor(var.instance_refresh_warmup) == var.instance_refresh_warmup
    error_message = "instance_refresh_warmup must be a non-negative whole number of seconds."
  }
}

variable "force_delete" {
  description = "Whether to delete the Auto Scaling Group without waiting for instances to terminate."
  type        = bool
  default     = false
}

variable "target_group_arns" {
  description = "Load balancer target groups to attach to the Auto Scaling Group."
  type        = list(string)
  default     = []
}

variable "termination_policies" {
  description = "Auto Scaling termination policies."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags for the launch template, instances, root disks, and Auto Scaling Group."
  type        = map(string)
  default     = {}
}
