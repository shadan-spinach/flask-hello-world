# main.tf

provider "aws" {
  region = "ap-south-1"
}

terraform {
  backend "s3" {
    bucket = "spinach-s3"
    key    = "terraform/terraform.tfstate"
    region = "ap-south-1"
  }
}