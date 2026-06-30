output "vpc_id" {
  value = module.network.vpc_id
}

output "vpc_cidr" {
  value = module.network.vpc_cidr
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  value       = module.network.private_subnet_ids
  description = "CIDR -> private subnet ID map"
}

output "private_subnet_azs" {
  value       = module.network.private_subnet_azs
  description = "CIDR -> AZ map for private subnets"
}

output "nat_route_table_ids" {
  value       = module.network.nat_route_table_ids
  description = "AZ -> NAT route table ID"
}

output "bastion_public_ip" {
  value       = module.bastion.public_ip
  description = "Bastion Public IP — SSH entry point"
}

output "bastion_security_group_id" {
  value       = module.bastion.security_group_id
  description = "Bastion SG ID — app/db SSH rules reference this"
}
