output "kms_key_arn" {
  description = "ARN of the customer-managed KMS key"
  value       = aws_kms_key.geofoodtruck_kms_key.arn
}

output "geofoodtruck_ssm_parameter_value" {
  description = "Decrypted SSM parameter value for GeoFoodTruck API authentication"
  value       = data.aws_ssm_parameter.sfgov_geofoodtruck_aws_ssm_parameter.value
  sensitive   = true
}

output "app_bucket_name" {
  description = "Name of the application S3 bucket"
  value       = aws_s3_bucket.geofoodtruck_app_bucket.bucket
}

output "app_bucket_arn" {
  description = "ARN of the application S3 bucket"
  value       = aws_s3_bucket.geofoodtruck_app_bucket.arn
}

output "app_bucket_regional_domain_name" {
  description = "Regional domain name of the application S3 bucket"
  value       = aws_s3_bucket.geofoodtruck_app_bucket.bucket_regional_domain_name
}

output "log_bucket_name" {
  description = "Name of the log S3 bucket"
  value       = aws_s3_bucket.geofoodtruck_log_bucket.bucket
}

output "log_bucket_arn" {
  description = "ARN of the log S3 bucket"
  value       = aws_s3_bucket.geofoodtruck_log_bucket.arn
}

output "log_bucket_regional_domain_name" {
  description = "Regional domain name of the log S3 bucket"
  value       = aws_s3_bucket.geofoodtruck_log_bucket.bucket_regional_domain_name
}

output "web_acl_arn" {
  description = "ARN of the WAFv2 Web ACL for CloudFront association"
  value       = aws_wafv2_web_acl.geofoodtruck_waf_web_acl.arn
}

output "cloudfront_distribution_domain" {
  value = aws_cloudfront_distribution.geofoodtruck_app_distribution.domain_name
}
