resource "aws_security_group" "nodes" {
  name        = "${var.name}-nodes"
  description = "Shared access rules for k3s nodes"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name}-nodes"
  }
}

resource "aws_security_group" "server" {
  name        = "${var.name}-server"
  description = "Kubernetes API access for the k3s server"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name}-server"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.nodes.id
  description       = "SSH from the administrator IP"
  cidr_ipv4         = var.ssh_cidr
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.nodes.id
  description       = "Public HTTP"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.nodes.id
  description       = "Public HTTPS"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "flannel" {
  security_group_id            = aws_security_group.nodes.id
  referenced_security_group_id = aws_security_group.nodes.id
  description                  = "Flannel VXLAN between nodes"
  ip_protocol                  = "udp"
  from_port                    = 8472
  to_port                      = 8472
}

resource "aws_vpc_security_group_ingress_rule" "kubelet" {
  security_group_id            = aws_security_group.nodes.id
  referenced_security_group_id = aws_security_group.nodes.id
  description                  = "Kubelet metrics between nodes"
  ip_protocol                  = "tcp"
  from_port                    = 10250
  to_port                      = 10250
}

resource "aws_vpc_security_group_ingress_rule" "api" {
  security_group_id            = aws_security_group.server.id
  referenced_security_group_id = aws_security_group.nodes.id
  description                  = "Kubernetes API from cluster nodes"
  ip_protocol                  = "tcp"
  from_port                    = 6443
  to_port                      = 6443
}

resource "aws_vpc_security_group_egress_rule" "outbound" {
  security_group_id = aws_security_group.nodes.id
  description       = "Outbound IPv4 traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}