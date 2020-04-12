terraform {
  backend "s3" {
    bucket  = "my-state-bucket"
    key     = "prod/us-east-1/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
