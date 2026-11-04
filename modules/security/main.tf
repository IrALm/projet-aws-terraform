# Module sécurité : un security group par couche (web, base de données).
# Principe du moindre privilège : chaque couche n'accepte que le port dont elle a besoin,
# et la base n'accepte que le trafic provenant du security group web (pas d'IP).
# Note : AWS refuse les accents et apostrophes dans les descriptions (ASCII uniquement).

# ---------- Couche web ----------
resource "aws_security_group" "web" {
  name        = "${var.name}-web-sg"
  description = "Serveur web: HTTP public, SSH admin"
  vpc_id      = var.vpc_id

  tags = { Name = "${var.name}-web-sg" }
}

resource "aws_vpc_security_group_ingress_rule" "web_http" {
  security_group_id = aws_security_group.web.id
  description       = "HTTP depuis Internet"
  ip_protocol       = "tcp"
  from_port         = var.app_port
  to_port           = var.app_port
  cidr_ipv4         = "0.0.0.0/0"
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
