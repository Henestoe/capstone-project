variable "name" {
  description = "Name used for the cluster instances and SSH key."
  type        = string
}

variable "ami_id" {
  description = "Ubuntu AMI ID for the instances."
  type        = string
}

variable "public_key" {
  description = "SSH public key to register with AWS."
  type        = string
}

variable "subnet_id" {
  description = "Subnet in which to launch the instances."
  type        = string
}

variable "nodes_security_group_id" {
  description = "Security group attached to all nodes."
  type        = string
}

variable "server_security_group_id" {
  description = "Additional security group attached to the control plane."
  type        = string
}

variable "nodes" {
  description = "Node names and their configuration."
  type = map(object({
    role          = string
    instance_type = string
    disk_size     = number
  }))

  validation {
    condition = alltrue([
      for node in values(var.nodes) :
      contains(["server", "worker"], node.role)
    ])
    error_message = "Each node role must be server or worker."
  }

  validation {
    condition = (
      length([for node in values(var.nodes) : node if node.role == "server"]) == 1 &&
      length([for node in values(var.nodes) : node if node.role == "worker"]) >= 2
    )
    error_message = "Configure exactly one server and at least two workers."
  }
}