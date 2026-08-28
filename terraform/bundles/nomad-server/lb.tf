# Private Network Load Balancer for the Nomad HTTP API.
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
