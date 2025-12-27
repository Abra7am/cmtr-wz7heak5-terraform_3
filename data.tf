provider "aws" {
  region = var.aws_region
}

data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_name]
  }
}

data "aws_subnet" "public" {
  filter {
    name   = "tag:Name"
    values = [var.public_subnet_name]
  }

  vpc_id = data.aws_vpc.this.id
}

data "aws_security_group" "this" {
  filter {
    name   = "group-name"
    values = [var.security_group_name]
  }

  vpc_id = data.aws_vpc.this.id
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}
