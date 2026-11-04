variable "aws_region" {
  description = "Région AWS (le code de l'application lit le secret en us-east-1)"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nom du projet, utilisé pour nommer les ressources"
  type        = string
  default     = "universite-exemple"
}

variable "vpc_cidr" {
  description = "Plage d'adresses du VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Sous-réseaux publics (serveurs web), un par zone"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Sous-réseaux privés (base de données), un par zone"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "instance_type" {
  description = "Type d'instance du serveur web (plus de MySQL local : t3.micro suffit)"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_class" {
  description = "Classe de l'instance RDS"
  type        = string
  default     = "db.t3.micro"
}

variable "db_engine_version" {
  description = "Version de MySQL sur RDS"
  type        = string
  default     = "8.4"
}

variable "iam_instance_profile" {
  description = "Profil IAM de l'EC2 (AWS Academy : LabInstanceProfile)"
  type        = string
  default     = "LabInstanceProfile"
}

variable "ssh_allowed_cidr" {
  description = "Votre IP publique au format x.x.x.x/32"
  type        = string
  # Pas de valeur par défaut : à renseigner dans terraform.tfvars
}

variable "ssh_public_key_path" {
  description = "Chemin de la clé publique SSH (la même qu'en phase 1)"
  type        = string
  default     = "~/.ssh/id_ed25519_phase1.pub"
}
