# IAM permissions used by Consul's AWS cloud auto-join.
data "aws_iam_policy_document" "consul_assume_role" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "consul_cloud_join" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role" "consul_server" {
  name               = var.name
  assume_role_policy = data.aws_iam_policy_document.consul_assume_role.json

  tags = merge(var.tags, {
    Name = var.name
    Role = "consul-server"
  })
}

resource "aws_iam_role_policy" "consul_cloud_join" {
  name   = "${var.name}-cloud-join"
  role   = aws_iam_role.consul_server.id
  policy = data.aws_iam_policy_document.consul_cloud_join.json
}

resource "aws_iam_instance_profile" "consul_server" {
  name = var.name
  role = aws_iam_role.consul_server.name

  tags = merge(var.tags, {
    Name = var.name
    Role = "consul-server"
  })
}
