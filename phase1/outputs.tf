# IP publique de la VM : utile pour la connexion SSH
output "public_ip" {
  description = "Adresse IP publique de la VM"
  value       = aws_instance.app.public_ip
}

# URL à ouvrir dans le navigateur pour tester l'application
output "application_url" {
  description = "URL de l application web (a ouvrir après le premier demarrage)"
  value       = "http://${aws_instance.app.public_ip}"
}

# Commande prête à copier pour se connecter en SSH
output "ssh_command" {
  description = "Commande pour se connecter a la VM en SSH"
  value       = "ssh -i ${replace(var.ssh_public_key_path, ".pub", "")} ubuntu@${aws_instance.app.public_ip}"
}

output "vpc_id" {
  description = "Identifiant du VPC cree"
  value       = aws_vpc.main.id
}

output "instance_id" {
  description = "Identifiant de l'instance EC2"
  value       = aws_instance.app.id
}