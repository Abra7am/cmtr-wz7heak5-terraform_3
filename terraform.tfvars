aws_region = "us-east-1"

vpc_cidr = "10.10.0.0/16"

public_subnets = {
  a = {
    cidr_block = "10.10.1.0/24"
    az         = "us-east-1a"
    name       = "cmtr-wz7heak5-01-subnet-public-a"
  }
  b = {
    cidr_block = "10.10.3.0/24"
    az         = "us-east-1b"
    name       = "cmtr-wz7heak5-01-subnet-public-b"
  }
  c = {
    cidr_block = "10.10.5.0/24"
    az         = "us-east-1c"
    name       = "cmtr-wz7heak5-01-subnet-public-c"
  }
}
