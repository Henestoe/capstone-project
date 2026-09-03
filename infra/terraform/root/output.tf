output "vpc_id" {
  description = "ID of the cluster VPC."
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "IPv4 address range of the cluster VPC."
  value       = module.vpc.vpc_cidr_block
}

output "subnet_id" {
  description = "ID of the cluster subnet."
  value       = module.vpc.subnet_id
}

output "nodes_security_group_id" {
  description = "Security group ID shared by the cluster nodes."
  value       = module.security_group.nodes_id
}

output "server_security_group_id" {
  description = "Additional security group ID for the control plane."
  value       = module.security_group.server_id
}

output "nodes" {
  description = "Cluster node details for SSH and Ansible."
  value       = module.ec2.nodes
}