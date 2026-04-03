variable "app_name" {
  description = "Elastic Beanstalk Application Name"
  type        = string
}

variable "env_name" {
  description = "Elastic Beanstalk Environment Name"
  type        = string
}

variable "iam_instance_profile" {
  description = "Existing IAM instance profile name"
  type        = string
}

variable "service_role" {
  description = "Existing IAM service role ARN"
  type        = string
}

variable "vpc_id" {
  description = "Existing VPC ID"
  type        = string
}

variable "subnets" {
  description = "A list of subnet IDs to launch resources in"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type(s)"
  type        = string
}

variable "tier" {
  description = "Elastic Beanstalk Environment Tier"
  type        = string
}

variable "solution_stack_name" {
  description = "Elastic Beanstalk Solution Stack Name"
  type        = string
}

variable "ssl_certificate_arn" {
  description = "SSL Certificate ARN for the ALB"
  type        = string
  default     = ""
}

# --- S3 Source ---
variable "s3_bucket" {
  description = "The S3 bucket containing the JAR/ZIP file"
  type        = string
}

variable "s3_key" {
  description = "The S3 key (path) to the JAR/ZIP file"
  type        = string
}
