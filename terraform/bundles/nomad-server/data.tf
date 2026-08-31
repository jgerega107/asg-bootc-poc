# Shared state, AWS lookups, and values used by the Nomad resources.
data "terraform_remote_state" "base" {
  backend = "local"

  config = {
    path = var.base_state_path
  }
}

data "terraform_remote_state" "subnet_router" {
  backend = "local"

  config = {
    path = "../subnet-router/terraform.tfstate"
  }
}

data "terraform_remote_state" "consul_server" {
  backend = "local"

  config = {
    path = "../consul-server/terraform.tfstate"
  }
}

data "aws_region" "current" {}

data "aws_vpc" "base" {
  id = data.terraform_remote_state.base.outputs.vpc_id
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
