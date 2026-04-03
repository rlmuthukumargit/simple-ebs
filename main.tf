module "elastic_beanstalk" {
  source = "./modules/elastic-beanstalk"

  app_name             = var.app_name
  env_name             = var.env_name
  iam_instance_profile = var.iam_instance_profile
  service_role         = var.service_role
  vpc_id               = var.vpc_id
  subnets              = var.subnets
  instance_type        = var.instance_type
  tier                 = var.tier
  solution_stack_name  = var.solution_stack_name
  ssl_certificate_arn  = var.ssl_certificate_arn
  
  # S3 Source
  s3_bucket            = var.s3_bucket
  s3_key               = var.s3_key
}

module "monitoring" {
  source             = "./modules/monitoring"
  app_name           = var.app_name
  env_name           = var.env_name
  notification_email = var.notification_email
}
