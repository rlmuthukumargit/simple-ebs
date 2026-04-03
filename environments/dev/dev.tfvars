region               = "us-east-2"
app_name             = "my-eb-app"
env_name             = "my-eb-env-dev"
iam_instance_profile = "aws-elasticbeanstalk-ec2-role"
service_role         = "arn:aws:iam::911287867452:role/aws-elasticbeanstalk-service-role"
vpc_id               = "vpc-0975e41529fdd220e"
subnets              = ["subnet-0db123d54c271e391", "subnet-07f28a28b8830044b", "subnet-0b17ab8abf3a8b378"]
instance_type        = "t3a.medium"
#ssl_certificate_arn  = "arn:aws:acm:us-east-1:xxxxxxxx:certificate/xxxx-xxxx-xxxx"

# --- S3 Source ---
s3_bucket            = "elasticbeanstalk-us-east-2-infra"
s3_key               = "app/application.zip" 

# --- Monitoring ---
notification_email   = "your-email@example.com"
