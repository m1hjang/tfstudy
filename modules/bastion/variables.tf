variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "vpc_id" {
  type        = string
  description = "Bastion을 배치할 VPC ID"
}

variable "subnet_id" {
  type        = string
  description = "Bastion을 배치할 퍼블릭 서브넷 ID"
}

variable "ami_id" {
  type        = string
  description = "Bastion EC2 AMI ID"
}

variable "instance_type" {
  type        = string
  default     = "t3.micro"
  description = "Bastion EC2 인스턴스 타입"
}

variable "key_name" {
  type        = string
  description = "Bastion EC2 Key Pair 이름"
}

variable "ssh_allowed_cidr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "Bastion SSH 허용 CIDR — 운영 시 본인 IP/32 로 제한 권장"
}

variable "ansible_repo_url" {
  type        = string
  default     = ""
  description = "부팅 시 클론할 Ansible 플레이북 Git URL (공백이면 클론 생략)"
}
