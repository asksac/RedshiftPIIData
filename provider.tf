terraform {
  required_version        = ">= 1.1.0"
  required_providers {
    aws                   = ">= 4.10.0"
    random                = ">= 3.1.2"
  }
}

provider "aws" {
  profile                 = var.aws_profile
  region                  = var.aws_region
}

