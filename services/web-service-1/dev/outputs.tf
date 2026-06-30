output "bastion_public_ip" {
  value       = data.terraform_remote_state.shared.outputs.bastion_public_ip
  description = "Bastion Public IP (shared 레이어에서 참조)"
}

output "alb_dns_name" {
  value       = module.compute.alb_dns_name
  description = "ALB DNS — 앱 접근 주소"
}

output "app_instance_ids" {
  value = module.compute.app_instance_ids
}

output "db_private_ips" {
  value       = data.terraform_remote_state.db.outputs.db_private_ips
  description = "DB 인스턴스 private IP 맵 (db-service-1 레이어에서 참조)"
}

output "etcd_private_ips" {
  value       = data.terraform_remote_state.db.outputs.etcd_private_ips
  description = "etcd 인스턴스 private IP 맵 (db-service-1 레이어에서 참조)"
}
