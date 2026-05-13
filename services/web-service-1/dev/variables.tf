variable "aws_region" {
  type    = string
  default = "ap-northeast-2"
}

variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "ami_id" {
  type        = string
  description = "EC2 AMI ID (app/db 동일 AMI 사용)"
}

variable "key_name" {
  type        = string
  description = "EC2 Key Pair 이름"
}

variable "app_instance_type" {
  type = string
}

variable "app_instance_count" {
  type    = number
  default = 1
}

variable "app_port" {
  type    = number
  default = 8080
}

variable "db_instance_type" {
  type = string
}

variable "db_port" {
  type    = number
  default = 5432
}

variable "db_volume_size_gb" {
  type    = number
  default = 50
}
