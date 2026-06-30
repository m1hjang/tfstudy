variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR — DB SG 인바운드 룰에 사용 (app SG 대신 CIDR 기반)"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "DB 인스턴스를 배치할 private subnet ID 목록 (서브넷당 DB 1개, etcd 1개)"
}

variable "etcd_extra_subnet_id" {
  type        = string
  description = "홀수 쿼럼용 추가 etcd 인스턴스를 배치할 서브넷 ID"
}

variable "instance_type" {
  type        = string
  description = "DB EC2 인스턴스 타입"
}

variable "etcd_instance_type" {
  type        = string
  description = "etcd EC2 인스턴스 타입 (경량 권장, 예: t3.micro)"
}

variable "ami_id" {
  type = string
}

variable "key_name" {
  type    = string
  default = null
}

variable "db_port" {
  type    = number
  default = 3306
}

variable "data_volume_size_gb" {
  type    = number
  default = 1
}

variable "bastion_security_group_id" {
  type        = string
  default     = null
  description = "Bastion SG ID — 제공 시 Bastion → DB/etcd SSH 룰(SG 기반)을 추가"
}
