output "alb_dns_name" {
  value       = module.compute.alb_dns_name
  description = "ALB DNS — 이 주소로 서비스 접근"
}

output "app_instance_ids" {
  value = module.compute.app_instance_ids
}

output "db_private_ip" {
  value = module.database.db_private_ip
}
