provider "aws" {
  region = var.region
}

# --- Application Artifact ---
resource "aws_s3_object" "app_artifact" {
  bucket = var.s3_bucket
  key    = "deployments/snapshot.jar"
  source = "snapshot.jar"
}

resource "aws_elastic_beanstalk_application_version" "latest" {
  name        = "${var.app_name}-${var.env_name}-v1"
  application = aws_elastic_beanstalk_application.eb_app.name
  bucket      = var.s3_bucket
  key         = aws_s3_object.app_artifact.key
}

# --- Elastic Beanstalk ---
resource "aws_elastic_beanstalk_application" "eb_app" {
  name        = var.app_name
  description = "Elastic Beanstalk Application for ${var.app_name}"
}

resource "aws_elastic_beanstalk_environment" "eb_env" {
  name                = var.env_name
  application         = aws_elastic_beanstalk_application.eb_app.name
  solution_stack_name = var.solution_stack_name
  tier                = var.tier
  version_label       = aws_elastic_beanstalk_application_version.latest.name

  # --- General Settings ---
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = var.iam_instance_profile
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = var.service_role
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = var.vpc_id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", var.subnets)
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBScheme"
    value     = "internal"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.instance_type
  }

  # --- Shared Application Load Balancer Settings ---
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerIsShared"
    value     = "true"
  }

  setting {
    namespace = "aws:elbv2:loadbalancer"
    name      = "SharedLoadBalancer"
    value     = aws_lb.this.arn
  }

  # --- Rolling Updates ---
  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "RollingUpdateEnabled"
    value     = "true"
  }

  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "RollingUpdateType"
    value     = "Health"
  }

  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "MaxBatchSize"
    value     = "1"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.instance_sg.id
  }

  # --- CloudWatch Logs Integration ---
  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "StreamLogs"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "DeleteOnTerminate"
    value     = "false"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "RetentionInDays"
    value     = "7"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "S3_BUCKET"
    value     = var.s3_bucket
  }

  # --- S3 Log Storage ---
  setting {
    namespace = "aws:elasticbeanstalk:hostmanager"
    name      = "LogPublicationControl"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "LOG_PREFIX"
    value     = "logs/eb/${var.env_name}"
  }

  # --- Dynamic Auto Scaling Group Settings (from asg.tf) ---
  dynamic "setting" {
    for_each = local.asg_settings
    content {
      namespace = setting.value.namespace
      name      = setting.value.name
      value     = setting.value.value
    }
  }

  # --- Managed Actions ---
  setting {
    namespace = "aws:elasticbeanstalk:managedactions"
    name      = "ManagedActionsEnabled"
    value     = "false"
  }

  depends_on = [
    aws_elastic_beanstalk_application.eb_app,
    aws_s3_object.app_artifact,
    aws_lb.this
  ]

  lifecycle {
    ignore_changes = [tags, tags_all]
  }
}

output "eb_app_name" {
  description = "Elastic Beanstalk Application Name"
  value       = aws_elastic_beanstalk_application.eb_app.name
}

output "eb_env_name" {
  description = "Elastic Beanstalk Environment Name"
  value       = aws_elastic_beanstalk_environment.eb_env.name
}

output "eb_env_url" {
  description = "Elastic Beanstalk Environment URL"
  value       = aws_elastic_beanstalk_environment.eb_env.cname
}

output "eb_load_balancer_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_elastic_beanstalk_environment.eb_env.load_balancers[0]
}
