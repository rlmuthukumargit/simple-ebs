# --- Monitoring (Use Existing SNS Topic) ---

data "aws_sns_topic" "alerts" {
  name = "${var.app_name}-${var.env_name}-alerts"
}

# --- Elastic Beanstalk Alarms ---

resource "aws_cloudwatch_metric_alarm" "eb_health" {
  alarm_name          = "${var.app_name}-${var.env_name}-eb-unhealthy"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "EnvironmentHealth"
  namespace           = "AWS/ElasticBeanstalk"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "0" # 0 is OK/Green. Higher values mean Warning/Degraded/Severe.
  alarm_description   = "This metric monitors EB environment health (Non-Green status)"
  alarm_actions       = [data.aws_sns_topic.alerts.arn]

  dimensions = {
    EnvironmentName = aws_elastic_beanstalk_environment.eb_env.name
  }
}

resource "aws_cloudwatch_metric_alarm" "eb_4xx" {
  alarm_name          = "${var.app_name}-${var.env_name}-eb-high-4xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ApplicationRequests4xx"
  namespace           = "AWS/ElasticBeanstalk"
  period              = "60"
  statistic           = "Sum"
  threshold           = "50"
  alarm_description   = "This metric monitors high 4XX errors on the EB environment"
  alarm_actions       = [data.aws_sns_topic.alerts.arn]

  dimensions = {
    EnvironmentName = aws_elastic_beanstalk_environment.eb_env.name
  }
}

resource "aws_cloudwatch_metric_alarm" "eb_5xx" {
  alarm_name          = "${var.app_name}-${var.env_name}-eb-high-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ApplicationRequests5xx"
  namespace           = "AWS/ElasticBeanstalk"
  period              = "60"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors high 5XX errors on the EB environment"
  alarm_actions       = [data.aws_sns_topic.alerts.arn]

  dimensions = {
    EnvironmentName = aws_elastic_beanstalk_environment.eb_env.name
  }
}

output "sns_topic_arn" {
  description = "The ARN of the SNS topic for alerts"
  value       = data.aws_sns_topic.alerts.arn
}
