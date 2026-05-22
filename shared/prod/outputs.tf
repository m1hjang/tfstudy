output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.network.private_subnet_ids
}

output "vpc_cidr" {
  value = module.network.vpc_cidr
}

output "bastion_public_ip" {
  value       = module.bastion.public_ip
  description = "Bastion Public IP — SSH 진입점 (ssh -A ec2-user@<IP>)"
}

output "bastion_security_group_id" {
  value       = module.bastion.security_group_id
  description = "Bastion SG ID — 서비스 모듈의 app/db SSH 룰에 전달"
}
