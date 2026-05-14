project              = "tfstudy-web-infra"
env                  = "dev"
vpc_cidr             = "10.10.0.0/16"
public_subnet_cidrs  = ["10.10.1.0/24", "10.10.2.0/24"]
private_subnet_cidrs = ["10.10.11.0/24", "10.10.12.0/24"]
azs                  = ["ap-northeast-2a", "ap-northeast-2c"]
