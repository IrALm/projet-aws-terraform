variable "name" {
  description = "Préfixe des noms de ressources"
  type        = string
}

variable "subnet_id" {
  description = "Sous-réseau public de l'instance"
  type        = string
}

variable "security_group_ids" {
  description = "Security groups attachés à l'instance"
  type        = list(string)
}

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t3.micro"
}

variable "ubuntu_version" {
  description = "Version d'Ubuntu (ex. 22.04 ou 24.04)"
  type        = string
  default     = "24.04"
}

variable "ssh_public_key_path" {
  description = "Chemin de la clé publique SSH"
  type        = string
}

variable "iam_instance_profile" {
  description = "Profil IAM de l'instance (AWS Academy : LabInstanceProfile)"
  type        = string
  default     = "LabInstanceProfile"
}

variable "user_data_path" {
  description = "Chemin du script d'installation exécuté au premier démarrage"
  type        = string
}

variable "depends_on_ids" {
  description = "Valeurs dont la création doit précéder l'instance (ex. version du secret)"
  type        = list(string)
  default     = []
}
