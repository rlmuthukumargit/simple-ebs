############################################
# --- SNS Topic for Alarms ---
############################################
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
# --- DATA SOURCES (NEW - REQUIRED) ---
############################################

# Fetch EB Auto Scaling Group
data "aws_autoscaling_groups" "eb_asg" {
  filter {
    name   = "tag:elasticbeanstalk:environment-name"
    values = [var.env_name]
  }
}

# Fetch ALB created by EB
data "aws_lb" "eb_alb" {
  tags = {
    "elasticbeanstalk:environment-name" = var.env_name
  }
}

# Fetch Target Group created by EB
data "aws_lb_target_group" "eb_tg" {
  tags = {
    "elasticbeanstalk:environment-name" = var.env_name
  }
}

############################################
# --- CloudWatch Alarms ---
############################################

# 1. Environment Health Alarm (UNCHANGED ✅)
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
}

# 2. CPU Utilization (FIXED ✅ - now accurate)
resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  alarm_name          = "${var.app_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alarm if average CPU utilization exceeds 80%"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    AutoScalingGroupName = data.aws_autoscaling_groups.eb_asg.names[0]
  }
}

# 3. Application 5xx Errors (FIXED ✅ - now real traffic errors)
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.app_name}-app-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alarm if ALB 5xx errors exceed 10 in 1 minute"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = data.aws_lb.eb_alb.arn_suffix
    TargetGroup  = data.aws_lb_target_group.eb_tg.arn_suffix
  }
}

# 4. Latency Alarm (FIXED ✅ - accurate latency)
resource "aws_cloudwatch_metric_alarm" "latency" {
  alarm_name          = "${var.app_name}-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "Alarm if application latency exceeds 1 second"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]

  dimensions = {
    LoadBalancer = data.aws_lb.eb_alb.arn_suffix
    TargetGroup  = data.aws_lb_target_group.eb_tg.arn_suffix
  }
}
