variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "app_security_group_id" {
  type        = string
  description = "App EC2 SG — DB SG allows inbound from this only"
}

variable "instance_type" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "key_name" {
  type = string
}

variable "db_port" {
  type    = number
  default = 3306
}

variable "data_volume_size_gb" {
  type    = number
  default = 1
}

variable "ssh_allowed_cidr" {
  type    = string
  default = "10.0.0.0/8"
}

variable "bastion_security_group_id" {
  type        = string
  default     = null
  description = "Bastion SG ID — 제공 시 Bastion → DB EC2 SSH 룰(SG 기반)을 추가"
}
