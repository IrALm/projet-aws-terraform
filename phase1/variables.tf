variable "aws_region" {
  description = "Region AWS utilisee pour le deploiement"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nom du projet, utilise pour nommer les ressources"
  type        = string
  default     = "universite-exemple"
}

variable "vpc_cidr" {
  description = "Plage d adresses IP du VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "Plage d adresses IP du sous-reseau public ou se trouve la VM"
  type        = string
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "Type d instance EC2 pour la VM de l application"
  type        = string
  default     = "t3.small"
}

variable "ubuntu_version" {
  description = "Version d Ubuntu (ex. 22.04 ou 24.04)"
  type        = string
  default     = "24.04"
}

variable "ssh_allowed_cidr" {
  description = "Adresse IP autorisee a se connecter en SSH, au format x.x.x.x/32"
  type        = string
  # Pas de valeur par défaut : c'est à vous de la renseigner.
}

variable "ssh_public_key_path" {
  description = "Chemin de la cle publique SSH a installer sur la VM"
  type        = string
  default     = "~/.ssh/id_ed25519_phase1.pub"
}