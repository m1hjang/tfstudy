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
  #   key            = "services/web-service-1/dev/terraform.tfstate"
  #   region         = "ap-northeast-2"
  #   dynamodb_table = "terraform-state-lock"
  #   encrypt        = true
  # }
}

provider "aws" {
  access_key = var.ACCESS_KEY
  secret_key = var.SECRET_KEY
  region = var.aws_region
}


data "terraform_remote_state" "shared" {
  backend = "local"
  config = {
    path = "${path.module}/../../../shared/dev/terraform.tfstate"
  }

  # S3 backend로 이전 후 위 블록을 아래로 교체:
  # backend = "s3"
  # config = {
  #   bucket = "YOUR-TF-STATE-BUCKET"
  #   key    = "shared/dev/terraform.tfstate"
  #   region = "ap-northeast-2"
  # }
}

module "compute" {
  source = "../../../modules/compute"

  project            = var.project
  env                = var.env
  vpc_id             = data.terraform_remote_state.shared.outputs.vpc_id
  public_subnet_ids  = data.terraform_remote_state.shared.outputs.public_subnet_ids
  private_subnet_ids = data.terraform_remote_state.shared.outputs.private_subnet_ids
  instance_type      = var.app_instance_type
  ami_id             = var.ami_id
  key_name           = var.key_name
  app_port           = var.app_port
  instance_count     = var.app_instance_count
}

module "database" {
  source = "../../../modules/database"

  project               = var.project
  env                   = var.env
  vpc_id                = data.terraform_remote_state.shared.outputs.vpc_id
  private_subnet_ids    = data.terraform_remote_state.shared.outputs.private_subnet_ids
  app_security_group_id = module.compute.app_security_group_id
  instance_type         = var.db_instance_type
  ami_id                = var.ami_id
  key_name              = var.key_name
  db_port               = var.db_port
  data_volume_size_gb   = var.db_volume_size_gb
}
