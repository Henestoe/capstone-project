resource "aws_key_pair" "main" {
  key_name   = "${var.name}-ssh"
  public_key = var.public_key

  tags = {
    Name = "${var.name}-ssh"
  }
}

resource "aws_instance" "nodes" {
  for_each = var.nodes

  ami                         = var.ami_id
  instance_type               = each.value.instance_type
  subnet_id                   = var.subnet_id
  key_name                    = aws_key_pair.main.key_name
  associate_public_ip_address = true
  iam_instance_profile        = each.value.role == "server" ? aws_iam_instance_profile.ssm.name : null

  vpc_security_group_ids = each.value.role == "server" ? [
    var.nodes_security_group_id,
    var.server_security_group_id
    ] : [
    var.nodes_security_group_id
  ]

  root_block_device {
    volume_type           = "gp3"
    volume_size           = each.value.disk_size
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "disabled"
  }

  credit_specification {
    cpu_credits = "standard"
  }

  tags = {
    Name = "${var.name}-${each.key}"
    Role = each.value.role
  }

  volume_tags = {
    Name = "${var.name}-${each.key}-root"
  }
}
