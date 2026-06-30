output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_cidr" {
  value = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  value = values(aws_subnet.public)[*].id
}

output "private_subnet_ids" {
  value       = { for cidr, s in aws_subnet.private : cidr => s.id }
  description = "CIDR -> private subnet ID map. Consuming modules filter by their own CIDR lists."
}

output "private_subnet_azs" {
  value       = { for cidr, az in var.private_subnets : cidr => az }
  description = "CIDR -> AZ map for private subnets."
}

output "nat_route_table_ids" {
  value       = { for cidr, rt in aws_route_table.nat : var.public_subnets[cidr] => rt.id }
  description = "AZ -> NAT route table ID. Consuming modules create RTAs to enable outbound internet for their subnets."
}
