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
  description = "VPC CIDR — DB SG inbound rule (CIDR-based to avoid circular SG ref)"
}

variable "db_subnet_ids" {
  type        = list(string)
  description = "Subnets for PostgreSQL instances (one instance per subnet). Subset of data_subnet_ids."
}

variable "etcd_subnet_ids" {
  type        = list(string)
  description = "Subnets for etcd instances (all data_subnet_ids for quorum). Length must be odd (3+)."
}

variable "instance_type" {
  type        = string
  description = "PostgreSQL EC2 instance type"
}

variable "etcd_instance_type" {
  type        = string
  description = "etcd EC2 instance type (lightweight, e.g. t3.micro)"
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
  default = 5432
}

variable "data_volume_size_gb" {
  type    = number
  default = 20
}

variable "bastion_security_group_id" {
  type        = string
  default     = null
  description = "Bastion SG ID — if set, adds SSH rule from bastion to DB/etcd SGs"
}
