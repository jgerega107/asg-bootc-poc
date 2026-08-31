# Shared state, AWS lookups, and values used by the Consul server resources.
data "terraform_remote_state" "base" {
  backend = "local"

  config = {
    path = var.base_state_path
  }
}

data "aws_region" "current" {}

data "aws_vpc" "base" {
  id = data.terraform_remote_state.base.outputs.vpc_id
}

data "aws_subnet" "public" {
  id = data.terraform_remote_state.base.outputs.public_subnet_id
}

data "aws_ami" "consul_server" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["consul-server-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

locals {
  http_cidr_blocks = [data.terraform_remote_state.base.outputs.private_subnet_cidr]

  client_cidr_blocks = concat(
    [data.terraform_remote_state.base.outputs.private_subnet_cidr],
    var.client_cidr_blocks,
  )
}
