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
  #   key            = "shared/prod/terraform.tfstate"
  #   region         = "ap-northeast-2"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region
}

module "network" {
  source = "../../modules/network"

  project         = var.project
  env             = var.env
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
}

module "bastion" {
  source = "../../modules/bastion"

  project          = var.project
  env              = var.env
  vpc_id           = module.network.vpc_id
  subnet_id        = module.network.public_subnet_ids[0]
  ami_id           = var.bastion_ami_id
  key_name         = var.bastion_key_name
  ssh_allowed_cidr = var.bastion_ssh_allowed_cidr
  ansible_repo_url = var.ansible_repo_url
}
