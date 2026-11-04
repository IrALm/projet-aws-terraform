variable "name" {
  description = "Préfixe des noms de ressources"
  type        = string
}

variable "subnet_ids" {
  description = "Sous-réseaux des instances (un par zone)"
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security groups des instances"
  type        = list(string)
}

variable "target_group_arns" {
  description = "Target groups de l'ALB dans lesquels enregistrer les instances"
  type        = list(string)
}

variable "instance_type" {
  description = "Type d'instance"
  type        = string
  default     = "t3.micro"
}

variable "ubuntu_version" {
  description = "Version d'Ubuntu"
  type        = string
  default     = "24.04"
}

variable "ssh_public_key_path" {
  description = "Chemin de la clé publique SSH"
  type        = string
}

variable "iam_instance_profile" {
  description = "Profil IAM des instances (AWS Academy : LabInstanceProfile)"
  type        = string
  default     = "LabInstanceProfile"
}

variable "user_data_path" {
  description = "Fichier du script d'installation exécuté au premier démarrage (si user_data est vide)"
  type        = string
  default     = null
}

variable "user_data" {
  description = "Contenu du script d'installation (prioritaire sur user_data_path), ex. templatefile(...)"
  type        = string
  default     = null
}

variable "metadata_hop_limit" {
  description = "Nombre de sauts autorisés vers IMDS (2 si l'application tourne dans un conteneur)"
  type        = number
  default     = 1
}

variable "min_size" {
  description = "Nombre minimal d'instances (2 = une par zone, haute disponibilité)"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Nombre maximal d'instances (plafond de coût)"
  type        = number
  default     = 4
}

variable "desired_capacity" {
  description = "Nombre d'instances au démarrage"
  type        = number
  default     = 2
}

variable "cpu_target" {
  description = "Utilisation CPU moyenne visée par la politique de scaling (%)"
  type        = number
  default     = 50
}

variable "health_check_grace_period" {
  description = "Délai (s) avant la prise en compte du health check d'une nouvelle instance"
  type        = number
  default     = 600
}

variable "instance_warmup" {
  description = "Délai (s) avant que les métriques d'une nouvelle instance comptent pour le scaling"
  type        = number
  default     = 300
}

variable "enable_instance_refresh" {
  description = "Remplace automatiquement les instances quand le modèle de lancement change (interdit dans AWS Academy)"
  type        = bool
  default     = false
}

variable "detailed_monitoring" {
  description = "Métriques EC2 à la minute (scaling plus réactif, faible surcoût)"
  type        = bool
  default     = true
}

variable "depends_on_ids" {
  description = "Valeurs dont la création doit précéder les instances (ex. version du secret)"
  type        = list(string)
  default     = []
}
