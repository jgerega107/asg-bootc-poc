# IAM permissions used by Nomad and Consul AWS cloud auto-join.
data "aws_iam_policy_document" "nomad_client_assume_role" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "nomad_client_cloud_join" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role" "nomad_client" {
  name               = var.name
  assume_role_policy = data.aws_iam_policy_document.nomad_client_assume_role.json

  tags = merge(var.tags, {
    Name = var.name
    Role = "nomad-client"
  })
}

resource "aws_iam_role_policy" "nomad_client_cloud_join" {
  name   = "${var.name}-cloud-join"
  role   = aws_iam_role.nomad_client.id
  policy = data.aws_iam_policy_document.nomad_client_cloud_join.json
}

resource "aws_iam_instance_profile" "nomad_client" {
  name = var.name
  role = aws_iam_role.nomad_client.name

  tags = merge(var.tags, {
    Name = var.name
    Role = "nomad-client"
  })
}
