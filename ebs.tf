provider "aws" {
  region = var.region
}

# --- Elastic Beanstalk Application ---
resource "aws_elastic_beanstalk_application" "eb_app" {
  name        = var.app_name
  description = "Elastic Beanstalk Application for ${var.app_name}"
}

# --- Elastic Beanstalk Environment ---
resource "aws_elastic_beanstalk_environment" "eb_env" {
  name                = var.env_name
  application         = aws_elastic_beanstalk_application.eb_app.name
  solution_stack_name = var.solution_stack_name
  tier                = var.tier

  # --- IAM ---
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

  # --- VPC / Network ---
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
    name      = "ELBSubnets"
    value     = join(",", var.subnets)
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBScheme"
    value     = "internal"
  }

  # --- Instance Settings ---
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.instance_type
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "DisableIMDSv1"
    value     = "true"
  }

  # --- Load Balancer ---
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }

  setting {
    namespace = "aws:elbv2:loadbalancer"
    name      = "SharedLoadBalancer"
    value     = "false"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckPath"
    value     = "/"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "Port"
    value     = "80"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "Protocol"
    value     = "HTTP"
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
    value     = "30"
  }

  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "MaxBatchSizeUnit"
    value     = "Percentage"
  }

  # --- Deployment ---
  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "DeploymentPolicy"
    value     = "Rolling"
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "InstanceReplacement"
    value     = "false"
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "Timeout"
    value     = "600"
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "IgnoreHealthCheck"
    value     = "false"
  }

  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "HealthCheckSuccessThreshold"
    value     = "Ok"
  }

  # --- CloudWatch Logs ---
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

  # --- Managed Actions ---
  setting {
    namespace = "aws:elasticbeanstalk:managedactions"
    name      = "ManagedActionsEnabled"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:managedactions"
    name      = "PreferredStartTime"
    value     = "Sun:03:00"
  }

  setting {
    namespace = "aws:elasticbeanstalk:managedactions:platformupdate"
    name      = "UpdateLevel"
    value     = "minor"
  }

  # --- Proxy Server ---
  setting {
    namespace = "aws:elasticbeanstalk:environment:proxy"
    name      = "ProxyServer"
    value     = "nginx"
  }

  # --- Store Logs ---
  setting {
    namespace = "aws:elasticbeanstalk:hostmanager"
    name      = "LogPublicationControl"
    value     = "false"
  }

  # --- X-Ray ---
  setting {
    namespace = "aws:elasticbeanstalk:xray"
    name      = "XRayEnabled"
    value     = "false"
  }

  # --- Rotate Logs ---
  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "RotateLogs"
    value     = "true"
  }

  # --- Environment Properties ---
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "ASPNETCORE_ENVIRONMENT"
    value     = "Development"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "D365_BASE_URL"
    value     = "https://tss-d365-d2.crm.dynamics.com"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "D365_CLIENT_ID"
    value     = "aa78a446-0627-4353-8419-d66bcbfdf4e0"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "D365_CLIENT_SECRET"
    value     = "arn:aws:secretsmanager:us-east-2:510931056574:secret:D365_CLIENT_SECRET_D2-WhUnC"
  }

  # --- Dynamic Auto Scaling Group Settings ---
  dynamic "setting" {
    for_each = local.asg_settings
    content {
      namespace = setting.value.namespace
      name      = setting.value.name
      value     = setting.value.value
    }
  }

  depends_on = [
    aws_elastic_beanstalk_application.eb_app
  ]

  lifecycle {
    ignore_changes = [tags, tags_all]
  }
}

# --- Outputs ---
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
