data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "cloud_join" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.name}-vm"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = merge(var.tags, {
    Name = "${var.name}-vm"
    Role = "vm"
  })
}

resource "aws_iam_role_policy" "cloud_join" {
  name   = "${var.name}-vm-cloud-join"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.cloud_join.json
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.name}-vm"
  role = aws_iam_role.this.name

  tags = merge(var.tags, {
    Name = "${var.name}-vm"
    Role = "vm"
  })
}
