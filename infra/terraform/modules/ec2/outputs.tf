output "nodes" {
  description = "Instance IDs, roles, and IP addresses for Ansible."
  value = {
    for name, instance in aws_instance.nodes : name => {
      instance_id = instance.id
      role        = var.nodes[name].role
      public_ip   = instance.public_ip
      private_ip  = instance.private_ip
    }
  }
}