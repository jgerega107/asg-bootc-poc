# Private Nomad server instances and their Auto Scaling Group.
resource "aws_security_group" "nomad_server" {
  name        = "${var.name}-sg"
  description = "Security group for Nomad server instances"
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
    description = "Nomad TCP traffic between servers"
    protocol    = "tcp"
    from_port   = 4646
    to_port     = 4648
    self        = true
  }

  ingress {
    description = "Nomad HTTP API traffic from private clients"
    protocol    = "tcp"
    from_port   = 4646
    to_port     = 4646
    cidr_blocks = [data.terraform_remote_state.base.outputs.private_subnet_cidr]
  }

  ingress {
    description = "Nomad RPC traffic from private clients"
    protocol    = "tcp"
    from_port   = 4647
    to_port     = 4647
    cidr_blocks = [data.terraform_remote_state.base.outputs.private_subnet_cidr]
  }

  ingress {
    description = "Nomad Serf LAN traffic from private clients"
    protocol    = "tcp"
    from_port   = 4648
    to_port     = 4648
    cidr_blocks = [data.terraform_remote_state.base.outputs.private_subnet_cidr]
  }

  ingress {
    description = "Nomad Serf LAN traffic from private clients"
    protocol    = "udp"
    from_port   = 4648
    to_port     = 4648
    cidr_blocks = [data.terraform_remote_state.base.outputs.private_subnet_cidr]
  }

  ingress {
    description = "Nomad Serf LAN traffic between servers"
    protocol    = "udp"
    from_port   = 4648
    to_port     = 4648
    self        = true
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
    Role = "nomad-server"
  })
}

module "nomad_server" {
  source = "../../modules/asg"

  ami                         = data.aws_ami.nomad_server.id
  name                        = var.name
  instance_type               = var.instance_type
  root_disk_size              = var.root_disk_size
  root_disk_encrypted         = var.root_disk_encrypted
  subnet_ids                  = [data.terraform_remote_state.base.outputs.private_subnet_id]
  associate_public_ip_address = false
  vpc_security_group_ids      = concat([aws_security_group.nomad_server.id], var.vpc_security_group_ids)
  iam_instance_profile_name   = aws_iam_instance_profile.nomad_server.name

  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    username       = var.username
    ssh_public_key = var.ssh_public_key
    nomad_join     = "provider=aws tag_key=Name tag_value=${var.name} region=${data.aws_region.current.region}"
    consul_join    = "provider=aws tag_key=Name tag_value=${data.terraform_remote_state.consul_server.outputs.name} region=${data.aws_region.current.region}"
  })

  min_size                  = var.min_size
  desired_capacity          = var.desired_capacity
  max_size                  = var.max_size
  health_check_type         = "EC2"
  health_check_grace_period = var.health_check_grace_period
  instance_refresh_enabled  = var.instance_refresh_enabled

  tags = merge(var.tags, {
    Name = var.name
    Role = "nomad-server"
  })
}
