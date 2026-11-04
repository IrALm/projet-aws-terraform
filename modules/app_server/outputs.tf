output "instance_id" {
  description = "ID de l'instance"
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "IP publique de l'instance"
  value       = aws_instance.this.public_ip
}

output "private_ip" {
  description = "IP privée de l'instance"
  value       = aws_instance.this.private_ip
}

output "ami_id" {
  description = "AMI Ubuntu utilisée"
  value       = data.aws_ami.ubuntu.id
}
