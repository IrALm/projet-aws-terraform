terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Les identifiants AWS Academy ne sont PAS écrits ici.
# Ils sont lus depuis les variables d'environnement ou ~/.aws/credentials.
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "universite-exemple-poc"
      Phase     = "1"
      ManagedBy = "terraform"
    }
  }
}