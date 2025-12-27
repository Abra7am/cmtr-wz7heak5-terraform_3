variable "aws_region" {
  description = "AWS region for resources"
  type        = string
}

variable "project_id" {
  description = "Project identifier for tagging"
  type        = string
}

variable "state_bucket" {
  description = "S3 bucket name for remote Terraform state"
  type        = string
}

variable "state_key" {
  description = "S3 key path for remote Terraform state file"
  type        = string
}
