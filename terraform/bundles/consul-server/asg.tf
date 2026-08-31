# Private Consul server instances and their Auto Scaling Group.
resource "aws_security_group" "consul_server" {
  name        = "${var.name}-sg"
  description = "Security group for Consul server instances"
  vpc_id      = data.aws_vpc.base.id

  ingress {
    description = "SSH from the private subnet"
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [data.terraform_remote_state.base.outputs.private_subnet_cidr]
  }

  ingress {
    description = "All traffic from the public subnet"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [data.aws_subnet.public.cidr_block]
  }

  ingress {
    description = "Consul HTTP API and UI from private clients"
    protocol    = "tcp"
    from_port   = 8500
    to_port     = 8500
    cidr_blocks = local.http_cidr_blocks
  }

  ingress {
    description = "Consul server RPC traffic from the private subnet"
    protocol    = "tcp"
    from_port   = 8300
    to_port     = 8300
    cidr_blocks = [data.terraform_remote_state.base.outputs.private_subnet_cidr]
  }

  ingress {
    description = "Consul LAN gossip from private clients"
    protocol    = "tcp"
    from_port   = 8301
    to_port     = 8301
    cidr_blocks = local.client_cidr_blocks
  }

  ingress {
    description = "Consul LAN gossip from private clients"
    protocol    = "udp"
    from_port   = 8301
    to_port     = 8301
    cidr_blocks = local.client_cidr_blocks
  }

  ingress {
    description = "Consul WAN gossip from the private subnet"
    protocol    = "tcp"
    from_port   = 8302
    to_port     = 8302
    cidr_blocks = [data.terraform_remote_state.base.outputs.private_subnet_cidr]
  }

  ingress {
    description = "Consul WAN gossip from the private subnet"
    protocol    = "udp"
    from_port   = 8302
    to_port     = 8302
    cidr_blocks = [data.terraform_remote_state.base.outputs.private_subnet_cidr]
  }

  ingress {
    description = "Consul DNS from private clients"
    protocol    = "tcp"
    from_port   = 8600
    to_port     = 8600
    cidr_blocks = local.client_cidr_blocks
  }

  ingress {
    description = "Consul DNS from private clients"
    protocol    = "udp"
    from_port   = 8600
    to_port     = 8600
    cidr_blocks = local.client_cidr_blocks
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
    Role = "consul-server"
  })
}

module "consul_server" {
  source = "../../modules/asg"

  ami                         = data.aws_ami.consul_server.id
  name                        = var.name
  instance_type               = var.instance_type
  root_disk_size              = var.root_disk_size
  root_disk_encrypted         = var.root_disk_encrypted
  subnet_ids                  = [data.terraform_remote_state.base.outputs.private_subnet_id]
  associate_public_ip_address = false
  vpc_security_group_ids      = concat([aws_security_group.consul_server.id], var.vpc_security_group_ids)
  iam_instance_profile_name   = aws_iam_instance_profile.consul_server.name

  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    username         = var.username
    ssh_public_key   = var.ssh_public_key
    bootstrap_expect = var.bootstrap_expect
    consul_join      = "provider=aws tag_key=Name tag_value=${var.name} region=${data.aws_region.current.region}"
  })

  min_size                  = var.min_size
  desired_capacity          = var.desired_capacity
  max_size                  = var.max_size
  health_check_type         = "EC2"
  health_check_grace_period = var.health_check_grace_period
  instance_refresh_enabled  = var.instance_refresh_enabled

  tags = merge(var.tags, {
    Name = var.name
    Role = "consul-server"
  })
}
