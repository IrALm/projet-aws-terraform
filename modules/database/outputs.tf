output "address" {
  description = "Nom DNS du endpoint RDS (sans le port)"
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Port MySQL"
  value       = aws_db_instance.this.port
}

output "db_name" {
  description = "Nom de la base"
  value       = aws_db_instance.this.db_name
}

output "username" {
  description = "Utilisateur administrateur"
  value       = aws_db_instance.this.username
}

output "password" {
  description = "Mot de passe administrateur (transmis uniquement au module secret)"
  value       = random_password.master.result
  sensitive   = true
}

output "identifier" {
  description = "Identifiant de l'instance RDS"
  value       = aws_db_instance.this.identifier
}
