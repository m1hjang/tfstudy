output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = values(aws_subnet.public)[*].id
}

output "private_subnet_ids" {
  value = values(aws_subnet.private)[*].id
}

output "vpc_cidr" {
  value = aws_vpc.main.cidr_block
}

output "private_route_table_ids" {
  value       = { for cidr, rt in aws_route_table.private : var.private_subnets[cidr] => rt.id }
  description = "AZ → private route table ID 맵 (DB 루트 모듈에서 etcd 전용 서브넷 연결에 사용)"
}
