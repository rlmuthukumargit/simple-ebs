output "eb_env_url" {
  description = "Elastic Beanstalk Environment URL"
  value       = aws_elastic_beanstalk_environment.eb_env.cname
}
