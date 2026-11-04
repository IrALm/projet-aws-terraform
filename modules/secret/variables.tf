variable "secret_name" {
  description = "Nom du secret (imposé par le code de l'application)"
  type        = string
  default     = "Mydbsecret"
}

variable "db_username" {
  description = "Utilisateur de la base"
  type        = string
}

variable "db_password" {
  description = "Mot de passe de la base"
  type        = string
  sensitive   = true
}

variable "db_host" {
  description = "Nom DNS du endpoint RDS"
  type        = string
}

variable "db_name" {
  description = "Nom de la base"
  type        = string
}
