# Shared state, AWS lookups, and values used by the Nomad resources.
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

data "aws_ami" "nomad_server" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["nomad-server-*"]
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
  endpoint_cidr_blocks = concat(
    [data.aws_vpc.base.cidr_block],
    var.endpoint_cidr_blocks,
  )
}
