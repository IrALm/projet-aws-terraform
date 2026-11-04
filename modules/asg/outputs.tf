output "asg_name" {
  description = "Nom du groupe Auto Scaling"
  value       = aws_autoscaling_group.this.name
}

output "launch_template_id" {
  description = "ID du modèle de lancement"
  value       = aws_launch_template.this.id
}

output "launch_template_version" {
  description = "Dernière version du modèle de lancement"
  value       = aws_launch_template.this.latest_version
}

output "ami_id" {
  description = "AMI Ubuntu utilisée"
  value       = data.aws_ami.ubuntu.id
}
