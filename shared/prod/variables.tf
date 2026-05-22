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
  description = "key = CIDR, value = AZ"
}

variable "bastion_ami_id" {
  type        = string
  description = "Bastion EC2 AMI ID"
}

variable "bastion_key_name" {
  type        = string
  description = "Bastion EC2 Key Pair 이름"
}

variable "bastion_ssh_allowed_cidr" {
  type    = string
  default = "0.0.0.0/0"
}

variable "ansible_repo_url" {
  type    = string
  default = ""
}
