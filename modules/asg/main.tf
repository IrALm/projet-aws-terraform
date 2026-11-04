# Module Auto Scaling : modèle de lancement + groupe Auto Scaling + politique de mise à l'échelle.
# - Haute disponibilité : instances réparties sur 2 zones, remplacées automatiquement si l'ALB
#   les déclare non saines.
# - Mise à l'échelle : le nombre d'instances suit la charge CPU (target tracking).

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd*/ubuntu-*-${var.ubuntu_version}-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Tags par défaut du provider (Project, Phase...) : recopiés sur les instances lancées par l'ASG,
# car les default_tags ne s'appliquent pas automatiquement aux instances créées par AWS.
data "aws_default_tags" "current" {}

resource "aws_key_pair" "this" {
  key_name   = "${var.name}-key"
  public_key = file(pathexpand(var.ssh_public_key_path))
}

resource "aws_launch_template" "this" {
  name        = "${var.name}-lt"
  description = "Serveur web de l application (Node.js), lit ses identifiants dans Secrets Manager"

  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.this.key_name

  vpc_security_group_ids = var.security_group_ids

  # Profil IAM fourni par AWS Academy : autorise la lecture du secret
  iam_instance_profile {
    name = var.iam_instance_profile
  }

  # Script fourni soit sous forme de contenu (template rendu par l'appelant), soit de fichier
  user_data = var.user_data != null ? base64encode(var.user_data) : filebase64(var.user_data_path)

  # IMDSv2 obligatoire.
  # hop_limit = 1 : seuls les processus de l'hôte obtiennent les identifiants du rôle.
  # hop_limit = 2 : nécessaire quand l'application tourne dans un conteneur Docker
  # (le pont réseau Docker ajoute un saut), sinon le SDK ne peut pas lire le secret.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = var.metadata_hop_limit
  }

  # Métriques CloudWatch toutes les minutes (au lieu de 5) : la politique de scaling réagit plus vite
  monitoring {
    enabled = var.detailed_monitoring
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_type           = "gp3"
      volume_size           = 20
      encrypted             = true
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(data.aws_default_tags.current.tags, { Name = "${var.name}-web" })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(data.aws_default_tags.current.tags, { Name = "${var.name}-web" })
  }

  # Chaque modification crée une nouvelle version, utilisée par défaut
  update_default_version = true

  tags = { Name = "${var.name}-lt" }
}

resource "aws_autoscaling_group" "this" {
  name = "${var.name}-asg"

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = var.desired_capacity

  # Instances réparties sur toutes les zones fournies
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = var.target_group_arns

  # "ELB" : une instance que l'ALB déclare non saine est remplacée (pas seulement si elle est arrêtée)
  health_check_type = "ELB"
  # Délai avant de prendre en compte le health check : le premier démarrage
  # (apt + npm + application) prend 3 à 5 minutes.
  health_check_grace_period = var.health_check_grace_period
  # Pendant ce délai, les métriques d'une nouvelle instance ne sont pas prises en compte par le scaling
  default_instance_warmup = var.instance_warmup

  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }

  # Remplacement automatique des instances à chaque modification du modèle de lancement.
  # 100 % / 200 % : les nouvelles instances sont lancées et déclarées saines AVANT le retrait
  # des anciennes ("launch before terminate") : la capacité ne baisse jamais.
  # DÉSACTIVÉ par défaut : dans AWS Academy, autoscaling:StartInstanceRefresh est refusé par
  # une politique de l'organisation (SCP), ce qui ferait échouer "terraform apply".
  # Remplacement équivalent sans cette API : phase5/scripts/rolling-deploy.sh.
  dynamic "instance_refresh" {
    for_each = var.enable_instance_refresh ? [1] : []
    content {
      strategy = "Rolling"
      preferences {
        min_healthy_percentage = 100
        max_healthy_percentage = 200
        instance_warmup        = var.instance_warmup
      }
    }
  }

  # Métriques du groupe visibles dans CloudWatch (capacité désirée, en service...)
  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]

  tag {
    key                 = "Name"
    value               = "${var.name}-web"
    propagate_at_launch = true
  }

  # Après une mise à l'échelle, un "terraform apply" ne doit pas remettre la capacité à sa valeur initiale
  lifecycle {
    ignore_changes = [desired_capacity]
  }

  # Le secret doit exister avant le démarrage des instances
  depends_on = [terraform_data.wait_for]
}

# Politique de suivi de cible : AWS ajoute ou retire des instances pour maintenir
# l'utilisation CPU moyenne du groupe autour de la cible (scale-out rapide, scale-in prudent).
resource "aws_autoscaling_policy" "cpu" {
  name                   = "${var.name}-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.cpu_target
  }
}

# Ancre de dépendance (même principe que dans le module app_server)
resource "terraform_data" "wait_for" {
  input = var.depends_on_ids
}
