############################################
# --- SNS Topic for Alarms ---
############################################
resource "aws_sns_topic" "alerts" {
  name = "${var.app_name}-alerts"
  tags = {
    Application = var.app_name
    EnvName     = var.env_name
  }
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    sid     = "AllowCloudWatchAlarms"
    actions = ["sns:Publish"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
    resources = [aws_sns_topic.alerts.arn]
  }
}

resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.alerts.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

############################################
# --- CloudWatch Alarms (ULTIMATE STABILITY) ---
############################################
# All alarms now use the 'EnvironmentName' dimension.
# This ensures that dashboards and alerts NEVER break, even if 
# AWS recreates Instances, ASGs, or Load Balancers during updates.

# 1. Environment Health Alarm
resource "aws_cloudwatch_metric_alarm" "eb_health" {
  alarm_name          = "${var.app_name}-eb-health"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "EnvironmentHealth"
  namespace           = "AWS/ElasticBeanstalk"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "Alarm if Elastic Beanstalk health is not Ok"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    EnvironmentName = var.env_name
  }

  tags = {
    Application = var.app_name
    EnvName     = var.env_name
  }
}

# 2. CPU Utilization
resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  alarm_name          = "${var.app_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ElasticBeanstalk"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alarm if environment-wide CPU utilization exceeds 80%"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    EnvironmentName = var.env_name
  }

  tags = {
    Application = var.app_name
    EnvName     = var.env_name
  }
}

# 3. Application 5xx Errors (Service Level)
resource "aws_cloudwatch_metric_alarm" "eb_5xx" {
  alarm_name          = "${var.app_name}-app-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApplicationRequests5xx"
  namespace           = "AWS/ElasticBeanstalk"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alarm if environment 5xx errors exceed 10 in 1 minute"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    EnvironmentName = var.env_name
  }

  tags = {
    Application = var.app_name
    EnvName     = var.env_name
  }
}

# 4. Latency Alarm (Service Level)
resource "aws_cloudwatch_metric_alarm" "eb_latency" {
  alarm_name          = "${var.app_name}-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "Duration"
  namespace           = "AWS/ElasticBeanstalk"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "Alarm if average environment response duration exceeds 1 second"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    EnvironmentName = var.env_name
  }

  tags = {
    Application = var.app_name
    EnvName     = var.env_name
  }
}
