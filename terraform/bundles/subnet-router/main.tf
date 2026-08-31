data "terraform_remote_state" "base" {
  backend = "local"

  config = {
    path = var.base_state_path
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-${var.ubuntu_release}-${var.ubuntu_version}-amd64-server-*"]
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

data "aws_region" "current" {}

locals {
  advertised_routes = [data.terraform_remote_state.base.outputs.private_subnet_cidr]

  consul_server_containerfile = file("${path.module}/../../../images/consul-server/Containerfile")
  consul_version              = regex("ARG CONSUL_VERSION=([0-9.]+)", local.consul_server_containerfile)[0]
  consul_sha256               = regex("amd64[)] consul_arch=amd64; consul_sha256=([0-9a-f]+)", local.consul_server_containerfile)[0]
}

resource "aws_security_group" "tailscale_router" {
  name        = "${var.name}-sg"
  description = "Tailscale subnet router"
  vpc_id      = data.terraform_remote_state.base.outputs.vpc_id

  ingress {
    description = "Tailscale WireGuard traffic"
    protocol    = "udp"
    from_port   = 41641
    to_port     = 41641
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "All traffic from the private subnet"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [data.terraform_remote_state.base.outputs.private_subnet_cidr]
  }

  egress {
    description = "Outbound traffic for Tailscale and forwarded connections"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-sg"
  })
}

module "subnet_router" {
  source = "../../modules/vm"

  ami                         = data.aws_ami.ubuntu.id
  name                        = var.name
  instance_type               = var.instance_type
  root_disk_size              = var.root_disk_size
  subnet_id                   = data.terraform_remote_state.base.outputs.public_subnet_id
  associate_public_ip_address = true
  source_dest_check           = false
  vpc_security_group_ids      = [aws_security_group.tailscale_router.id]

  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    auth_arg       = "--auth-key=${var.tailscale_auth_key}"
    route_arg      = "--advertise-routes=${join(",", local.advertised_routes)}"
    username       = var.username
    ssh_public_key = var.ssh_public_key
    consul_join    = "provider=aws tag_key=Role tag_value=consul-server region=${data.aws_region.current.region}"
    consul_version = local.consul_version
    consul_sha256  = local.consul_sha256
  })

  tags = merge(var.tags, {
    Role = "tailscale-subnet-router"
  })
}
