
resource "aws_secretsmanager_secret" "key_secret" {
  name                    = "${var.app_shortcode}/redshift/encr-key"
}

resource "aws_secretsmanager_secret_policy" "key_secret_policy" {
  secret_arn              = aws_secretsmanager_secret.key_secret.arn

  policy = jsonencode({
    Version               = "2012-10-17"
    Statement             = [
      {
        Sid               = "EnableGetSecretAccess"
        Effect            = "Allow"
        Principal         = {
          AWS             = aws_iam_role.lambda_exec_role.arn
        }
        Action            = "secretsmanager:GetSecretValue"
        Resource          = [ aws_secretsmanager_secret.key_secret.arn ]
      }
    ]
  })

}

resource "random_password" "key_material" {
  length                  = 32
  special                 = true
}

resource "aws_secretsmanager_secret_version" "key_secret_data" {
  secret_id               = aws_secretsmanager_secret.key_secret.arn
  secret_string           = random_password.key_material.result
}
