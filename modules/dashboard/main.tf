# Module tableau de bord CloudWatch : suivi de la charge et de la mise à l'échelle
# (CPU, nombre d'instances, requêtes, latence, erreurs), utilisé par les phases 3 à 5.

resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = "${var.name}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric", x = 0, y = 0, width = 12, height = 6
        properties = {
          title   = "CPU moyen du groupe Auto Scaling (%) - cible ${var.cpu_target} %"
          region  = var.region
          stat    = "Average"
          period  = 60
          view    = "timeSeries"
          metrics = [["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.asg_name]]
          annotations = {
            horizontal = [{ label = "Cible", value = var.cpu_target }]
          }
        }
      },
      {
        type = "metric", x = 12, y = 0, width = 12, height = 6
        properties = {
          title  = "Nombre d'instances"
          region = var.region
          stat   = "Maximum"
          period = 60
          view   = "timeSeries"
          metrics = [
            ["AWS/AutoScaling", "GroupDesiredCapacity", "AutoScalingGroupName", var.asg_name, { label = "Désirées" }],
            [".", "GroupInServiceInstances", ".", ".", { label = "En service" }],
            ["AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", var.target_group_arn_suffix, "LoadBalancer", var.alb_arn_suffix, { label = "Saines (ALB)" }],
          ]
        }
      },
      {
        type = "metric", x = 0, y = 6, width = 12, height = 6
        properties = {
          title   = "Requêtes reçues par l'ALB (par minute)"
          region  = var.region
          stat    = "Sum"
          period  = 60
          view    = "timeSeries"
          metrics = [["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix]]
        }
      },
      {
        type = "metric", x = 12, y = 6, width = 12, height = 6
        properties = {
          title  = "Temps de réponse des instances (s) et erreurs"
          region = var.region
          period = 60
          view   = "timeSeries"
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, { stat = "p95", label = "Temps de réponse p95" }],
            [".", "HTTPCode_Target_5XX_Count", ".", ".", { stat = "Sum", label = "Erreurs 5xx instances", yAxis = "right" }],
            [".", "HTTPCode_ELB_5XX_Count", ".", ".", { stat = "Sum", label = "Erreurs 5xx ALB", yAxis = "right" }],
          ]
        }
      },
    ]
  })
}
