# Module base de données : RDS MySQL privé, mono-AZ (hypothèse du sujet), chiffré.

# Mot de passe généré aléatoirement : il n'est écrit nulle part dans le code.
# Il est stocké dans Secrets Manager (module secret) et lu par l'application au démarrage.
# Alphanumérique uniquement : évite les caractères refusés par RDS (/ @ " espace)
# et les problèmes d'échappement dans les scripts shell.
resource "random_password" "master" {
  length  = 24
  special = false
}

# Groupe de sous-réseaux : RDS exige des sous-réseaux dans au moins 2 zones,
# même pour une instance mono-AZ (permet de passer en Multi-AZ plus tard).
resource "aws_db_subnet_group" "this" {
  name        = "${var.name}-db-subnets"
  description = "Sous-reseaux prives pour RDS"
  subnet_ids  = var.subnet_ids

  tags = { Name = "${var.name}-db-subnets" }
}

# Groupe de paramètres MySQL.
# L'application fournie ouvre une connexion par requête sans jamais la fermer (pas de end()
# ni de pool dans app/models/supplier.model.js). Avec les réglages par défaut de db.t3.micro
# (wait_timeout = 8 h, max_connections = 61), la base refuse toute connexion après ~60 pages
# affichées ("Too many connections"). Le code ne devant pas être modifié :
#   - wait_timeout   : MySQL ferme lui-même les connexions inactives après quelques secondes ;
#   - max_connections: plus de marge pour les rafales (une connexion inactive coûte < 1 Mo).
# Capacité soutenue sur les pages qui lisent la base ≈ max_connections / wait_timeout req/s.
locals {
  # "8.4" ou "8.4.11" -> "mysql8.4"
  parameter_group_family = "mysql${join(".", slice(split(".", var.engine_version), 0, 2))}"
}

resource "aws_db_parameter_group" "this" {
  name_prefix = "${var.name}-mysql-"
  family      = local.parameter_group_family
  description = "Parametres MySQL de l application (fermeture des connexions inactives)"

  parameter {
    name  = "wait_timeout"
    value = var.wait_timeout
  }

  parameter {
    name  = "max_connections"
    value = var.max_connections
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = { Name = "${var.name}-mysql-params" }
}

resource "aws_db_instance" "this" {
  identifier = "${var.name}-mysql"

  engine         = "mysql"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage # autoscaling du stockage
  storage_type          = "gp3"
  storage_encrypted     = true

  parameter_group_name = aws_db_parameter_group.this.name

  db_name  = var.db_name
  username = var.db_username
  password = random_password.master.result

  # Sécurité réseau : privée, dans les sous-réseaux privés, derrière son security group
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.security_group_ids
  publicly_accessible    = false

  # Disponibilité : mono-AZ (hypothèse du sujet, et coût divisé par 2)
  multi_az = var.multi_az

  # Sauvegardes automatiques (1 jour suffit pour un POC)
  backup_retention_period = var.backup_retention_days

  # Mises à jour mineures automatiques pendant la fenêtre de maintenance
  auto_minor_version_upgrade = true

  # POC : suppression rapide et sans snapshot final lors du terraform destroy
  skip_final_snapshot = true
  deletion_protection = false
  apply_immediately   = true

  tags = { Name = "${var.name}-mysql" }
}
