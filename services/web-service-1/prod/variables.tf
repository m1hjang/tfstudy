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
