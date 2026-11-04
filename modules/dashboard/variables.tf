variable "name" {
  description = "Préfixe du nom du tableau de bord"
  type        = string
}

variable "region" {
  description = "Région des métriques"
  type        = string
}

variable "asg_name" {
  description = "Nom du groupe Auto Scaling"
  type        = string
}

variable "cpu_target" {
  description = "Cible CPU de la politique de scaling (ligne de référence sur le graphique)"
  type        = number
}

variable "alb_arn_suffix" {
  description = "Suffixe d'ARN de l'ALB"
  type        = string
}

variable "target_group_arn_suffix" {
  description = "Suffixe d'ARN du target group"
  type        = string
}
