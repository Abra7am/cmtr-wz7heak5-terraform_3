variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "project_id" {
  description = "Project identifier"
  type        = string
}

variable "ssh_key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "public_subnets" {
  description = "Public subnet IDs"
  type        = list(string)
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}
