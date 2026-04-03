output "eb_env_url" {
  description = "Elastic Beanstalk Environment URL"
  value       = aws_elastic_beanstalk_environment.eb_env.cname
}

output "eb_app_name" {
  description = "Elastic Beanstalk Application Name"
  value       = aws_elastic_beanstalk_application.eb_app.name
}

output "eb_env_name" {
  description = "Elastic Beanstalk Environment Name"
  value       = aws_elastic_beanstalk_environment.eb_env.name
}

output "s3_bucket" {
  description = "The S3 bucket used for deployments"
  value       = var.s3_bucket
}
