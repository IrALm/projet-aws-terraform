# Pare-feu de la VM : seuls les ports nécessaires sont ouverts
resource "aws_security_group" "app" {
  name        = "${var.project_name}-app-sg"
  description = "HTTP public, SSH restreint, MySQL non expose"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-app-sg"
  }
}

# HTTP (80) ouvert à tout Internet : c'est le port de l'application
resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.app.id
  description       = "HTTP public vers l application"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

# SSH (22) limité à votre IP uniquement
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.app.id
  description       = "SSH depuis mon IP uniquement"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = var.ssh_allowed_cidr
}

# Aucune règle pour le port 3306 (MySQL) : la base n'est pas joignable depuis Internet.
# Le script installe MySQL sur la même VM, donc l'application s'y connecte en local.

# Sortie libre : nécessaire pour apt, npm et le téléchargement de code.zip
resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.app.id
  description       = "Trafic sortant autorise"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}