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
  default     = null
  description = "EC2 Key Pair name"
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
  default = 20
}

variable "etcd_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "data_subnet_cidrs" {
  type        = list(string)
  description = "CIDRs of private subnets used as data tier (PostgreSQL + etcd). Last CIDR is etcd-only quorum node."
}

variable "app_subnet_cidrs" {
  type        = list(string)
  description = "CIDRs of app tier subnets — used to open NACL inbound to PostgreSQL port."
}

variable "ACCESS_KEY" {
  type = string
}

variable "SECRET_KEY" {
  type = string
}
