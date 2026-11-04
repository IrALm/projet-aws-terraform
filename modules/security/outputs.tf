output "web_sg_id" {
  description = "ID du security group des serveurs web"
  value       = aws_security_group.web.id
}

output "alb_sg_id" {
  description = "ID du security group de l'équilibreur (null si enable_alb = false)"
  value       = var.enable_alb ? aws_security_group.alb[0].id : null
}

output "db_sg_id" {
  description = "ID du security group de la base de données"
  value       = aws_security_group.db.id
}
