# Tableau de bord CloudWatch : suivi de la charge et de la mise à l'échelle,
# notamment pendant le test de charge (captures pour le rapport).

module "dashboard" {
  source = "../modules/dashboard"

  name                    = local.name
  region                  = var.aws_region
  asg_name                = module.asg.asg_name
  cpu_target              = var.asg_cpu_target
  alb_arn_suffix          = module.alb.arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
}
