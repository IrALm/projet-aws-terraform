# Module registre : dépôt Amazon ECR privé pour l'image de l'application.

resource "aws_ecr_repository" "this" {
  name = var.name

  # Tags modifiables : "latest" désigne toujours la dernière version déployée,
  # chaque build étant aussi poussé avec un tag immuable (SHA du commit Git).
  image_tag_mutability = "MUTABLE"

  # Analyse de vulnérabilités (CVE) automatique à chaque push
  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  # POC : autorise terraform destroy même si le dépôt contient des images
  force_delete = var.force_delete

  tags = { Name = var.name }
}

# Politique de cycle de vie : limite le stockage (et donc le coût) aux N dernières images
resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Supprimer les images sans tag apres 1 jour"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Conserver les ${var.max_images} images les plus recentes"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.max_images
        }
        action = { type = "expire" }
      },
    ]
  })
}
