# Shared state and AWS lookups used by the Nomad client resources.
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

data "aws_ami" "nomad_client" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["nomad-client-*"]
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
