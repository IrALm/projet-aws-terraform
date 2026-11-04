output "vpc_id" {
  description = "ID du VPC"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs des sous-réseaux publics"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs des sous-réseaux privés"
  value       = aws_subnet.private[*].id
}

output "availability_zones" {
  description = "Zones de disponibilité utilisées"
  value       = local.azs
}
