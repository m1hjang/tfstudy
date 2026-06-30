output "db_private_ips" {
  value       = module.database.db_private_ips
  description = "index -> PostgreSQL instance private IP map"
}

output "db_instance_ids" {
  value = module.database.db_instance_ids
}

output "db_security_group_id" {
  value = module.database.db_security_group_id
}

output "etcd_private_ips" {
  value       = module.database.etcd_private_ips
  description = "index -> etcd instance private IP map"
}

output "etcd_security_group_id" {
  value = module.database.etcd_security_group_id
}
