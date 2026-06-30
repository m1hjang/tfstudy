locals {
  db_subnet_map   = { for idx, id in var.db_subnet_ids : tostring(idx) => id }
  etcd_subnet_map = { for idx, id in var.etcd_subnet_ids : tostring(idx) => id }
}

# ── DB Security Group ─────────────────────────────────────────────────────────

resource "aws_security_group" "db" {
  name        = "${var.project}-${var.env}-db-sg"
  description = "DB EC2: inbound from VPC CIDR on db_port, SSH from bastion"
  vpc_id      = var.vpc_id

  tags = {
    Name    = "${var.project}-${var.env}-db-sg"
    Project = var.project
    Env     = var.env
  }
}

resource "aws_security_group_rule" "db_ingress_app_cidr" {
  security_group_id = aws_security_group.db.id
  type              = "ingress"
  from_port         = var.db_port
  to_port           = var.db_port
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr]
  description       = "DB inbound from VPC CIDR (avoid circular SG ref)"
}

resource "aws_security_group_rule" "db_ingress_ssh_bastion" {
  count                    = var.bastion_security_group_id != null ? 1 : 0
  security_group_id        = aws_security_group.db.id
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = var.bastion_security_group_id
  description              = "SSH via Bastion (DB)"
}

resource "aws_security_group_rule" "db_egress_all" {
  security_group_id = aws_security_group.db.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# ── etcd Security Group ───────────────────────────────────────────────────────

resource "aws_security_group" "etcd" {
  name        = "${var.project}-${var.env}-etcd-sg"
  description = "etcd cluster: peer 2380, client 2379 from DB SG and self"
  vpc_id      = var.vpc_id

  tags = {
    Name    = "${var.project}-${var.env}-etcd-sg"
    Project = var.project
    Env     = var.env
  }
}

resource "aws_security_group_rule" "etcd_ingress_client_from_db" {
  security_group_id        = aws_security_group.etcd.id
  type                     = "ingress"
  from_port                = 2379
  to_port                  = 2379
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.db.id
  description              = "etcd client: from DB instances"
}

resource "aws_security_group_rule" "etcd_ingress_client_self" {
  security_group_id = aws_security_group.etcd.id
  type              = "ingress"
  from_port         = 2379
  to_port           = 2379
  protocol          = "tcp"
  self              = true
  description       = "etcd client: intra-cluster"
}

resource "aws_security_group_rule" "etcd_ingress_peer" {
  security_group_id = aws_security_group.etcd.id
  type              = "ingress"
  from_port         = 2380
  to_port           = 2380
  protocol          = "tcp"
  self              = true
  description       = "etcd peer: inter-node replication"
}

resource "aws_security_group_rule" "etcd_ingress_ssh_bastion" {
  count                    = var.bastion_security_group_id != null ? 1 : 0
  security_group_id        = aws_security_group.etcd.id
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = var.bastion_security_group_id
  description              = "SSH via Bastion (etcd)"
}

resource "aws_security_group_rule" "etcd_egress_all" {
  security_group_id = aws_security_group.etcd.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

# ── DB Instances (private subnet당 1개) ───────────────────────────────────────

resource "aws_instance" "db" {
  for_each               = local.db_subnet_map
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = each.value
  vpc_security_group_ids = [aws_security_group.db.id]
  key_name               = var.key_name

  root_block_device {
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name    = "${var.project}-${var.env}-db-${each.key}"
    Project = var.project
    Env     = var.env
    Role    = "db"
  }
}

# ── etcd Instances (DB 서브넷 동일 배치 + 쿼럼용 추가 1개) ───────────────────

resource "aws_instance" "etcd" {
  for_each               = local.etcd_subnet_map
  ami                    = var.ami_id
  instance_type          = var.etcd_instance_type
  subnet_id              = each.value
  vpc_security_group_ids = [aws_security_group.etcd.id]
  key_name               = var.key_name

  root_block_device {
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name    = "${var.project}-${var.env}-etcd-${each.key}"
    Project = var.project
    Env     = var.env
    Role    = "etcd"
  }
}
