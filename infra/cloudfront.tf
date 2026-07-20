# CloudFront Distribution Resources
#
# This file contains all CloudFront-related resources and data sources
# for the GeoFoodTruck application, including:
# - Origin Access Control (OAC)
# - Managed policy data sources (cache, origin request, response headers)
# - Custom origin request policy
# - Custom response headers policy
# - CloudFront distribution
# - App bucket policy for OAC access
#
# Provider, terraform block, aws_caller_identity, and aws_region are
# managed in main.tf and are NOT declared here.

data "aws_cloudfront_cache_policy" "geofoodtruck_cloudfront_cache_policy" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "sfgov_geofoodtruck_cloudfront_cache_policy" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "geofoodtruck_cloudfront_origin_request_policy" {
  name = "Managed-CORS-S3Origin"
}

data "aws_cloudfront_response_headers_policy" "sfgov_geofoodtruck_cloudfront_response_header_policy" {
  name = "Managed-CORS-With-Preflight"
}

resource "aws_cloudfront_origin_access_control" "geofoodtruck_origin_access_control" {
  name                              = "geofoodtruck-app-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
  description                       = "Origin Access Control for GeoFoodTruck app"
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

resource "aws_cloudfront_response_headers_policy" "geofoodtruck_cloudfront_response_header_policy" {
  name    = "Custom-GeoFoodTruck-CORS-With-Preflight"
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

  security_headers_config {
    strict_transport_security {
      access_control_max_age_sec = 31536000
      override                   = true
    }
  }
}

resource "aws_cloudfront_distribution" "geofoodtruck_app_distribution" {
  origin {
    domain_name              = aws_s3_bucket.geofoodtruck_app_bucket.bucket_regional_domain_name
    origin_id                = aws_s3_bucket.geofoodtruck_app_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.geofoodtruck_origin_access_control.id
  }

  origin {
    domain_name = "data.sfgov.org"
    origin_id   = "data.sfgov.org"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "X-App-Token"
      value = data.aws_ssm_parameter.sfgov_geofoodtruck_aws_ssm_parameter.value
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.geofoodtruck_log_bucket.bucket_regional_domain_name
  }

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true

    cache_policy_id            = data.aws_cloudfront_cache_policy.geofoodtruck_cloudfront_cache_policy.id
    origin_request_policy_id   = data.aws_cloudfront_origin_request_policy.geofoodtruck_cloudfront_origin_request_policy.id
    response_headers_policy_id = aws_cloudfront_response_headers_policy.geofoodtruck_cloudfront_response_header_policy.id

    target_origin_id       = aws_s3_bucket.geofoodtruck_app_bucket.bucket_regional_domain_name
    viewer_protocol_policy = "redirect-to-https"
  }

  ordered_cache_behavior {
    path_pattern    = "/resource/rqzj-sfat.json"
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD", "OPTIONS"]
    compress        = true

    cache_policy_id            = data.aws_cloudfront_cache_policy.sfgov_geofoodtruck_cloudfront_cache_policy.id
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.sfgov_geofoodtruck_cloudfront_origin_request_policy.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.sfgov_geofoodtruck_cloudfront_response_header_policy.id

    target_origin_id       = "data.sfgov.org"
    viewer_protocol_policy = "https-only"
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
  bucket     = aws_s3_bucket.geofoodtruck_app_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = ["s3:GetObject"]
        Resource  = ["${aws_s3_bucket.geofoodtruck_app_bucket.arn}/*"]
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.geofoodtruck_app_distribution.arn
          }
        }
      }
    ]
  })
}
