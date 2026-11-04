variable "name" {
  description = "Préfixe des noms de ressources"
  type        = string
}

variable "vpc_cidr" {
  description = "Plage d'adresses du VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "Plages des sous-réseaux publics (une par zone de disponibilité)"
  type        = list(string)

  validation {
    condition     = length(var.public_subnet_cidrs) >= 1
    error_message = "Au moins un sous-réseau public est requis."
  }
}

variable "private_subnet_cidrs" {
  description = "Plages des sous-réseaux privés (RDS exige au moins 2 zones)"
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "RDS exige au moins 2 sous-réseaux privés dans 2 zones différentes."
  }
}
