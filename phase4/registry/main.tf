# Registre d'images de l'application (Amazon ECR).
#
# Configuration Terraform séparée de l'infrastructure applicative (dossier phase4/) :
# - le registre doit exister AVANT l'infrastructure, pour que les instances puissent
#   télécharger l'image dès leur premier démarrage ;
# - il survit à un "terraform destroy" de l'infrastructure : les images restent disponibles,
#   et la chaîne CI/CD (phase 5) continue d'y publier.

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "universite-exemple-poc"
      Phase     = "4"
      ManagedBy = "terraform"
    }
  }
}

variable "aws_region" {
  description = "Région AWS du registre"
  type        = string
  default     = "us-east-1"
}

variable "repository_name" {
  description = "Nom du dépôt ECR"
  type        = string
  default     = "universite-exemple-app"
}

module "ecr" {
  source = "../../modules/ecr"

  name       = var.repository_name
  max_images = 10
}

# Analyse de vulnérabilités automatique à chaque push.
# Le réglage "scan_on_push" du dépôt ne suffit pas : c'est la configuration du registre
# (au niveau du compte) qui décide, et elle ne contient aucune règle par défaut.
resource "aws_ecr_registry_scanning_configuration" "this" {
  scan_type = "BASIC"

  rule {
    scan_frequency = "SCAN_ON_PUSH"
    repository_filter {
      filter      = var.repository_name
      filter_type = "WILDCARD"
    }
  }
}

output "repository_url" {
  description = "URL du dépôt, à utiliser pour docker push / docker pull"
  value       = module.ecr.repository_url
}

output "repository_name" {
  description = "Nom du dépôt"
  value       = module.ecr.repository_name
}

output "aws_region" {
  description = "Région du registre"
  value       = var.aws_region
}
