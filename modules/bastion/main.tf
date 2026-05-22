resource "aws_security_group" "bastion" {
  name        = "${var.project}-${var.env}-bastion-sg"
  description = "Bastion: SSH from allowed CIDR"
  vpc_id      = var.vpc_id

  tags = {
    Name    = "${var.project}-${var.env}-bastion-sg"
    Project = var.project
    Env     = var.env
  }
}

resource "aws_security_group_rule" "bastion_ingress_ssh" {
  security_group_id = aws_security_group.bastion.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.ssh_allowed_cidr]
  description       = "SSH from allowed CIDR - restrict to your IP/32 in production"
}

resource "aws_security_group_rule" "bastion_egress_all" {
  security_group_id = aws_security_group.bastion.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_instance" "bastion" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  # 부팅 시 Ansible 설치 + 플레이북 레포 자동 클론
  user_data = <<-USERDATA
#!/bin/bash
yum update -y
yum install -y git
%{~ if var.ansible_repo_url != "" }
sudo -u ec2-user git clone ${var.ansible_repo_url} /home/ec2-user/playbooks
chown -R ec2-user:ec2-user /home/ec2-user/playbooks
%{ endif ~}
echo "Bastion ansible control node setup complete" >> /var/log/user-data.log
  USERDATA

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  tags = {
    Name    = "${var.project}-${var.env}-bastion"
    Project = var.project
    Env     = var.env
    Role    = "bastion"
  }
}
