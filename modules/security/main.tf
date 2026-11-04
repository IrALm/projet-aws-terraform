# Module sécurité : un security group par couche (équilibreur, web, base de données).
# Principe du moindre privilège : chaque couche n'accepte que le port dont elle a besoin,
# et uniquement depuis la couche précédente (références de security groups, pas d'IP) :
#   Internet -> [SG alb :80] -> [SG web :80] -> [SG db :3306]
# Sans équilibreur (enable_alb = false, phase 2) : Internet -> [SG web :80] -> [SG db :3306]
# Note : AWS refuse les accents et apostrophes dans les descriptions (ASCII uniquement).

# ---------- Couche équilibreur de charge (phase 3) ----------
resource "aws_security_group" "alb" {
  count = var.enable_alb ? 1 : 0

  name        = "${var.name}-alb-sg"
  description = "ALB: HTTP public"
  vpc_id      = var.vpc_id

  tags = { Name = "${var.name}-alb-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  count = var.enable_alb ? 1 : 0

  security_group_id = aws_security_group.alb[0].id
  description       = "HTTP depuis Internet"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

# L'ALB ne peut sortir que vers les serveurs web, sur le port de l'application
resource "aws_vpc_security_group_egress_rule" "alb_to_web" {
  count = var.enable_alb ? 1 : 0

  security_group_id            = aws_security_group.alb[0].id
  description                  = "Vers les serveurs web"
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
  referenced_security_group_id = aws_security_group.web.id
}

# ---------- Couche web ----------
resource "aws_security_group" "web" {
  name        = "${var.name}-web-sg"
  description = var.enable_alb ? "Serveur web: HTTP depuis ALB, SSH admin" : "Serveur web: HTTP public, SSH admin"
  vpc_id      = var.vpc_id

  tags = { Name = "${var.name}-web-sg" }
}

# Avec ALB : HTTP accepté uniquement depuis l'ALB (les instances ne sont pas
# joignables directement en HTTP depuis Internet). Sans ALB : HTTP public.
resource "aws_vpc_security_group_ingress_rule" "web_http" {
  security_group_id            = aws_security_group.web.id
  description                  = var.enable_alb ? "HTTP depuis ALB uniquement" : "HTTP depuis Internet"
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
  cidr_ipv4                    = var.enable_alb ? null : "0.0.0.0/0"
  referenced_security_group_id = var.enable_alb ? aws_security_group.alb[0].id : null
}

resource "aws_vpc_security_group_ingress_rule" "web_ssh" {
  security_group_id = aws_security_group.web.id
  description       = "SSH depuis IP admin uniquement"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.ssh_allowed_cidr
}

# Sortie libre : apt, npm, téléchargement du code, API Secrets Manager, connexion à RDS
resource "aws_vpc_security_group_egress_rule" "web_all" {
  security_group_id = aws_security_group.web.id
  description       = "Trafic sortant"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# ---------- Couche base de données ----------
resource "aws_security_group" "db" {
  name        = "${var.name}-db-sg"
  description = "RDS MySQL: accessible uniquement depuis le SG web"
  vpc_id      = var.vpc_id

  tags = { Name = "${var.name}-db-sg" }
}

# Seul le security group web peut joindre MySQL (référence de SG, pas de plage IP)
resource "aws_vpc_security_group_ingress_rule" "db_mysql_from_web" {
  security_group_id            = aws_security_group.db.id
  description                  = "MySQL depuis le SG web"
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
  referenced_security_group_id = aws_security_group.web.id
}

# Pas de règle de sortie pour la base : RDS n'initie aucune connexion.
