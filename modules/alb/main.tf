# Module équilibreur de charge : Application Load Balancer public, sur 2 zones.
# Il répartit les requêtes entre les instances saines du groupe Auto Scaling
# et retire automatiquement du trafic une instance qui ne répond plus.

resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids # au moins 2 zones : l'ALB reste disponible si une zone tombe

  # Rejette les en-têtes HTTP malformés (protection contre le "request smuggling")
  drop_invalid_header_fields = true
  idle_timeout               = 60

  # POC : suppression possible par terraform destroy
  enable_deletion_protection = false

  tags = { Name = "${var.name}-alb" }
}

resource "aws_lb_target_group" "this" {
  name        = "${var.name}-tg"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  # Temps laissé aux requêtes en cours avant de retirer une instance (300 s par défaut) :
  # réduit pour accélérer les remplacements et le scale-in.
  deregistration_delay = 30

  # La page d'accueil "/" ne dépend pas de la base : une panne de RDS ne fait pas
  # retirer toutes les instances (évite une panne en cascade).
  health_check {
    path                = var.health_check_path
    matcher             = "200"
    interval            = 15
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = { Name = "${var.name}-tg" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
