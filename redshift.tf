# create redshift cluster

resource "random_password" "rs_master_password" {
  length                  = 16
  special                 = false
}

resource "aws_redshift_subnet_group" "rs_subnet_group" {
  name                    = "${var.app_shortcode}-rs-subnets"
  subnet_ids              = data.aws_subnet.rsdb.*.id

  tags                    = local.common_tags
}

resource "aws_redshift_cluster" "rs_cluster" {
  cluster_identifier      = "${var.app_shortcode}-rs-cluster"
  node_type               = "dc2.large"
  cluster_type            = "multi-node"
  number_of_nodes         = 2

  cluster_subnet_group_name = aws_redshift_subnet_group.rs_subnet_group.name
  port                    = var.rsdb_port
  publicly_accessible     = true
  vpc_security_group_ids  = [ aws_security_group.rsdb_sg.id ]
  iam_roles               = [ aws_iam_role.redshift_assume_role.arn ]

  automated_snapshot_retention_period = 30

  database_name           = "${var.app_shortcode}_${var.aws_env}_db"
  encrypted               = true
  master_username         = var.rsdb_master_user
  master_password         = random_password.rs_master_password.result

  tags                    = local.common_tags
}