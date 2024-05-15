terraform {
  backend "s3" {
    bucket         = "geofoodtruck-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "geofoodtruck-terraform-state-lock"
    encrypt        = true
  }
}