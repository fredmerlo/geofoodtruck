provider "aws" {
  region = "us-east-1"
}

data "aws_iam_policy" "aws_key_management_service_power_user" {
  arn = "arn:aws:iam::aws:policy/AWSKeyManagementServicePowerUser"
}

resource "aws_iam_role" "aws_iam_role_geofoodtruck_kms_admin_role" {
  name                = "GeoFoodTruckKmsAdmin"

  assume_role_policy  = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal: {
          "AWS": "${var.aws_account_id}"
        },
      },
    ]
  })

  managed_policy_arns = [data.aws_iam_policy.aws_key_management_service_power_user.arn]
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
        Sid = "Enable IAM User Permissions",
        Effect = "Allow",
        Principal = {
            "AWS": [
              aws_iam_role.aws_iam_role_geofoodtruck_kms_admin_role.arn,
              "arn:aws:iam::${var.aws_account_id}:root"
            ]
        },
        Action = "kms:*",
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Principal = {
          "Service": "cloudfront.amazonaws.com"
        },
        Action   = [
          "kms:Encrypt",
          "kms:Decrypt"
        ],
        Resource = "*"
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

resource "aws_s3_bucket_server_side_encryption_configuration" "geofoodtruck_s3_bucket_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.geofoodtruck_app_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.geofoodtruck_kms_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_cloudfront_origin_access_control" "geofoodtruck_origin_access_control" {
  name = "geofoodtruck-app-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior = "always"
  signing_protocol = "sigv4"
  description = "Origin Access Control for GeoFoodTruck app"
}

data "aws_cloudfront_cache_policy" "geofoodtruck_cloudfront_cache_policy" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_origin_request_policy" "geofoodtruck_cloudfront_origin_request_policy" {
  name = "Managed-CORS-S3Origin"
}

resource "aws_cloudfront_response_headers_policy" "geofoodtruck_cloudfront_response_header_policy" {
  name = "Custom-GeoFoodTruck-CORS-With-Preflight"
  comment = "Custom CORS with Preflight Response Policy for GeoFoodTruck"

  cors_config {
    access_control_allow_credentials = false

    access_control_allow_headers {
      items = ["*"]
    }

    access_control_allow_methods {
      items = ["GET", "HEAD", "PUT", "POST", "PATCH", "DELETE", "OPTIONS"]
    }

    access_control_allow_origins {
      items = ["*"]
    }

    access_control_expose_headers {
      items = ["*"]
    }

    origin_override = false
  }

  remove_headers_config {
    items {
      header = "Server"
    }

    items {
      header = "X-Amz-Server-Side-Encryption"
    }

    items {
      header = "X-Amz-Server-Side-Encryption-Aws-Kms-Key-Id"
    }
  } 

}

data "aws_cloudfront_response_headers_policy" "sfgov_geofoodtruck_cloudfront_response_header_policy" {
  name = "Managed-CORS-With-Preflight"
}

data "aws_cloudfront_cache_policy" "sfgov_geofoodtruck_cloudfront_cache_policy" {
  name = "Managed-CachingDisabled"
}
 
resource "aws_cloudfront_origin_request_policy" "sfgov_geofoodtruck_cloudfront_origin_request_policy" {
  name    = "Custom-DataSFGov-CORS-Origin"
  comment = "Custom CORS Origin Request Policy for SFGov Data API"

  cookies_config {
    cookie_behavior = "none"
  }

  headers_config {
    header_behavior = "whitelist"
    headers {
      items = ["origin"]
    }
  }

  query_strings_config {
    query_string_behavior = "all"
  }
}

data "aws_ssm_parameter" "sfgov_geofoodtruck_aws_ssm_parameter" {
  name = "/geofoodtruck/sfgovkey"
  with_decryption = true
}

resource "aws_cloudfront_distribution" "geofoodtruck_app_distribution" {
  origin {
    domain_name              = aws_s3_bucket.geofoodtruck_app_bucket.bucket_regional_domain_name
    origin_id                = aws_s3_bucket.geofoodtruck_app_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.geofoodtruck_origin_access_control.id
  }

  origin {
    domain_name              = "data.sfgov.org"
    origin_id                = "data.sfgov.org"
    
    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "https-only"
      origin_ssl_protocols     = ["TLSv1.2"]
    }
    
    custom_header {
      name  = "X-App-Token"
      value = data.aws_ssm_parameter.sfgov_geofoodtruck_aws_ssm_parameter.value
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  ordered_cache_behavior {
    path_pattern     = "/resource/rqzj-sfat.json"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    compress         = true

    cache_policy_id  = data.aws_cloudfront_cache_policy.sfgov_geofoodtruck_cloudfront_cache_policy.id
    origin_request_policy_id = aws_cloudfront_origin_request_policy.sfgov_geofoodtruck_cloudfront_origin_request_policy.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.sfgov_geofoodtruck_cloudfront_response_header_policy.id

    target_origin_id = "data.sfgov.org"

    viewer_protocol_policy = "https-only"
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    compress         = true

    cache_policy_id  = data.aws_cloudfront_cache_policy.geofoodtruck_cloudfront_cache_policy.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.geofoodtruck_cloudfront_origin_request_policy.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.geofoodtruck_cloudfront_response_header_policy.id

    target_origin_id = aws_s3_bucket.geofoodtruck_app_bucket.bucket_regional_domain_name

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

  web_acl_id = aws_wafv2_web_acl.geofoodtruck_waf_web_acl.arn
}

resource "aws_s3_bucket_policy" "geofoodtruck_app_bucket_policy" {
  depends_on = [aws_cloudfront_distribution.geofoodtruck_app_distribution]
  bucket = aws_s3_bucket.geofoodtruck_app_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Principal = {
          "Service": "cloudfront.amazonaws.com"
        },
        Action   = [
          "s3:GetObject"
        ],
        Resource = [
          "${aws_s3_bucket.geofoodtruck_app_bucket.arn}/*"
        ],
        Condition = {
          "StringEquals": {
            "AWS:SourceArn": "${aws_cloudfront_distribution.geofoodtruck_app_distribution.arn}"
          }
        }
      }
    ]
  })
}

resource "local_file" "geofoodtruck_config_json" {
  filename     = "${var.app_build_dir}/config.json"
  content      = jsonencode({
    distribution = "${aws_cloudfront_distribution.geofoodtruck_app_distribution.domain_name}"
  })
}

resource "aws_s3_bucket_object" "aws_s3_object_geofoodtruck_config_json" {
  bucket       = aws_s3_bucket.geofoodtruck_app_bucket.id
  key          = local_file.geofoodtruck_config_json.filename
  source       = local_file.geofoodtruck_config_json.filename
  content_type = "application/json"
  etag         = filemd5("${var.app_build_dir}/${local_file.geofoodtruck_config_json.filename}")
}

resource "aws_s3_object" "app_files" {
  depends_on   = [aws_cloudfront_distribution.geofoodtruck_app_distribution]
  for_each = { for file in local.app_build_files : file => file }
  bucket       = aws_s3_bucket.geofoodtruck_app_bucket.id
  key          = each.value
  source       = "${var.app_build_dir}/${each.value}"
  content_type = lookup(
    local.content_types,
    element(split(".", each.value), length(split(".", each.value)) - 1),
    "application/octet-stream"
  )
  etag         = filemd5("${var.app_build_dir}/${each.value}")
}

output "s3_bucket_name" {
  value = aws_s3_bucket.geofoodtruck_app_bucket.bucket
}

output "cloudfront_distribution_domain" {
  value = aws_cloudfront_distribution.geofoodtruck_app_distribution.domain_name
}
