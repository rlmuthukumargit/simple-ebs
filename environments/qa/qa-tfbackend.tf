terraform {
  backend "s3" {
    bucket  = "tss-ebstalk-qa-backend"
    key     = "qa/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
