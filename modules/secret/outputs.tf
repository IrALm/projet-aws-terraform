output "name" {
  description = "Nom du secret"
  value       = aws_secretsmanager_secret.db.name
}

output "arn" {
  description = "ARN du secret"
  value       = aws_secretsmanager_secret.db.arn
}

output "version_id" {
  description = "Version du secret (permet d'ordonner la création des serveurs après le secret)"
  value       = aws_secretsmanager_secret_version.db.version_id
}
