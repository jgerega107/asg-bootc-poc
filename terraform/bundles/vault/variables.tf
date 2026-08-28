variable "base_state_path" {
  description = "Path to the local Terraform state for the base bundle."
  type        = string
  default     = "../base/terraform.tfstate"
}

variable "name" {
  description = "Name tag for the Vault instance and root disk."
  type        = string
  default     = "vault"

  validation {
    condition     = trimspace(var.name) != ""
    error_message = "name must not be empty."
  }
}

variable "instance_type" {
  description = "EC2 instance type for the Vault node."
  type        = string
  default     = "t3.micro"
}

variable "root_disk_size" {
  description = "Root disk size in GiB. Vault stores its data on this disk."
  type        = number
  default     = 20

  validation {
    condition     = var.root_disk_size >= 1 && floor(var.root_disk_size) == var.root_disk_size
    error_message = "root_disk_size must be a positive whole number of GiB."
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

variable "vpc_security_group_ids" {
  description = "Additional security groups to attach to the private Vault instance."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags for the Vault instance and root disk."
  type        = map(string)
  default     = {}
}
