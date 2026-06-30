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
