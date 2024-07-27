terraform {
  backend "s3" {
    bucket = "blue-green-deployment-group-4"
    key    = "ohio/terraform.tfstate"
    region = "us-east-2"
    dynamodb_table = "state-lock"
  }
}