project  = "my-infra"
env      = "prod"
vpc_cidr = "10.20.0.0/16"

public_subnets = {
  "10.20.1.0/24" = "ap-northeast-2a"
  "10.20.2.0/24" = "ap-northeast-2c"
}

private_subnets = {
  "10.20.11.0/24" = "ap-northeast-2a"
  "10.20.12.0/24" = "ap-northeast-2c"
}
