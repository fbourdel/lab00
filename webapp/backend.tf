terraform {
  backend "s3" {
    bucket = "lab00-tfstate"
    key    = "webapp/terraform.tfstate"
    region = "eu-west-1"
  }
}