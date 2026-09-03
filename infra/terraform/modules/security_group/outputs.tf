output "nodes_id" {
  description = "Security group ID shared by all cluster nodes."
  value       = aws_security_group.nodes.id
}

output "server_id" {
  description = "Additional security group ID for the control plane."
  value       = aws_security_group.server.id
}