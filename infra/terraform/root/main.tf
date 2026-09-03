module "vpc" {
  source = "../modules/vpc"

  name              = "${var.project_name}-${var.environment}-vpc"
  vpc_cidr          = var.vpc_cidr
  subnet_cidr       = var.subnet_cidr
  availability_zone = var.availability_zone
}

module "security_group" {
  source = "../modules/security_group"

  name     = "${var.project_name}-${var.environment}"
  vpc_id   = module.vpc.vpc_id
  ssh_cidr = var.ssh_cidr
}

module "ec2" {
  source = "../modules/ec2"

  name                     = "${var.project_name}-${var.environment}"
  ami_id                   = var.ami_id
  public_key               = file(pathexpand(var.ssh_public_key_path))
  subnet_id                = module.vpc.subnet_id
  nodes_security_group_id  = module.security_group.nodes_id
  server_security_group_id = module.security_group.server_id
  nodes                    = var.nodes
}