output "eb_env_url" {
  description = "Elastic Beanstalk Environment URL"
  value       = module.elastic_beanstalk.eb_env_url
}

output "eb_app_name" {
  description = "Elastic Beanstalk Application Name"
  value       = module.elastic_beanstalk.eb_app_name
}

output "eb_env_name" {
  description = "Elastic Beanstalk Environment Name"
  value       = module.elastic_beanstalk.eb_env_name
}

output "s3_bucket" {
  description = "The S3 bucket used for deployments"
  value       = module.elastic_beanstalk.s3_bucket
}
