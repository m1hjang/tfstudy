terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # ── Local state (현재) ──────────────────────────────────────────────────────
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
  # 자격증명은 환경변수로 주입:
  #   export AWS_ACCESS_KEY_ID="..."
  #   export AWS_SECRET_ACCESS_KEY="..."
}

module "network" {
  source = "../../modules/network"

  project              = var.project
  env                  = var.env
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = var.azs
}
