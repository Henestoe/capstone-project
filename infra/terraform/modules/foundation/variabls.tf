variable "project_name" {
  description = "Project name used for resource naming."
  type        = string
  default     = "taskapp"
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC."
  type        = string
  default     = "10.20.0.0/16"
}