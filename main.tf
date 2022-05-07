/**
 * # Terraform Module - RedshiftPIIData
 *
 */

data "aws_caller_identity" "current" {}

data "aws_vpc" "rsdb" {
  id                      = var.rsdb_vpc_id
}

data "aws_subnet" "rsdb" {
  count                   = length(var.rsdb_subnet_ids)
  id                      = var.rsdb_subnet_ids[count.index]
}

data "aws_vpc" "client" {
  id                      = var.client_vpc_id
}

data "aws_subnet" "client" {
  count                   = length(var.client_subnet_ids)
  id                      = var.client_subnet_ids[count.index]
}

locals {
  # Common tags to be assigned to all resources
  common_tags             = {
    Application           = var.app_name
    Environment           = var.aws_env
  }

  account_id              = data.aws_caller_identity.current.account_id
}

