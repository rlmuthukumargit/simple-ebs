region               = "us-east-2"
app_name             = "my-eb-app"
env_name             = "my-eb-env-dev"
instance_type        = "t3a.medium"
#ssl_certificate_arn  = "arn:aws:acm:us-east-1:xxxxxxxx:certificate/xxxx-xxxx-xxxx"

# --- S3 Source ---
s3_bucket            = "elasticbeanstalk-us-east-2-infra"
s3_key               = "app/application.zip" 

# --- Monitoring ---
notification_email   = "your-email@example.com"
