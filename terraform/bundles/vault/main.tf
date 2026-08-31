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

data "aws_ami" "vault" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["vault-*"]
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

resource "aws_security_group" "vault" {
  name        = "${var.name}-sg"
  description = "Security group for the Vault instance"
  vpc_id      = data.terraform_remote_state.base.outputs.vpc_id

  ingress {
    description = "SSH from the private subnet"
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [data.terraform_remote_state.base.outputs.private_subnet_cidr]
  }

  ingress {
    description = "All traffic from the subnet router"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [format("%s/32", data.terraform_remote_state.subnet_router.outputs.private_ip)]
  }

  ingress {
    description = "Vault API from the private subnet"
    protocol    = "tcp"
    from_port   = 8200
    to_port     = 8200
    cidr_blocks = [data.terraform_remote_state.base.outputs.private_subnet_cidr]
  }

  egress {
    description = "Outbound traffic"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-sg"
  })
}

module "vault" {
  source = "../../modules/vm"

  ami                         = data.aws_ami.vault.id
  name                        = var.name
  instance_type               = var.instance_type
  root_disk_size              = var.root_disk_size
  subnet_id                   = data.terraform_remote_state.base.outputs.private_subnet_id
  associate_public_ip_address = false
  vpc_security_group_ids      = concat([aws_security_group.vault.id], var.vpc_security_group_ids)

  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    username       = var.username
    ssh_public_key = var.ssh_public_key
    consul_join    = "provider=aws tag_key=Name tag_value=${data.terraform_remote_state.consul_server.outputs.name} region=${data.aws_region.current.region}"
  })

  tags = merge(var.tags, {
    Role = "vault"
  })
}
