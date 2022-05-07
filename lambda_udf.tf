#
# This script performs the following steps: 
# 1. Creates a CloudWatch Log group  for Lambda function to write logs to
# 2. Creates a ZIP pacakge from Lambda source file(s)
# 3. Creates an IAM execution role for Lambda
# 4. Creates a Lambda function resource using local ZIP file as source
#

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name                    = "/aws/lambda/${var.lambda_name}"
  retention_in_days       = 7 
}

data "archive_file" "lambda_archive" {
  source_dir              = "${path.module}/redshift_udf/src/get_key_lambda"
  output_path             = "${path.module}/redshift_udf/dist/GetKeyLambda.zip"
  type                    = "zip"
}

resource "aws_lambda_function" "lambda_func" {
  function_name           = var.lambda_name 

  handler                 = "main.lambda_handler"
  role                    = aws_iam_role.lambda_exec_role.arn
  runtime                 = "python3.8"
  timeout                 = 60

  filename                = data.archive_file.lambda_archive.output_path
  source_code_hash        = data.archive_file.lambda_archive.output_base64sha256

  environment {
    variables             = {
      DEFAULT_KEY_NAME    = aws_secretsmanager_secret.key_secret.name
    }
  }

  tags                    = local.common_tags
}

resource "aws_lambda_alias" "lambda_latest" {
  name                    = "${var.lambda_name}-Latest"
  description             = "Alias for latest Lambda version"
  function_name           = aws_lambda_function.lambda_func.function_name
  function_version        = "$LATEST"
}

# Create Lambda execution IAM role, giving permissions to access other AWS services

resource "aws_iam_role" "lambda_exec_role" {
  name                    = "${var.app_shortcode}_Lambda_Exec_Role"
  assume_role_policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
      {
      "Action": [
        "sts:AssumeRole"
      ],
      "Principal": {
          "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": "LambdaAssumeRolePolicy"
      }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_policy" {
  name                    = "${var.app_shortcode}_Lambda_Policy"
  path                    = "/"
  description             = "IAM policy with minimum permissions for ${var.lambda_name} Lambda function"

  policy = jsonencode({
    Version               = "2012-10-17"
    Statement             = [
      {
        Action            = [
          "logs:CreateLogGroup",
        ]
        Resource          = "arn:aws:logs:*:*:log-group:/aws/lambda/${var.lambda_name}"
        Effect            = "Allow"
        Sid               = "AllowCloudWatchLogsAccess"
      }, 
      {
        Action            = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource          = "arn:aws:logs:*:*:log-group:/aws/lambda/${var.lambda_name}:*"
        Effect            = "Allow"
        Sid               = "AllowCloudWatchPutLogEvents"
      }, 
      {
        Action            = [
          "secretsmanager:GetSecretValue",
        ]
        Resource          = "*"
        Effect            = "Allow"
        Sid               = "AllowKeyValueAccess"
      }, 
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_exec_policy" {
  role                    = aws_iam_role.lambda_exec_role.name
  policy_arn              = aws_iam_policy.lambda_policy.arn
}
