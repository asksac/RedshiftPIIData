# create S3 bucket for data files

locals {
  customer_data_file      = "${path.module}/synth_data/data/customer_data.csv"
  account_data_file       = "${path.module}/synth_data/data/account_data.csv"
  pyaes_library           = "${path.module}/redshift_udf/bin/pyaes.zip"
}

resource "aws_s3_bucket" "data_files" {
  bucket                  = "${var.app_shortcode}-data-files-${local.account_id}"

  tags                    = local.common_tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_files_config" {
  bucket                  = aws_s3_bucket.data_files.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm       = "aws:kms"
    }
  }
}

data "aws_iam_policy_document" "data_files_bucket_policy" {
  statement {
    actions               = [ "s3:GetObject", "s3:PutObject", "s3:DeleteObject" ]
    resources             = [ "${aws_s3_bucket.data_files.arn}/*" ]

    principals {
      type                = "AWS"
      identifiers         = [ local.account_id ]
    }
  }

  statement {
    actions               = [ "s3:ListBucket" ]
    resources             = [ aws_s3_bucket.data_files.arn ]

    principals {
      type                = "AWS"
      identifiers         = [ local.account_id ]
    }
  }
}

resource "aws_s3_bucket_policy" "data_files" {
  bucket                  = aws_s3_bucket.data_files.id
  policy                  = data.aws_iam_policy_document.data_files_bucket_policy.json 
}

# customer file
resource "aws_s3_object" "upload_customer_data" {
  bucket                  = aws_s3_bucket.data_files.id
  key                     = "data/upload/customer_data.csv"
  source                  = local.customer_data_file
  #etag                    = filemd5(local.customer_data_file)
}

# account file 
resource "aws_s3_object" "upload_account_data" {
  bucket                  = aws_s3_bucket.data_files.id
  key                     = "data/upload/account_data.csv"
  source                  = local.account_data_file
  #etag                    = filemd5(local.account_data_file)
}

# pyaes.zip library
resource "aws_s3_object" "upload_pyaes" {
  bucket                  = aws_s3_bucket.data_files.id
  key                     = "library/pyaes.zip"
  source                  = local.pyaes_library
  #etag                    = filemd5(local.pyaes_library)
}
