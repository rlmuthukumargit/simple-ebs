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

############################################
# --- CloudWatch LOG-BASED MONITORING ---
# Metric Filters + Alarms for EB logs
############################################
# EB native log streaming creates log groups at:
#   /aws/elasticbeanstalk/<env_name>/environment/eb-engine.log
#   /aws/elasticbeanstalk/<env_name>/environment/web.stdout.log
#   /aws/elasticbeanstalk/<env_name>/environment/nginx/error.log

# --- 5. Application Errors (web.stdout.log) ---
resource "aws_cloudwatch_log_metric_filter" "app_errors" {
  name           = "${var.app_name}-app-error-filter"
  log_group_name = "/aws/elasticbeanstalk/${var.env_name}/environment/web.stdout.log"
  pattern        = "?ERROR ?Exception ?\"error\" ?\"FATAL\" ?\"ORA-\""

  metric_transformation {
    name          = "${var.app_name}-AppErrorCount"
    namespace     = "Custom/${var.app_name}"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "app_errors" {
  alarm_name          = "${var.app_name}-app-log-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "${var.app_name}-AppErrorCount"
  namespace           = "Custom/${var.app_name}"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Alarm if application logs contain more than 5 errors in 5 minutes (web.stdout.log)"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  tags = {
    Application = var.app_name
    EnvName     = var.env_name
  }
}

# --- 6. EB Engine Errors (eb-engine.log) ---
resource "aws_cloudwatch_log_metric_filter" "eb_engine_errors" {
  name           = "${var.app_name}-eb-engine-error-filter"
  log_group_name = "/aws/elasticbeanstalk/${var.env_name}/environment/eb-engine.log"
  pattern        = "?ERROR ?\"error\" ?\"Failed\" ?\"failed\""

  metric_transformation {
    name          = "${var.app_name}-EBEngineErrorCount"
    namespace     = "Custom/${var.app_name}"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "eb_engine_errors" {
  alarm_name          = "${var.app_name}-eb-engine-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "${var.app_name}-EBEngineErrorCount"
  namespace           = "Custom/${var.app_name}"
  period              = 300
  statistic           = "Sum"
  threshold           = 3
  alarm_description   = "Alarm if EB engine logs contain more than 3 errors in 5 minutes (eb-engine.log)"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  tags = {
    Application = var.app_name
    EnvName     = var.env_name
  }
}

# --- 7. Nginx Errors (nginx/error.log) ---
resource "aws_cloudwatch_log_metric_filter" "nginx_errors" {
  name           = "${var.app_name}-nginx-error-filter"
  log_group_name = "/aws/elasticbeanstalk/${var.env_name}/environment/nginx/error.log"
  pattern        = "?error ?crit ?alert ?emerg"

  metric_transformation {
    name          = "${var.app_name}-NginxErrorCount"
    namespace     = "Custom/${var.app_name}"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "nginx_errors" {
  alarm_name          = "${var.app_name}-nginx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "${var.app_name}-NginxErrorCount"
  namespace           = "Custom/${var.app_name}"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alarm if Nginx error logs exceed 10 entries in 5 minutes"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  tags = {
    Application = var.app_name
    EnvName     = var.env_name
  }
}
