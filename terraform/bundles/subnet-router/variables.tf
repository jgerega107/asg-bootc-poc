variable "base_state_path" {
  description = "Path to the local Terraform state for the base bundle."
  type        = string
  default     = "../base/terraform.tfstate"
}

variable "name" {
  description = "Name for the Tailscale subnet-router instance and security group."
  type        = string
  default     = "tailscale-subnet-router"

  validation {
    condition     = trimspace(var.name) != ""
    error_message = "name must not be empty."
  }
}

variable "tailscale_auth_key" {
  description = "Tailscale auth key used to register the subnet router."
  type        = string
  sensitive   = true

  validation {
    condition     = trimspace(var.tailscale_auth_key) != ""
    error_message = "tailscale_auth_key must not be empty."
  }
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

variable "instance_type" {
  description = "EC2 instance type for the subnet router."
  type        = string
  default     = "t3.micro"
}

variable "root_disk_size" {
  description = "Root disk size in GiB."
  type        = number
  default     = 8

  validation {
    condition     = var.root_disk_size >= 1 && floor(var.root_disk_size) == var.root_disk_size
    error_message = "root_disk_size must be a positive whole number of GiB."
  }
}

variable "ubuntu_release" {
  description = "Ubuntu release codename to use for the router AMI."
  type        = string
  default     = "noble"
}

variable "ubuntu_version" {
  description = "Ubuntu release version to use for the router AMI."
  type        = string
  default     = "24.04"
}

variable "tags" {
  description = "Additional tags for the router instance and root disk."
  type        = map(string)
  default     = {}
}
