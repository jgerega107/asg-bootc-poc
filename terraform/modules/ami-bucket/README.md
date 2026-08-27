# bootc-images

Creates a private bucket for bootc disk images used by the EC2 VM Import/Export
workflow. It uses S3's default server-side encryption and prevents public
access.

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

The module intentionally does not create the `vmimport` service role; that can
be added separately when the import workflow is wired up.
