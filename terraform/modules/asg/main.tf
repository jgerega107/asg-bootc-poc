locals {
  instance_tags = merge(var.tags, {
    Name = var.name
  })

  root_volume_tags = merge(var.tags, {
    Name = "${var.name}-root"
  })
}

resource "aws_launch_template" "this" {
  name          = var.name
  image_id      = var.ami
  instance_type = var.instance_type

  user_data = var.user_data == null ? null : base64encode(var.user_data)

  dynamic "iam_instance_profile" {
    for_each = var.iam_instance_profile_name == null ? [] : [var.iam_instance_profile_name]

    content {
      name = iam_instance_profile.value
    }
  }

  # Launch templates cannot set source_dest_check. Use a separately managed
  # network interface if a workload needs that setting disabled.
  vpc_security_group_ids = var.associate_public_ip_address ? null : var.vpc_security_group_ids

  dynamic "network_interfaces" {
    for_each = var.associate_public_ip_address ? [true] : []

    content {
      associate_public_ip_address = true
      delete_on_termination       = true
      device_index                = 0
      security_groups             = length(var.vpc_security_group_ids) > 0 ? var.vpc_security_group_ids : null
    }
  }

  block_device_mappings {
    device_name = var.root_device_name

    ebs {
      volume_size           = var.root_disk_size
      volume_type           = "gp3"
      encrypted             = var.root_disk_encrypted
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = local.instance_tags
  }

  tag_specifications {
    resource_type = "volume"
    tags          = local.root_volume_tags
  }

  tags = local.instance_tags
}

resource "aws_autoscaling_group" "this" {
  name                      = var.name
  min_size                  = var.min_size
  max_size                  = var.max_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = var.subnet_ids
  health_check_type         = var.health_check_type
  health_check_grace_period = var.health_check_grace_period
  default_instance_warmup   = var.default_instance_warmup
  force_delete              = var.force_delete
  target_group_arns         = var.target_group_arns
  termination_policies      = var.termination_policies

  launch_template {
    id      = aws_launch_template.this.id
    version = tostring(aws_launch_template.this.latest_version)
  }

  dynamic "tag" {
    for_each = local.instance_tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  dynamic "instance_refresh" {
    for_each = var.instance_refresh_enabled ? [true] : []

    content {
      strategy = "Rolling"

      preferences {
        min_healthy_percentage = var.instance_refresh_min_healthy_percentage
        instance_warmup        = var.instance_refresh_warmup
      }
    }
  }

  lifecycle {
    precondition {
      condition     = var.min_size <= var.desired_capacity && var.desired_capacity <= var.max_size
      error_message = "desired_capacity must be between min_size and max_size."
    }
  }
}
