output "dashboard_name" {
  description = "Nom du tableau de bord"
  value       = aws_cloudwatch_dashboard.this.dashboard_name
}

output "dashboard_url" {
  description = "URL du tableau de bord dans la console AWS"
  value       = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards/dashboard/${aws_cloudwatch_dashboard.this.dashboard_name}"
}
