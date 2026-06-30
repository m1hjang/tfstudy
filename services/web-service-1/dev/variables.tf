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

variable "app_subnet_cidrs" {
  type        = list(string)
  description = "CIDRs of private subnets used as app tier. These subnets get RTAs to NAT GW for outbound internet."
}

variable "ACCESS_KEY" {
  type = string
}

variable "SECRET_KEY" {
  type = string
}
