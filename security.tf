# create security groups

resource "aws_security_group" "rsdb_sg" {
  name                        = "${var.app_shortcode}_rsdb_sg"
  vpc_id                      = data.aws_vpc.rsdb.id

  ingress {
    cidr_blocks               = [ data.aws_vpc.rsdb.cidr_block, data.aws_vpc.client.cidr_block ]
    from_port                 = var.rsdb_port
    to_port                   = var.rsdb_port
    protocol                  = "tcp"
  }

  egress {
    from_port                 = 0
    to_port                   = 0
    protocol                  = -1
    self                      = true
  }

  tags                        = local.common_tags
}

resource "aws_security_group" "client_sg" {
  name_prefix             = "${var.app_shortcode}_client_app_sg"
  vpc_id                  = data.aws_vpc.client.id

  ingress {
    cidr_blocks           = var.client_ssh_cidr_blocks
    from_port             = 22
    to_port               = 22
    protocol              = "tcp"
  }

  # terraform removes the default egress rule, so lets add it back
  egress {
    from_port             = 0
    to_port               = 0
    protocol              = "-1"
    cidr_blocks           = [ "0.0.0.0/0" ]
  }
}


# 
# Create an IAM role for Redshift cluster to assume, to run rsql commands such as COPY, UNLOAD and CREATE EXTERNAL FUNCTION

resource "aws_iam_role" "redshift_assume_role" {
  name                = "${var.app_shortcode}_redshift_assume_role"

  assume_role_policy  = jsonencode({
    Version           = "2012-10-17",
    Statement         = [
      {
        Action        = [ "sts:AssumeRole" ]
        Principal     = {
          Service     = "redshift.amazonaws.com"
        }
        Effect        = "Allow"
        Sid           = "RedshiftAssumeRolePolicy"
      }
    ]
  })
}

resource "aws_iam_policy" "redshift_permissions_policy" {
  name        = "${var.app_shortcode}_redshift_permissions_policy"
  path        = "/"
  description = "IAM policy with minimum permissions for Redshift cluster"

  policy = jsonencode({
    Version         = "2012-10-17"
    Statement       = [
      {
        Action      = [
          "s3:*",
        ]
        Resource    = "arn:aws:s3:::*${local.account_id}*"
        Effect      = "Allow"
        Sid         = "AllowS3Access"
      }, 
      {
        Action      = [
          "lambda:InvokeFunction",
        ]
        Resource    = "arn:aws:lambda:*:*:function:*"
        Effect      = "Allow"
        Sid         = "AllowLambdaAccess"
      }, 
    ]
  })
}

resource "aws_iam_role_policy_attachment" "redshift_assume_role_policy" {
  role       = aws_iam_role.redshift_assume_role.name
  policy_arn = aws_iam_policy.redshift_permissions_policy.arn
}

# -----
# IAM role for EC2 instance

resource "aws_iam_role" "ec2_exec_role" {
  name                      = "${var.app_shortcode}_ec2_exec_role" 
  path                      = "/"
  assume_role_policy        = jsonencode({
    Version                 = "2012-10-17",
    Statement               = [
      {  
        Action              = [ "sts:AssumeRole" ]
        Principal           = {
          Service           = "ec2.amazonaws.com"
        } 
        Effect              = "Allow"
        Sid                 = "EC2AssumeRolePolicy"
      }
    ]
  })
}

resource "aws_iam_policy" "ec2_exec_policy" {
  name                      = "${var.app_shortcode}_ec2_exec_policy"
  path                      = "/"
  description               = "IAM policy to grant required permissions to EC2"

  policy                    = jsonencode({
    Version         = "2012-10-17"
    Statement       = [
      {
        Action      = [
          "ec2:*",
        ]
        Resource    = "*"
        Effect      = "Allow"
        Sid         = "AllowFullEC2Access"
      }, 
      {
        "Effect": "Allow",
        "Action": [
          "kms:Encrypt", 
          "kms:Decrypt", 
          "kms:CreateGrant", 
          "kms:DescribeKey", 
          "kms:ListKeys", 
        ]
        Resource    = "*"
        Effect      = "Allow"
        Sid         = "AllowKMSAccess"
      }, 
      {
        Action      = [
          "logs:CreateLogGroup",
        ]
        Resource    = "arn:aws:logs:${var.aws_region}:${local.account_id}:*"
        Effect      = "Allow"
        Sid         = "AllowCloudWatchLogsAccess"
      }, 
      {
        Action      = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource    = "arn:aws:logs:${var.aws_region}:${local.account_id}:log-group:*:*"
        Effect      = "Allow"
        Sid         = "AllowCloudWatchPutLogEvents"
      }, 
      {
        Action      = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
        ]
        Resource    = "arn:aws:s3:::*"
        Effect      = "Allow"
        Sid         = "AllowS3ReadWriteAccess"
      }, 
      {
        Action      = [
          "sns:Publish",
        ]
        Resource    = "arn:aws:sns:${var.aws_region}:${local.account_id}:*"
        Effect      = "Allow"
        Sid         = "AllowSNSPublishAccess"
      }, 
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_exec_policy_attachment" {
  role                      = aws_iam_role.ec2_exec_role.name
  policy_arn                = aws_iam_policy.ec2_exec_policy.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name                      = "${var.app_shortcode}_ec2_instance_profile"
  role                      = aws_iam_role.ec2_exec_role.name
}
