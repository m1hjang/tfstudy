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
  description = "key = CIDR, value = AZ. Public subnets where NAT GWs are placed."
}

variable "private_subnets" {
  type        = map(string)
  description = "key = CIDR, value = AZ. All private subnets. Workload assignment is the consuming module's responsibility."
}
