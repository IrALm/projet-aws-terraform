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

variable "wait_timeout" {
  description = "Secondes avant que MySQL ferme une connexion inactive (l'application ne ferme jamais les siennes)"
  type        = number
  default     = 10
}

variable "max_connections" {
  description = "Nombre maximal de connexions simultanées (61 par défaut sur db.t3.micro)"
  type        = number
  default     = 150
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
