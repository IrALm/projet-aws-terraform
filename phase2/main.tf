# Phase 2 : découplage de l'application (EC2) et de la base de données (RDS MySQL).
#
# Ordre de création (géré automatiquement par les dépendances) :
#   réseau -> security groups -> RDS -> secret (contient l'endpoint RDS) -> serveur web

locals {
  name = "${var.project_name}-p2"
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

module "app_server" {
  source = "../modules/app_server"

  name                 = local.name
  subnet_id            = module.network.public_subnet_ids[0]
  security_group_ids   = [module.security.web_sg_id]
  instance_type        = var.instance_type
  ssh_public_key_path  = var.ssh_public_key_path
  iam_instance_profile = var.iam_instance_profile
  user_data_path       = "${path.module}/scripts/app-server-userdata.sh"

  # Le secret doit exister avant le premier démarrage de l'application
  depends_on_ids = [module.secret.version_id]
}
