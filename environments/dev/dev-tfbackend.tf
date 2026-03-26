terraform {
  backend "s3" {
    bucket = "elasticbukcet1"
    key    = "tssdev01/terraform.tfstate"
    region = "us-east-1"
    #dynamodb_table = "tss-dev-table"
    encrypt = true
  }
}