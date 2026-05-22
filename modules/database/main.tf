resource "aws_security_group" "db" {
  name        = "${var.project}-${var.env}-db-sg"
  description = "DB EC2: inbound from app SG only"
  vpc_id      = var.vpc_id

  tags = {
    Name    = "${var.project}-${var.env}-db-sg"
    Project = var.project
    Env     = var.env
  }
}

resource "aws_security_group_rule" "db_ingress_app" {
  security_group_id        = aws_security_group.db.id
  type                     = "ingress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = var.app_security_group_id
}

resource "aws_security_group_rule" "db_ingress_ssh" {
  security_group_id = aws_security_group.db.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.ssh_allowed_cidr]
}

resource "aws_security_group_rule" "db_ingress_ssh_bastion" {
  count                    = var.bastion_security_group_id != null ? 1 : 0
  security_group_id        = aws_security_group.db.id
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = var.bastion_security_group_id
  description              = "SSH via Bastion"
}

resource "aws_security_group_rule" "db_egress_all" {
  security_group_id = aws_security_group.db.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_instance" "db" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.db.id]
  key_name               = var.key_name

  root_block_device {
    volume_type = "gp3"
    encrypted   = true
  }

/* 추가 볼륨은 아직...
  ebs_block_device {
    device_name = "/dev/sdb"
    volume_type = "gp3"
    volume_size = var.data_volume_size_gb
    encrypted   = true
    delete_on_termination = false
  }
 */  
 tags = {
    Name    = "${var.project}-${var.env}-db"
    Project = var.project
    Env     = var.env
  }
}
