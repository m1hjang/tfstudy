project  = "my-infra"
env      = "prod"

bastion_ami_id           = "ami-035f4c601044a7af4"
bastion_key_name         = "seoul-ed25519"
bastion_ssh_allowed_cidr = "0.0.0.0/0"
ansible_repo_url         = ""
vpc_cidr = "10.20.0.0/16"

public_subnets = {
  "10.20.1.0/24" = "ap-northeast-2a"
  "10.20.2.0/24" = "ap-northeast-2c"
}

private_subnets = {
  "10.20.11.0/24" = "ap-northeast-2a"
  "10.20.12.0/24" = "ap-northeast-2c"
}
