output "web_sg_id" {
  description = "ID du security group des serveurs web"
  value       = aws_security_group.web.id
}

output "db_sg_id" {
  description = "ID du security group de la base de données"
  value       = aws_security_group.db.id
}
