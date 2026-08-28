data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "this" {
  bucket = format("${var.bucket_name}-%s", data.aws_caller_identity.current.account_id)

  tags = merge(var.tags, {
    Name = var.bucket_name
  })
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "vmimport" {
  name = var.vmimport_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "vmie.amazonaws.com"
      }
      Action = "sts:AssumeRole"
      Condition = {
        StringEquals = {
          "sts:Externalid" = "vmimport"
        }
      }
    }]
  })

  tags = merge(var.tags, {
    Name = var.vmimport_role_name
  })
}

resource "aws_iam_role_policy" "vmimport" {
  name = var.vmimport_role_name
  role = aws_iam_role.vmimport.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "InspectImportBuckets"
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:GetBucketAcl",
        ]
        Resource = aws_s3_bucket.this.arn
      },
      {
        Sid      = "ListAllBuckets"
        Effect   = "Allow"
        Action   = ["s3:ListAllMyBuckets"]
        Resource = "*"
      },
      {
        Sid    = "ManageImportObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:DeleteObject",
        ]
        Resource = "${aws_s3_bucket.this.arn}/*"
      },
      {
        Sid    = "ImportSnapshotsAndImages"
        Effect = "Allow"
        Action = [
          "ec2:ModifySnapshotAttribute",
          "ec2:CopySnapshot",
          "ec2:RegisterImage",
          "ec2:Describe*",
        ]
        Resource = "*"
      },
    ]
  })
}
