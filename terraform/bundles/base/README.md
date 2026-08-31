# Base bundle

Creates the shared single-AZ VPC, its private application subnet with a shared
NAT Gateway, and the S3 image bucket. Their names are configured in
`terraform.tfvars`; the checked-in development values are `test-bootc` and
`bootc-images`.

```hcl
tofu init
tofu plan
```

Run these commands from `terraform/bundles/base`. Because S3 bucket names are
global, applying the checked-in configuration will fail if another AWS account
already owns `bootc-images`.
