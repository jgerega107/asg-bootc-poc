# bootc-images

Creates a private bucket for bootc disk images used by the
`bootc-image-builder` AWS AMI uploader. It uses S3's default server-side
encryption and prevents public access.

Bucket names are globally unique, so include an account or environment suffix:

```hcl
module "bootc_images" {
  source = "./modules/bootc-images"

  bucket_name = "bootc-images-123456789012-us-east-1"

  tags = {
    Environment = "production"
  }
}
```

The module also creates the `vmimport` service role required by the AWS AMI
uploader. The role can inspect and remove intermediate objects in this bucket
and perform the snapshot/image operations required to create an AMI. The
identity invoking the upload must also have `iam:PassRole` permission for this
role. If the account uses a customer-managed KMS key for EBS encryption, grant
the role the KMS permissions required by VM Import/Export.
