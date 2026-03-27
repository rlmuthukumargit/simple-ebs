terraform {
  backend "s3" {}
}

provider "aws" {
  region = var.region
}

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
}
