resource "aws_security_group" "alb" {
  name        = "${var.project}-${var.env}-alb-sg"
  description = "ALB inbound: HTTP/HTTPS from internet"
  vpc_id      = var.vpc_id

  tags = {
    Name    = "${var.project}-${var.env}-alb-sg"
    Project = var.project
    Env     = var.env
  }
}

resource "aws_security_group_rule" "alb_ingress_http" {
  security_group_id = aws_security_group.alb.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_ingress_https" {
  security_group_id = aws_security_group.alb.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "alb_egress_all" {
  security_group_id = aws_security_group.alb.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group" "app" {
  name        = "${var.project}-${var.env}-app-sg"
  description = "App EC2: inbound from ALB only, SSH from internal"
  vpc_id      = var.vpc_id

  tags = {
    Name    = "${var.project}-${var.env}-app-sg"
    Project = var.project
    Env     = var.env
  }
}

resource "aws_security_group_rule" "app_ingress_alb" {
  security_group_id        = aws_security_group.app.id
  type                     = "ingress"
  from_port                = var.app_port
  to_port                  = var.app_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "app_ingress_ssh" {
  security_group_id = aws_security_group.app.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [var.ssh_allowed_cidr]
}

resource "aws_security_group_rule" "app_ingress_ssh_bastion" {
  count                    = var.bastion_security_group_id != null ? 1 : 0
  security_group_id        = aws_security_group.app.id
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = var.bastion_security_group_id
  description              = "SSH via Bastion"
}

resource "aws_security_group_rule" "app_egress_all" {
  security_group_id = aws_security_group.app.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_lb" "main" {
  name               = "${var.project}-${var.env}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  tags = {
    Name    = "${var.project}-${var.env}-alb"
    Project = var.project
    Env     = var.env
  }
}

resource "aws_lb_target_group" "app" {
  name     = "${var.project}-${var.env}-tg"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
  }

  tags = {
    Name    = "${var.project}-${var.env}-tg"
    Project = var.project
    Env     = var.env
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_instance" "app" {
  count                  = var.instance_count
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name               = var.key_name

  root_block_device {
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name    = "${var.project}-${var.env}-app-${count.index + 1}"
    Project = var.project
    Env     = var.env
  }
}

resource "aws_lb_target_group_attachment" "app" {
  count            = var.instance_count
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app[count.index].id
  port             = var.app_port
}