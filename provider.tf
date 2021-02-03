provider "aws" {
  region = "${var.aws_region}" 
  profile= "${var.myprofile}"
  version="~> 2.0"
}


terraform {
  required_version = ">= 0.14.2"
  # required_providers {
  #   aws = ">= 2.43"
  # }
  #backend "s3" {}
}