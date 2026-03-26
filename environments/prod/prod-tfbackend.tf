terraform {
  backend "s3" {
    bucket  = "tss-ebstalk-prod-backend"
    key     = "prod/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
