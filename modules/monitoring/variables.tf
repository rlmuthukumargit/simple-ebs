variable "app_name" {
  description = "The name of the Application"
  type        = string
}

variable "env_name" {
  description = "The name of the Environment"
  type        = string
}

variable "notification_email" {
  description = "The email address to receive CloudWatch Alarms"
  type        = string
}
