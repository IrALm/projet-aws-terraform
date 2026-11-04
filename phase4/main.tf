# Phase 4 : application conteneurisée.
# Même architecture que la phase 3 (ALB + Auto Scaling + RDS + Secrets Manager),
# mais les instances exécutent l'image Docker publiée dans Amazon ECR au lieu
# d'installer Node.js et l'application au démarrage.
#
# Prérequis : le registre (phase4/registry) existe et contient l'image (scripts/build-push.sh).

locals {
  name      = "${var.project_name}-p4"
  image_uri = "${data.aws_ecr_repository.app.repository_url}:${var.image_tag}"
}

# Registre créé par la configuration phase4/registry. Si le dépôt n'existe pas,
# le plan échoue immédiatement avec un message explicite (au lieu d'instances en échec).
data "aws_ecr_repository" "app" {
  name = var.repository_name
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
  enable_alb       = true
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

  # Script de démarrage : installe Docker et lance l'image ECR
  user_data = templatefile("${path.module}/scripts/user-data.sh.tftpl", {
    image_uri = local.image_uri
    host_port = 80
  })
  # Le conteneur doit pouvoir joindre IMDS (pont Docker = 1 saut de plus)
  metadata_hop_limit = 2

  min_size         = var.asg_min_size
  max_size         = var.asg_max_size
  desired_capacity = var.asg_desired_capacity
  cpu_target       = var.asg_cpu_target

  depends_on_ids = [module.secret.version_id]
}
