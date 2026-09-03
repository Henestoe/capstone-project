variable "name" {
  description = "Name used for the cluster security groups."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC containing the security groups."
  type        = string
}

variable "ssh_cidr" {
  description = "Public IPv4 address allowed to connect over SSH, with /32."
  type        = string

  validation {
    condition = (
      can(cidrnetmask(var.ssh_cidr)) &&
      can(regex("/32$", var.ssh_cidr))
    )
    error_message = "Provide one IPv4 address with /32, such as 203.0.113.10/32."
  }
}