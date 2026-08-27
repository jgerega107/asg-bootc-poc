module "vpc" {
  source = "../../modules/vpc"

  name = var.vpc_name
}

module "ami_bucket" {
  source = "../../modules/ami-bucket"

  bucket_name = var.bucket_name
}
