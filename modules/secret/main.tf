# Module secret : identifiants de la base dans AWS Secrets Manager.
# Équivalent Terraform du "Script-1" du sujet (aws secretsmanager create-secret).
#
# Le nom et le format sont imposés par le code fourni (app/config/config.js) :
#   - nom    : "Mydbsecret", lu dans la région us-east-1
#   - clés   : user, password, host, db

resource "aws_secretsmanager_secret" "db" {
  name        = var.secret_name
  description = "Identifiants de la base RDS de l'application web"

  # 0 = suppression immédiate au terraform destroy.
  # Sans cela, le nom reste réservé 7 à 30 jours et le prochain apply échoue.
  recovery_window_in_days = 0

  tags = { Name = var.secret_name }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id

  secret_string = jsonencode({
    user     = var.db_username
    password = var.db_password
    host     = var.db_host
    db       = var.db_name
  })
}
