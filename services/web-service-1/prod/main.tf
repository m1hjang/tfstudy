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
  #   key            = "services/web-service-1/prod/terraform.tfstate"
  #   region         = "ap-northeast-2"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region
}

data "terraform_remote_state" "shared" {
  backend = "local"
  config = {
    path = "${path.module}/../../../shared/prod/terraform.tfstate"
  }

  # backend = "s3"
  # config = {
  #   bucket = "YOUR-TF-STATE-BUCKET"
  #   key    = "shared/prod/terraform.tfstate"
  #   region = "ap-northeast-2"
  # }
}

data "terraform_remote_state" "db" {
  backend = "local"
  config = {
    path = "${path.module}/../../db-service-1/prod/terraform.tfstate"
  }

  # backend = "s3"
  # config = {
  #   bucket = "YOUR-TF-STATE-BUCKET"
  #   key    = "services/db-service-1/prod/terraform.tfstate"
  #   region = "ap-northeast-2"
  # }
}

locals {
  private_subnet_ids  = data.terraform_remote_state.shared.outputs.private_subnet_ids
  private_subnet_azs  = data.terraform_remote_state.shared.outputs.private_subnet_azs
  nat_route_table_ids = data.terraform_remote_state.shared.outputs.nat_route_table_ids
}

resource "aws_route_table_association" "app" {
  for_each       = toset(var.app_subnet_cidrs)
  subnet_id      = local.private_subnet_ids[each.value]
  route_table_id = local.nat_route_table_ids[local.private_subnet_azs[each.value]]
}

module "compute" {
  source = "../../../modules/compute"

  project                   = var.project
  env                       = var.env
  vpc_id                    = data.terraform_remote_state.shared.outputs.vpc_id
  public_subnet_ids         = data.terraform_remote_state.shared.outputs.public_subnet_ids
  private_subnet_ids        = [for cidr in var.app_subnet_cidrs : local.private_subnet_ids[cidr]]
  instance_type             = var.app_instance_type
  ami_id                    = var.ami_id
  key_name                  = var.key_name
  app_port                  = var.app_port
  instance_count            = var.app_instance_count
  bastion_security_group_id = data.terraform_remote_state.shared.outputs.bastion_security_group_id

  depends_on = [aws_route_table_association.app]
}
