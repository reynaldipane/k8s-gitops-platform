variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix for resource names and tags"
  type        = string
  default     = "k8s-gitops"
}