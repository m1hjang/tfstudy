project  = "tfstudy-web-infra"
env      = "dev"
vpc_cidr = "10.10.0.0/16"

# ── Bastion (Ansible 컨트롤 노드) ─────────────────────────────────────────────
bastion_ami_id           = "ami-035f4c601044a7af4"
bastion_key_name         = "seoul-ed25519"
bastion_ssh_allowed_cidr = "0.0.0.0/0"   # 운영 시 본인 IP/32 로 제한
ansible_repo_url         = "https://github.com/m1hjang/dvwa-ansible.git"

public_subnets = {
  "10.10.1.0/24" = "ap-northeast-2a"
  "10.10.2.0/24" = "ap-northeast-2c"
}

private_subnets = {
  "10.10.11.0/24" = "ap-northeast-2a"
  "10.10.12.0/24" = "ap-northeast-2c"
}
