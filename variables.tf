variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

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
  description = "List of subnets"
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type(s)"
  type        = string
  default     = "t3a.medium,t3a.large"
}

variable "tier" {
  description = "Elastic Beanstalk Environment Tier"
  type        = string
  default     = "WebServer"
}

variable "solution_stack_name" {
  description = "Elastic Beanstalk Solution Stack Name"
  type        = string
  default     = "64bit Amazon Linux 2023 v4.10.0 running Corretto 25"
}
