variable "aws_region" {
  description = "AWS region where the infrastructure will be deployed."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming and tagging."
  type        = string
  default     = "taskapp"
}

variable "environment" {
  description = "Dev"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "Private IPv4 address range for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "IPv4 address range for the cluster subnet."
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "Availability Zone for the cluster subnet."
  type        = string
  default     = "us-east-1a"
}

variable "ssh_cidr" {
  description = "Administrator public IPv4 address with /32."
  type        = string
}

variable "ami_id" {
  description = "Ubuntu AMI ID for the cluster nodes."
  type        = string
}

variable "ssh_public_key_path" {
  description = "Local path to the SSH public key."
  type        = string
}

variable "nodes" {
  description = "Configuration for the cluster nodes."
  type = map(object({
    role          = string
    instance_type = string
    disk_size     = number
  }))

  default = {
    server = {
      role          = "server"
      instance_type = "t3.medium"
      disk_size     = 30
    }

    worker-1 = {
      role          = "worker"
      instance_type = "t3.small"
      disk_size     = 30
    }

    worker-2 = {
      role          = "worker"
      instance_type = "t3.small"
      disk_size     = 30
    }
  }
}