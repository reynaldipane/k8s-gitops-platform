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

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "node_instance_type" {
  description = "EC2 instance type for Kubernetes nodes"
  type        = string
  default     = "t3.medium"
}

variable "kube_minor" {
  description = "Kubernetes minor version (pkgs.k8s.io repo)"
  type        = string
  default     = "v1.36"
}

variable "calico_version" {
  description = "Calico release for the Tigera operator manifests"
  type        = string
  default     = "v3.33.0"
}

variable "pod_cidr" {
  description = "Pod network CIDR (must not overlap the VPC)"
  type        = string
  default     = "192.168.0.0/16"
}
