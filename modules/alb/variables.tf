variable "name" {
  description = "Préfixe des noms de ressources (28 caractères max : AWS limite le nom de l'ALB à 32)"
  type        = string

  validation {
    condition     = length(var.name) <= 28
    error_message = "Le nom de l'ALB et du target group est limité à 32 caractères par AWS."
  }
}

variable "vpc_id" {
  description = "ID du VPC"
  type        = string
}

variable "subnet_ids" {
  description = "Sous-réseaux publics de l'ALB (au moins 2 zones)"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "Un ALB exige des sous-réseaux dans au moins 2 zones."
  }
}

variable "security_group_ids" {
  description = "Security groups de l'ALB"
  type        = list(string)
}

variable "app_port" {
  description = "Port de l'application sur les instances"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Chemin testé par le health check"
  type        = string
  default     = "/"
}
