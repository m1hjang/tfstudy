terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }

  # backend "s3" {
  #   bucket         = "YOUR-TF-STATE-BUCKET"
  #   key            = "services/db-service-1/dev/terraform.tfstate"
  #   region         = "ap-northeast-2"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.ACCESS_KEY
  secret_key = var.SECRET_KEY
}

data "terraform_remote_state" "shared" {
  backend = "local"
  config = {
    path = "${path.module}/../../../shared/dev/terraform.tfstate"
  }

  # backend = "s3"
  # config = {
  #   bucket = "YOUR-TF-STATE-BUCKET"
  #   key    = "shared/dev/terraform.tfstate"
  #   region = "ap-northeast-2"
  # }
}

locals {
  private_subnet_ids = data.terraform_remote_state.shared.outputs.private_subnet_ids

  # Sort data CIDRs so the split is deterministic across applies.
  # Last CIDR (alphabetically) is reserved for the etcd-only quorum node.
  data_cidrs_sorted = sort(var.data_subnet_cidrs)

  db_subnet_ids   = [for cidr in slice(local.data_cidrs_sorted, 0, length(local.data_cidrs_sorted) - 1) : local.private_subnet_ids[cidr]]
  etcd_subnet_ids = [for cidr in local.data_cidrs_sorted : local.private_subnet_ids[cidr]]
}

module "database" {
  source = "../../../modules/database"

  project                   = var.project
  env                       = var.env
  vpc_id                    = data.terraform_remote_state.shared.outputs.vpc_id
  vpc_cidr                  = data.terraform_remote_state.shared.outputs.vpc_cidr
  db_subnet_ids             = local.db_subnet_ids
  etcd_subnet_ids           = local.etcd_subnet_ids
  bastion_security_group_id = data.terraform_remote_state.shared.outputs.bastion_security_group_id
  instance_type             = var.db_instance_type
  etcd_instance_type        = var.etcd_instance_type
  ami_id                    = var.ami_id
  key_name                  = var.key_name
  db_port                   = var.db_port
  data_volume_size_gb       = var.db_volume_size_gb
}

# ── Data tier NACL ────────────────────────────────────────────────────────────
# Owns the network access policy for data subnets.
# NACL is stateless: both inbound and outbound rules are required.

resource "aws_network_acl" "data" {
  vpc_id     = data.terraform_remote_state.shared.outputs.vpc_id
  subnet_ids = [for cidr in var.data_subnet_cidrs : local.private_subnet_ids[cidr]]

  tags = {
    Name    = "${var.project}-${var.env}-data-nacl"
    Project = var.project
    Env     = var.env
  }
}

# Inbound: app -> data (PostgreSQL 5432)
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

# Inbound: data -> data (PostgreSQL replication 5432)
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

# Inbound: data -> data (etcd client 2379)
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

# Inbound: data -> data (etcd peer 2380)
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

# Inbound: ephemeral return from app (NACL stateless — response traffic)
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

# Inbound: ephemeral return from data (intra-tier responses)
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

# Outbound: data -> app (ephemeral — PostgreSQL query responses)
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

# Outbound: data -> data (PostgreSQL replication 5432)
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

# Outbound: data -> data (etcd client 2379)
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

# Outbound: data -> data (etcd peer 2380)
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

# Outbound: ephemeral to data (intra-tier responses)
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
