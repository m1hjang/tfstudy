# ── Bastion: module.network → module.bastion 이전 ────────────────────────────
#
# modules/bastion/ 분리로 인해 리소스 주소가 변경됨.
# 이 블록이 없으면 Terraform이 module.network 의 bastion 리소스를 삭제하고
# module.bastion 에 새로 생성하려 시도함 → EC2 재생성, SG 재생성, 서비스 중단.
#
# moved 블록은 "같은 물리 리소스를 다른 주소로 인식하라"고 Terraform에 알려줌.
# apply 후에도 파일을 남겨두면 no-op이므로 제거하지 않아도 됨.

moved {
  from = module.network.aws_instance.bastion
  to   = module.bastion.aws_instance.bastion
}

moved {
  from = module.network.aws_security_group.bastion
  to   = module.bastion.aws_security_group.bastion
}

moved {
  from = module.network.aws_security_group_rule.bastion_ingress_ssh
  to   = module.bastion.aws_security_group_rule.bastion_ingress_ssh
}

moved {
  from = module.network.aws_security_group_rule.bastion_egress_all
  to   = module.bastion.aws_security_group_rule.bastion_egress_all
}
