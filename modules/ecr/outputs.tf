output "repository_url" {
  description = "URL du dépôt (<compte>.dkr.ecr.<région>.amazonaws.com/<nom>)"
  value       = aws_ecr_repository.this.repository_url
}

output "repository_name" {
  description = "Nom du dépôt"
  value       = aws_ecr_repository.this.name
}

output "registry_id" {
  description = "ID du registre (numéro de compte AWS)"
  value       = aws_ecr_repository.this.registry_id
}
