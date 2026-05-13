variable "project" {
  type = string
}

variable "env" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
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

variable "app_port" {
  type    = number
  default = 8080
}

variable "instance_count" {
  type    = number
  default = 1
}

# SSH 접근 허용 CIDR (기본값은 VPC 내부만)
variable "ssh_allowed_cidr" {
  type    = string
  default = "10.0.0.0/8"
}
