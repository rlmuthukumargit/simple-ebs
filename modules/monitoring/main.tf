# --- SNS Topic for Alarms ---
resource "aws_sns_topic" "alerts" {
  name = "${var.app_name}-alerts"
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    actions = ["sns:Publish"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudwatch.amazonaws.com"]
    }
    resources = [aws_sns_topic.alerts.arn]
    sid       = "AllowCloudWatchEvents"
  }
}

resource "aws_sns_topic_policy" "default" {
  arn    = aws_sns_topic.alerts.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

# --- CloudWatch Alarms ---

# 1. Environment Health Alarm
resource "aws_cloudwatch_metric_alarm" "eb_health" {
  alarm_name          = "${var.app_name}-eb-health"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "EnvironmentHealth"
  namespace           = "AWS/ElasticBeanstalk"
  period              = "60"
  statistic           = "Maximum"
  threshold           = "0" # 0 is "Ok", any value > 0 indicates Warning, Degraded, or Severe
  alarm_description   = "Alarm if Elastic Beanstalk health is not Ok"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    EnvironmentName = var.env_name
  }
}

# 2. High CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  alarm_name          = "${var.app_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "Alarm if average CPU utilization exceeds 80%"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

# 3. ALB 5xx Errors Alarm
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.app_name}-alb-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "Alarm if ALB 5xx errors exceed 10 in 1 minute"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

# 4. Latency Alarm (Target Response Time)
resource "aws_cloudwatch_metric_alarm" "latency" {
  alarm_name          = "${var.app_name}-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Average"
  threshold           = "1" # 1 second
  alarm_description   = "Alarm if application latency exceeds 1 second"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
}

# --- CloudWatch Dashboard ---
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.app_name}-${var.env_name}-monitoring"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 24
        height = 3
        properties = {
          metrics = [
            ["AWS/ElasticBeanstalk", "EnvironmentHealth", "EnvironmentName", var.env_name]
          ]
          period  = 60
          stat    = "Maximum"
          region  = "us-east-2"
          title   = "Environment Health (0=Ok, >0=Degraded/Severe)"
          view    = "singleValue"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 3
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ElasticBeanstalk", "Requests", "EnvironmentName", var.env_name]
          ]
          period  = 60
          stat    = "Sum"
          region  = "us-east-2"
          title   = "Request Traffic"
          view    = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 3
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ElasticBeanstalk", "Duration", "EnvironmentName", var.env_name, { "label": "Avg Latency (ms)" }]
          ]
          period  = 60
          stat    = "Average"
          region  = "us-east-2"
          title   = "Target Latency (ms)"
          view    = "timeSeries"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 9
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ElasticBeanstalk", "ApplicationRequests4xx", "EnvironmentName", var.env_name, { "color": "#ff7f0e" }],
            ["AWS/ElasticBeanstalk", "ApplicationRequests5xx", "EnvironmentName", var.env_name, { "color": "#d62728" }]
          ]
          period  = 60
          stat    = "Sum"
          region  = "us-east-2"
          title   = "4xx and 5xx Error Rates"
          view    = "timeSeries"
        }
      }
    ]
  })
}

# --- UNIFIED LOG GROUP ---
# All logs in the .ebextensions config will be pushed to this single group.
resource "aws_cloudwatch_log_group" "unified" {
  name              = "/aws/elasticbeanstalk/${var.env_name}/unified"
  retention_in_days = 7
}
