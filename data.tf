provider "aws" {
  region = var.aws_region
}

data "terraform_remote_state" "base_infra" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = var.state_key
    region = var.aws_region
  }
}
