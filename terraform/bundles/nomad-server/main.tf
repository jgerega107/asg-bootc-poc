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

data "aws_iam_policy_document" "nomad_assume_role" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "nomad_cloud_join" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role" "nomad_server" {
  name               = "${var.name}-nomad-server"
  assume_role_policy = data.aws_iam_policy_document.nomad_assume_role.json

  tags = merge(var.tags, {
    Name = "${var.name}-nomad-server"
    Role = "nomad-server"
  })
}

resource "aws_iam_role_policy" "nomad_cloud_join" {
  name   = "${var.name}-cloud-join"
  role   = aws_iam_role.nomad_server.id
  policy = data.aws_iam_policy_document.nomad_cloud_join.json
}

resource "aws_iam_instance_profile" "nomad_server" {
  name = "${var.name}-nomad-server"
  role = aws_iam_role.nomad_server.name

  tags = merge(var.tags, {
    Name = "${var.name}-nomad-server"
    Role = "nomad-server"
  })
}

resource "aws_security_group" "nomad_nlb" {
  name        = "${var.name}-nlb-sg"
  description = "Security group for the Nomad server Network Load Balancer"
  vpc_id      = data.aws_vpc.base.id

  ingress {
    description = "Nomad traffic to the private endpoint"
    protocol    = "tcp"
    from_port   = 4646
    to_port     = 4646
    cidr_blocks = local.endpoint_cidr_blocks
  }

  egress {
    description = "Outbound traffic to Nomad servers"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name}-nlb-sg"
    Role = "nomad-server-endpoint"
  })
}

resource "aws_security_group" "nomad_server" {
  name        = "${var.name}-sg"
  description = "Security group for Nomad server instances"
  vpc_id      = data.aws_vpc.base.id

  ingress {
    description = "SSH from the public subnet"
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = [data.aws_subnet.public.cidr_block]
  }

  ingress {
    description     = "Nomad TCP traffic from the internal load balancer"
    protocol        = "tcp"
    from_port       = 4646
    to_port         = 4646
    security_groups = [aws_security_group.nomad_nlb.id]
  }

  ingress {
    description = "Nomad TCP traffic between servers"
    protocol    = "tcp"
    from_port   = 4646
    to_port     = 4648
    self        = true
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

resource "aws_lb" "nomad" {
  name               = "${var.name}-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = [data.terraform_remote_state.base.outputs.private_subnet_id]
  security_groups    = [aws_security_group.nomad_nlb.id]

  tags = merge(var.tags, {
    Name = "${var.name}-nlb"
    Role = "nomad-server-endpoint"
  })
}

resource "aws_lb_target_group" "nomad" {
  name               = "${var.name}-http"
  port               = 4646
  protocol           = "TCP"
  target_type        = "instance"
  vpc_id             = data.aws_vpc.base.id
  preserve_client_ip = false

  health_check {
    enabled             = true
    protocol            = "HTTP"
    port                = 4646
    path                = var.health_check_path
    matcher             = "200"
    interval            = 30
    timeout             = 6
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = merge(var.tags, {
    Name = "${var.name}-http"
    Role = "nomad-server-endpoint"
  })
}

resource "aws_lb_listener" "nomad" {
  load_balancer_arn = aws_lb.nomad.arn
  port              = 4646
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nomad.arn
  }
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
    server_join    = "provider=aws tag_key=Name tag_value=${var.name} region=${data.aws_region.current.region}"
  })

  min_size                  = var.min_size
  desired_capacity          = var.desired_capacity
  max_size                  = var.max_size
  health_check_type         = "ELB"
  health_check_grace_period = var.health_check_grace_period
  target_group_arns         = [aws_lb_target_group.nomad.arn]
  instance_refresh_enabled  = var.instance_refresh_enabled

  tags = merge(var.tags, {
    Name = var.name
    Role = "nomad-server"
  })
}
