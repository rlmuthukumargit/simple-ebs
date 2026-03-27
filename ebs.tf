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
  tier                = "WebServer"

  # --- MANDATORY: IAM ---
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

  # --- MANDATORY: VPC / Network ---
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

  # --- MANDATORY: Load Balancer Type ---
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }

  # --- APP SETTINGS: Environment Variable ---
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "ASPNETCORE_ENVIRONMENT"
    value     = "Development"
  }

  depends_on = [
    aws_elastic_beanstalk_application.eb_app
  ]

  lifecycle {
    ignore_changes = [tags, tags_all]
  }
}

# --- Outputs ---
output "eb_env_url" {
  description = "Elastic Beanstalk Environment URL"
  value       = aws_elastic_beanstalk_environment.eb_env.cname
}
