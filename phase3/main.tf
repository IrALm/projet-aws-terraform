# Phase 3 : haute disponibilité et mise à l'échelle.
# Reprend les modules de la phase 2 (réseau, sécurité, base, secret) et remplace
# le serveur web unique par un Application Load Balancer + un groupe Auto Scaling.
#
# Ordre de création (géré automatiquement par les dépendances) :
#   réseau -> security groups -> ALB  ─┐
#                             -> RDS -> secret -> groupe Auto Scaling (instances)

locals {
  name = "${var.project_name}-p3"
}

module "network" {
  source = "../modules/network"

  name                 = local.name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "security" {
  source = "../modules/security"

  name             = local.name
  vpc_id           = module.network.vpc_id
  ssh_allowed_cidr = var.ssh_allowed_cidr
  enable_alb       = true # HTTP des instances accepté uniquement depuis l'ALB
}

module "database" {
  source = "../modules/database"

  name               = local.name
  subnet_ids         = module.network.private_subnet_ids
  security_group_ids = [module.security.db_sg_id]
  engine_version     = var.db_engine_version
  instance_class     = var.db_instance_class
}

module "secret" {
  source = "../modules/secret"

  db_username = module.database.username
  db_password = module.database.password
  db_host     = module.database.address
  db_name     = module.database.db_name
}

module "alb" {
  source = "../modules/alb"

  name               = local.name
  vpc_id             = module.network.vpc_id
  subnet_ids         = module.network.public_subnet_ids
  security_group_ids = [module.security.alb_sg_id]
}

module "asg" {
  source = "../modules/asg"

  name                 = local.name
  subnet_ids           = module.network.public_subnet_ids
  security_group_ids   = [module.security.web_sg_id]
  target_group_arns    = [module.alb.target_group_arn]
  instance_type        = var.instance_type
  ssh_public_key_path  = var.ssh_public_key_path
  iam_instance_profile = var.iam_instance_profile
  user_data_path       = "${path.module}/scripts/app-server-userdata.sh"

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity
  cpu_target       = var.asg_cpu_target

  # Le secret doit exister avant le démarrage des instances
  depends_on_ids = [module.secret.version_id]
}
