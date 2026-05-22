project  = "tfstudy-web-infra"
env      = "dev"
vpc_cidr = "10.10.0.0/16"

public_subnets = {
  "10.10.1.0/24" = "ap-northeast-2a"
  "10.10.2.0/24" = "ap-northeast-2c"
}

private_subnets = {
  "10.10.11.0/24" = "ap-northeast-2a"
  "10.10.12.0/24" = "ap-northeast-2c"
}
