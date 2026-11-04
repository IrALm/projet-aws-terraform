output "dns_name" {
  description = "Nom DNS public de l'ALB (point d'entrée de l'application)"
  value       = aws_lb.this.dns_name
}

output "arn" {
  description = "ARN de l'ALB"
  value       = aws_lb.this.arn
}

output "arn_suffix" {
  description = "Suffixe d'ARN de l'ALB (utilisé par les métriques CloudWatch)"
  value       = aws_lb.this.arn_suffix
}

output "target_group_arn" {
  description = "ARN du target group"
  value       = aws_lb_target_group.this.arn
}

output "target_group_arn_suffix" {
  description = "Suffixe d'ARN du target group (utilisé par les métriques CloudWatch)"
  value       = aws_lb_target_group.this.arn_suffix
}
