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
  description = "key = CIDR, value = AZ (e.g. {\"10.0.1.0/24\" = \"ap-northeast-2a\"})"
}

variable "private_subnets" {
  type        = map(string)
  description = "key = CIDR, value = AZ (e.g. {\"10.0.11.0/24\" = \"ap-northeast-2a\"})"
}
