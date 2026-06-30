output "db_instance_ids" {
  value       = { for k, inst in aws_instance.db : k => inst.id }
  description = "index → DB 인스턴스 ID 맵"
}

output "db_private_ips" {
  value       = { for k, inst in aws_instance.db : k => inst.private_ip }
  description = "index → DB 인스턴스 private IP 맵"
}

output "db_security_group_id" {
  value = aws_security_group.db.id
}

output "etcd_instance_ids" {
  value       = { for k, inst in aws_instance.etcd : k => inst.id }
  description = "index → etcd 인스턴스 ID 맵"
}

output "etcd_private_ips" {
  value       = { for k, inst in aws_instance.etcd : k => inst.private_ip }
  description = "index → etcd 인스턴스 private IP 맵"
}

output "etcd_security_group_id" {
  value = aws_security_group.etcd.id
}
