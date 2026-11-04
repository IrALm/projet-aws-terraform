variable "name" {
  description = "Préfixe des noms de ressources"
  type        = string
}

variable "subnet_ids" {
  description = "Sous-réseaux privés de la base (au moins 2 zones)"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups attachés à l'instance RDS"
  type        = list(string)
}

variable "engine_version" {
  description = "Version du moteur MySQL"
  type        = string
  default     = "8.4"
}

variable "instance_class" {
  description = "Classe d'instance RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Stockage initial en Go"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Stockage maximal en Go (autoscaling du stockage)"
  type        = number
  default     = 50
}

variable "db_name" {
  description = "Nom de la base créée au démarrage (attendu par l'application)"
  type        = string
  default     = "STUDENTS"
}

variable "db_username" {
  description = "Utilisateur administrateur de la base"
  type        = string
  default     = "admin"
}

variable "multi_az" {
  description = "Active la réplique de secours dans une autre zone"
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Durée de conservation des sauvegardes automatiques (jours)"
  type        = number
  default     = 1
}
