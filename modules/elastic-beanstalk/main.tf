# --- DATA: Get VPC Details ---
#data "aws_vpc" "selected" {
#  id = var.vpc_id
#}

# --- Elastic Beanstalk Application ---
resource "aws_elastic_beanstalk_application" "eb_app" {
  name        = var.app_name
  description = "Elastic Beanstalk Application for ${var.app_name}"

  appversion_lifecycle {
    service_role          = var.service_role
    max_count             = 100
    delete_source_from_s3 = true
  }
}

# --- Elastic Beanstalk Application Version (S3 Source) ---
resource "aws_elastic_beanstalk_application_version" "eb_version" {
  name        = "${var.app_name}-v-${formatdate("YYYYMMDDhhmmss", timestamp())}"
  application = aws_elastic_beanstalk_application.eb_app.name
  description = "Application version for ${var.app_name} from S3 bucket ${var.s3_bucket}"
  bucket      = var.s3_bucket
  key         = var.s3_key
}

# --- Elastic Beanstalk Environment ---
resource "aws_elastic_beanstalk_environment" "eb_env" {
  name                = var.env_name
  application         = aws_elastic_beanstalk_application.eb_app.name
  solution_stack_name = var.solution_stack_name
  tier                = var.tier
  cname_prefix        = var.env_name
  version_label       = aws_elastic_beanstalk_application_version.eb_version.name

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

  # --- UPDATES & DEPLOYMENTS (Un-wedge mode) ---
  setting {
    namespace = "aws:elasticbeanstalk:command"
    name      = "DeploymentPolicy"
    value     = "AllAtOnce"
  }

  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name      = "RollingUpdateEnabled"
    value     = "false"
  }

  # --- MANDATORY: Instance Configuration ---
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.instance_type
  }

  # --- HTTPS Listener (Port 443) ---
  #setting {
  #  namespace = "aws:elbv2:listener:443"
  #  name      = "Protocol"
  #  value     = "HTTPS"
  #}

  #setting {
  #  namespace = "aws:elbv2:listener:443"
  #  name      = "SSLCertificateArns"
  #  value     = var.ssl_certificate_arn
  #}

  #setting {
  #  namespace = "aws:elbv2:listener:443"
  #  name      = "SSLPolicy"
  #  value     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  #}

  # --- APP SETTINGS: Environment Variable ---
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SERVER_PORT"
    value     = "8080"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "PORT"
    value     = "8080"
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "JAVA_OPTS"
    value     = "-Xmx512m"
  }

  # --- PHASE 1: COMMENT THIS OUT ---
  # Run terraform apply once. After it succeeds, uncomment this for Phase 2.
  # setting {
  #   namespace = "aws:autoscaling:launchconfiguration"
  #   name      = "InstanceType"
  #   value     = var.instance_type
  # }

  # --- PROCESS SETTINGS: Port and Health Check ---
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "Port"
    value     = "8080"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "Protocol"
    value     = "HTTP"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckPath"
    value     = "/actuator/health"
  }



  depends_on = [
    aws_elastic_beanstalk_application.eb_app
  ]

  tags = {
    Name        = var.app_name
    Environment = var.app_name
  }

  lifecycle {
    ignore_changes = [
      tags_all
    ]
  }
}
