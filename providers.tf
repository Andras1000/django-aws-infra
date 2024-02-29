provider "aws" {
  region = var.region
}

terraform {
  backend "s3" {
    bucket = "terraform-django-ecs-aws"
    key    = "terraform.tfstate"
    region = "eu-west-1"
  }
}