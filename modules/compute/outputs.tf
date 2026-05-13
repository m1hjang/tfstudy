output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "alb_arn" {
  value = aws_lb.main.arn
}

output "app_instance_ids" {
  value = aws_instance.app[*].id
}

output "app_security_group_id" {
  value = aws_security_group.app.id
}
