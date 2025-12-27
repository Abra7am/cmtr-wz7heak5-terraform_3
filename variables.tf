variable "aws_region" {
  description = "AWS region where resources will be deployed"
  type        = string
}

variable "project_id" {
  description = "Project identifier used for resource tagging"
  type        = string
}

variable "ssh_key_name" {
  description = "SSH key pair name for EC2 instances"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet IDs for ALB and Auto Scaling Group"
  type        = list(string)
}
