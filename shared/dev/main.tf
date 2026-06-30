terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # ── Local state ──────────────────────────────────────────────────────
  backend "local" {
    path = "terraform.tfstate"
  }

  # ── S3 backend로 이전할 때 위 backend "local" 블록을 아래로 교체 ─────────────
  # backend "s3" {
  #   bucket         = "YOUR-TF-STATE-BUCKET"
  #   key            = "shared/dev/terraform.tfstate"
  #   region         = "ap-northeast-2"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region
  access_key = var.ACCESS_KEY
  secret_key = var.SECRET_KEY
}

module "network" {
  source = "../../modules/network"

  project        = var.project
  env            = var.env
  vpc_cidr       = var.vpc_cidr
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
