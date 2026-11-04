terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Les identifiants AWS Academy ne sont PAS écrits ici :
# ils sont lus depuis ~/.aws/credentials ou les variables d'environnement.
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = "universite-exemple-poc"
      Phase     = "3"
      ManagedBy = "terraform"
    }
  }
}
