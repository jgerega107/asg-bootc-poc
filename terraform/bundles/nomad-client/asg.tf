# Private Nomad client instances and their Auto Scaling Group.
resource "aws_security_group" "nomad_client" {
  name        = "${var.name}-sg"
  description = "Security group for Nomad client instances"
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
    description = "Nomad HTTP API from the private subnet"
    protocol    = "tcp"
    from_port   = 4646
    to_port     = 4646
    cidr_blocks = [data.terraform_remote_state.base.outputs.private_subnet_cidr]
  }

  ingress {
    description = "Nomad RPC from the private subnet"
    protocol    = "tcp"
    from_port   = 4647
    to_port     = 4647
    cidr_blocks = [data.terraform_remote_state.base.outputs.private_subnet_cidr]
  }

  ingress {
    description = "Nomad dynamic ports from the private subnet"
    protocol    = "tcp"
    from_port   = 20000
    to_port     = 32000
    cidr_blocks = [data.terraform_remote_state.base.outputs.private_subnet_cidr]
  }

  ingress {
    description = "Nomad dynamic ports from the private subnet"
    protocol    = "udp"
    from_port   = 20000
    to_port     = 32000
    cidr_blocks = [data.terraform_remote_state.base.outputs.private_subnet_cidr]
  }

  ingress {
    description = "Consul LAN gossip from the private subnet"
    protocol    = "tcp"
    from_port   = 8301
    to_port     = 8301
    cidr_blocks = [data.terraform_remote_state.base.outputs.private_subnet_cidr]
  }

  ingress {
    description = "Consul LAN gossip from the private subnet"
    protocol    = "udp"
    from_port   = 8301
    to_port     = 8301
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
    Role = "nomad-client"
  })
}

module "nomad_client" {
  source = "../../modules/asg"

  ami                         = data.aws_ami.nomad_client.id
  name                        = var.name
  instance_type               = var.instance_type
  root_disk_size              = var.root_disk_size
  root_disk_encrypted         = var.root_disk_encrypted
  subnet_ids                  = [data.terraform_remote_state.base.outputs.private_subnet_id]
  associate_public_ip_address = false
  vpc_security_group_ids      = concat([aws_security_group.nomad_client.id], var.vpc_security_group_ids)
  iam_instance_profile_name   = aws_iam_instance_profile.nomad_client.name

  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    username       = var.username
    ssh_public_key = var.ssh_public_key
    nomad_join     = "provider=aws tag_key=Role tag_value=nomad-server region=${data.aws_region.current.region}"
    consul_join    = "provider=aws tag_key=Role tag_value=consul-server region=${data.aws_region.current.region}"
  })

  min_size                  = var.min_size
  desired_capacity          = var.desired_capacity
  max_size                  = var.max_size
  health_check_type         = "EC2"
  health_check_grace_period = var.health_check_grace_period
  instance_refresh_enabled  = var.instance_refresh_enabled

  tags = merge(var.tags, {
    Name = var.name
    Role = "nomad-client"
  })
}
