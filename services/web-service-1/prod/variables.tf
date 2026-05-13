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
  type = string
}

variable "key_name" {
  type = string
}

variable "app_instance_type" {
  type = string
}

variable "app_instance_count" {
  type    = number
  default = 2
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
  default = 100
}
