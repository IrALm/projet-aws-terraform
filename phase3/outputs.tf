output "application_url" {
  description = "URL de l'application (via l'équilibreur de charge)"
  value       = "http://${module.alb.dns_name}"
}

output "alb_dns_name" {
  description = "Nom DNS de l'équilibreur de charge"
  value       = module.alb.dns_name
}

output "asg_name" {
  description = "Nom du groupe Auto Scaling"
  value       = module.asg.asg_name
}

output "target_group_arn" {
  description = "ARN du target group"
  value       = module.alb.target_group_arn
}

output "launch_template_id" {
  description = "ID du modèle de lancement"
  value       = module.asg.launch_template_id
}

output "dashboard_url" {
  description = "Tableau de bord CloudWatch (à ouvrir depuis la console du lab)"
  value       = module.dashboard.dashboard_url
}

output "vpc_id" {
  description = "ID du VPC"
  value       = module.network.vpc_id
}

output "rds_endpoint" {
  description = "Endpoint privé de la base RDS"
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

output "secret_name" {
  description = "Nom du secret Secrets Manager"
  value       = module.secret.name
}

output "aws_region" {
  description = "Région de déploiement"
  value       = var.aws_region
}
