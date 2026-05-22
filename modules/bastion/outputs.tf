output "public_ip" {
  value       = aws_instance.bastion.public_ip
  description = "Bastion Public IP — SSH 진입점 (ssh -A ec2-user@<IP>)"
}

output "security_group_id" {
  value       = aws_security_group.bastion.id
  description = "Bastion SG ID — 서비스 모듈의 app/db SG SSH 인바운드에 사용"
}
