
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.14.0"
    }
  }
}
provider "aws" {
  region = "eu-central-1"
  profile = "default"
}