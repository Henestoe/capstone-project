variable "name" {
  description = "Name used when naming network resources."
  type        = string
}

variable "vpc_cidr" {
  description = "Private IPv4 address range for the VPC."
  type        = string
}

variable "subnet_cidr" {
  description = "IPv4 address range for the cluster subnet."
  type        = string
}

variable "availability_zone" {
  description = "Availability Zone for the cluster subnet."
  type        = string
}