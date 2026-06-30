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

variable "vpc_cidr" {
  type = string
}

variable "public_subnets" {
  type        = map(string)
  description = "key = CIDR, value = AZ"
}

variable "private_subnets" {
  type        = map(string)
  description = "key = CIDR, value = AZ. All private subnets."
}

variable "app_subnet_cidrs" {
  type        = list(string)
  description = "CIDRs treated as app tier (for NACL inbound rules)."
}

variable "data_subnet_cidrs" {
  type        = list(string)
  description = "CIDRs treated as data tier. Last entry (sorted) is etcd-only quorum node."
}

variable "db_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "etcd_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "db_port" {
  type    = number
  default = 5432
}

variable "key_name" {
  type    = string
  default = ""
}
