variable "name" {
  description = "Préfixe des noms de ressources"
  type        = string
}

variable "vpc_id" {
  description = "ID du VPC dans lequel créer les security groups"
  type        = string
}

variable "app_port" {
  description = "Port HTTP exposé par l'application"
  type        = number
  default     = 80
}

variable "enable_alb" {
  description = "Crée le SG de l'équilibreur et restreint le HTTP des serveurs web à l'ALB"
  type        = bool
  default     = false
}

variable "ssh_allowed_cidr" {
  description = "IP autorisée en SSH, au format x.x.x.x/32"
  type        = string

  validation {
    condition     = can(cidrhost(var.ssh_allowed_cidr, 0)) && endswith(var.ssh_allowed_cidr, "/32")
    error_message = "ssh_allowed_cidr doit être une IP unique au format x.x.x.x/32 (sans espace)."
  }
}
