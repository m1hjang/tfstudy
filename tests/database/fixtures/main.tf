terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# ── Network (inlined — no remote_state needed in fixture lifecycle) ─────────────
module "network" {
  source = "../../../modules/network"

  project         = var.project
  env             = var.env
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
}

# ── Data subnet split (mirrors db-service-1 root module logic) ─────────────────
locals {
  private_subnet_ids = module.network.private_subnet_ids

  data_cidrs_sorted = sort(var.data_subnet_cidrs)
  db_subnet_ids     = [for cidr in slice(local.data_cidrs_sorted, 0, length(local.data_cidrs_sorted) - 1) : local.private_subnet_ids[cidr]]
  etcd_subnet_ids   = [for cidr in local.data_cidrs_sorted : local.private_subnet_ids[cidr]]
}

# ── Database module ────────────────────────────────────────────────────────────
module "database" {
  source = "../../../modules/database"

  project            = var.project
  env                = var.env
  vpc_id             = module.network.vpc_id
  vpc_cidr           = module.network.vpc_cidr
  db_subnet_ids      = local.db_subnet_ids
  etcd_subnet_ids    = local.etcd_subnet_ids
  instance_type      = var.db_instance_type
  etcd_instance_type = var.etcd_instance_type
  ami_id             = data.aws_ami.amazon_linux_2.id
  db_port            = var.db_port
  key_name           = var.key_name != "" ? var.key_name : null
}

# ── Data tier NACL (same logic as db-service-1/dev) ───────────────────────────
resource "aws_network_acl" "data" {
  vpc_id     = module.network.vpc_id
  subnet_ids = [for cidr in var.data_subnet_cidrs : local.private_subnet_ids[cidr]]

  tags = {
    Name    = "${var.project}-${var.env}-data-nacl"
    Project = var.project
    Env     = var.env
  }
}

resource "aws_network_acl_rule" "data_in_pg_from_app" {
  for_each       = { for i, cidr in sort(var.app_subnet_cidrs) : tostring(100 + i * 10) => cidr }
  network_acl_id = aws_network_acl.data.id
  rule_number    = tonumber(each.key)
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = each.value
  from_port      = 5432
  to_port        = 5432
}

resource "aws_network_acl_rule" "data_in_pg_from_data" {
  for_each       = { for i, cidr in sort(var.data_subnet_cidrs) : tostring(200 + i * 10) => cidr }
  network_acl_id = aws_network_acl.data.id
  rule_number    = tonumber(each.key)
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = each.value
  from_port      = 5432
  to_port        = 5432
}

resource "aws_network_acl_rule" "data_in_etcd_client_from_data" {
  for_each       = { for i, cidr in sort(var.data_subnet_cidrs) : tostring(300 + i * 10) => cidr }
  network_acl_id = aws_network_acl.data.id
  rule_number    = tonumber(each.key)
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = each.value
  from_port      = 2379
  to_port        = 2379
}

resource "aws_network_acl_rule" "data_in_etcd_peer_from_data" {
  for_each       = { for i, cidr in sort(var.data_subnet_cidrs) : tostring(400 + i * 10) => cidr }
  network_acl_id = aws_network_acl.data.id
  rule_number    = tonumber(each.key)
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = each.value
  from_port      = 2380
  to_port        = 2380
}

resource "aws_network_acl_rule" "data_in_eph_from_app" {
  for_each       = { for i, cidr in sort(var.app_subnet_cidrs) : tostring(500 + i * 10) => cidr }
  network_acl_id = aws_network_acl.data.id
  rule_number    = tonumber(each.key)
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = each.value
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "data_in_eph_from_data" {
  for_each       = { for i, cidr in sort(var.data_subnet_cidrs) : tostring(600 + i * 10) => cidr }
  network_acl_id = aws_network_acl.data.id
  rule_number    = tonumber(each.key)
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = each.value
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "data_out_eph_to_app" {
  for_each       = { for i, cidr in sort(var.app_subnet_cidrs) : tostring(100 + i * 10) => cidr }
  network_acl_id = aws_network_acl.data.id
  rule_number    = tonumber(each.key)
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = each.value
  from_port      = 1024
  to_port        = 65535
}

resource "aws_network_acl_rule" "data_out_pg_to_data" {
  for_each       = { for i, cidr in sort(var.data_subnet_cidrs) : tostring(200 + i * 10) => cidr }
  network_acl_id = aws_network_acl.data.id
  rule_number    = tonumber(each.key)
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = each.value
  from_port      = 5432
  to_port        = 5432
}

resource "aws_network_acl_rule" "data_out_etcd_client_to_data" {
  for_each       = { for i, cidr in sort(var.data_subnet_cidrs) : tostring(300 + i * 10) => cidr }
  network_acl_id = aws_network_acl.data.id
  rule_number    = tonumber(each.key)
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = each.value
  from_port      = 2379
  to_port        = 2379
}

resource "aws_network_acl_rule" "data_out_etcd_peer_to_data" {
  for_each       = { for i, cidr in sort(var.data_subnet_cidrs) : tostring(400 + i * 10) => cidr }
  network_acl_id = aws_network_acl.data.id
  rule_number    = tonumber(each.key)
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = each.value
  from_port      = 2380
  to_port        = 2380
}

resource "aws_network_acl_rule" "data_out_eph_to_data" {
  for_each       = { for i, cidr in sort(var.data_subnet_cidrs) : tostring(500 + i * 10) => cidr }
  network_acl_id = aws_network_acl.data.id
  rule_number    = tonumber(each.key)
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = each.value
  from_port      = 1024
  to_port        = 65535
}

# ── Outputs ────────────────────────────────────────────────────────────────────
output "vpc_id" {
  value = module.network.vpc_id
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "db_instance_ids" {
  value = module.database.db_instance_ids
}

output "db_private_ips" {
  value = module.database.db_private_ips
}

output "db_security_group_id" {
  value = module.database.db_security_group_id
}

output "etcd_instance_ids" {
  value = module.database.etcd_instance_ids
}

output "etcd_private_ips" {
  value = module.database.etcd_private_ips
}

output "etcd_security_group_id" {
  value = module.database.etcd_security_group_id
}
