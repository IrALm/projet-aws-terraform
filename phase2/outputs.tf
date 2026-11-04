output "application_url" {
  description = "URL de l'application web"
  value       = "http://${module.app_server.public_ip}"
}

output "public_ip" {
  description = "IP publique du serveur web"
  value       = module.app_server.public_ip
}

output "ssh_command" {
  description = "Commande de connexion SSH au serveur web"
  value       = "ssh -i ${trimsuffix(var.ssh_public_key_path, ".pub")} ubuntu@${module.app_server.public_ip}"
}

output "instance_id" {
  description = "ID de l'instance EC2"
  value       = module.app_server.instance_id
}

output "vpc_id" {
  description = "ID du VPC"
  value       = module.network.vpc_id
}

output "rds_endpoint" {
  description = "Endpoint privé de la base RDS (non joignable depuis Internet)"
  value       = module.database.address
}

output "rds_identifier" {
  description = "Identifiant de l'instance RDS"
  value       = module.database.identifier
}

output "db_name" {
  description = "Nom de la base"
  value       = module.database.db_name
}

output "db_username" {
  description = "Utilisateur de la base"
  value       = module.database.username
}

output "secret_name" {
  description = "Nom du secret Secrets Manager contenant les identifiants"
  value       = module.secret.name
}

output "aws_region" {
  description = "Région de déploiement"
  value       = var.aws_region
}
