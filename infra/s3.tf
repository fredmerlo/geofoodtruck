# S3 bucket resources for geofoodtruck application and logging

resource "aws_s3_bucket" "geofoodtruck_app_bucket" {
  bucket = "geofoodtruck-app-bucket"

  tags = {
    Name = "geofoodtruck-app-bucket"
  }
}

resource "aws_s3_bucket_public_access_block" "geofoodtruck_s3_bucket_public_access_block" {
  bucket = aws_s3_bucket.geofoodtruck_app_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "geofoodtruck_s3_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.geofoodtruck_app_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.geofoodtruck_kms_key.arn
    }
  }
}

resource "aws_s3_bucket" "geofoodtruck_log_bucket" {
  bucket = "geofoodtruck-log-bucket"

  tags = {
    Name = "geofoodtruck-log-bucket"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "geofoodtruck_s3_bucket_log_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.geofoodtruck_log_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.geofoodtruck_kms_key.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "geofoodtruck_s3_bucket_log_public_access_block" {
  bucket = aws_s3_bucket.geofoodtruck_log_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#checkov:skip=CKV2_AWS_65:CloudFront Standard Logging requires S3 log bucket to have ACLs enabled
resource "aws_s3_bucket_ownership_controls" "geofoodtruck_s3_bucket_log_ownership_controls" {
  bucket = aws_s3_bucket.geofoodtruck_log_bucket.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "geofoodtruck_log_bucket_acl" {
  bucket = aws_s3_bucket.geofoodtruck_log_bucket.id
  acl    = "private"

  depends_on = [aws_s3_bucket_ownership_controls.geofoodtruck_s3_bucket_log_ownership_controls]
}

resource "aws_s3_object" "app_files" {
  for_each = { for file in local.app_build_files : file => file }

  bucket       = aws_s3_bucket.geofoodtruck_app_bucket.id
  key          = each.value
  source       = "${var.app_build_dir}/${each.value}"
  content_type = lookup(local.content_types, element(split(".", each.value), length(split(".", each.value)) - 1), "application/octet-stream")
  etag         = filemd5("${var.app_build_dir}/${each.value}")
}
