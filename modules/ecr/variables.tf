variable "name" {
  description = "Nom du dépôt ECR"
  type        = string
}

variable "max_images" {
  description = "Nombre d'images conservées"
  type        = number
  default     = 10
}

variable "force_delete" {
  description = "Autorise la suppression du dépôt même s'il contient des images"
  type        = bool
  default     = true
}
