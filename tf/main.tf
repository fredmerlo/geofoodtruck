provider "aws" {
  region = "us-east-1"
}

resource "aws_kms_key" "geofoodtruck_kms_key" {
  description = "KMS key for GeoFoodTruck"
  is_enabled  = true

  key_usage   = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"

   policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
          "Sid": "Enable IAM User Permissions",
          "Effect": "Allow",
          "Principal": {
              "AWS": "arn:aws:iam::900357929763:root"
          },
          "Action": "kms:*",
          "Resource": "*"
      },
      {
        Effect   = "Allow",
        Principal = {
          "Service": "cloudfront.amazonaws.com"
        },
        Action   = [
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = "${aws_s3_bucket.geofoodtruck_app_bucket.arn}/*",
        Condition = {
          "StringEquals": {
            "AWS:SourceArn": "${aws_cloudfront_distribution.geofoodtruck_app_distribution.arn}"
          }
        }
      }
    ]
  })

  tags = {
    Name = "geofoodtruck-kms-key"
  }
}

resource "aws_s3_bucket" "geofoodtruck_app_bucket" {
  bucket = "geofoodtruck-app-bucket"
}

resource "aws_s3_bucket_ownership_controls" "geofoodtruck_s3_bucket_ownership_cotrols" {
  bucket = aws_s3_bucket.geofoodtruck_app_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "geofoodtruck_s3_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.geofoodtruck_app_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.geofoodtruck_kms_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_policy" "geofoodtruck_app_bucket_policy" {
  bucket = aws_s3_bucket.geofoodtruck_app_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Principal = {
          "Service": "cloudfront.amazonaws.com"
        },
        Action   = "s3:GetObject",
        Resource = "${aws_s3_bucket.geofoodtruck_app_bucket.arn}/*",
        Condition = {
          "StringEquals": {
            "AWS:SourceArn": "${aws_cloudfront_distribution.geofoodtruck_app_distribution.arn}"
          }
        }
      }
    ]
  })
}

resource "aws_cloudfront_origin_access_control" "geofoodtruck_origin_access_control" {
  name = "geofoodtruck-app-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior = "always"
  signing_protocol = "sigv4"
  description = "Origin Access Control for GeoFoodTruck app"
}

resource "aws_cloudfront_distribution" "geofoodtruck_app_distribution" {
  origin {
    domain_name              = aws_s3_bucket.geofoodtruck_app_bucket.bucket_regional_domain_name
    origin_id                = "S3-geofoodtruck-app-bucket"
    origin_access_control_id = aws_cloudfront_origin_access_control.geofoodtruck_origin_access_control.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-geofoodtruck-app-bucket"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  logging_config {
    include_cookies = false
    bucket          = "${aws_s3_bucket.geofoodtruck_app_bucket.bucket}.s3.amazonaws.com"
    prefix          = "log/"
  }
}

output "s3_bucket_name" {
  value = aws_s3_bucket.geofoodtruck_app_bucket.bucket
}

output "cloudfront_distribution_domain" {
  value = aws_cloudfront_distribution.geofoodtruck_app_distribution.domain_name
}
