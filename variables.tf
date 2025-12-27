variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnets" {
  description = "Public subnet configurations"
  type = map(object({
    cidr_block = string
    az         = string
    name       = string
  }))
}
