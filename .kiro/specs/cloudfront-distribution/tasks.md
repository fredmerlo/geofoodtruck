# Implementation Plan: CloudFront Distribution

## Overview

This plan implements the AWS CloudFront distribution Terraform configuration in the existing `infra` directory. Tasks are ordered by dependency: file creation first, then custom policies and OAC, then the distribution resource that references all of them, and finally outputs. This feature does NOT create provider configuration, `aws_caller_identity`, or `aws_region` data sources — those are already managed in `infra/main.tf`. The implementation language is Terraform HCL.

## Tasks

- [x] 1. Create CloudFront configuration file
  - [x] 1.1 Create `infra/cloudfront.tf` for CloudFront resources
    - Create the file that will hold all CloudFront-related resources and data sources
    - Do NOT create `infra/main.tf` or add provider/required_providers — these exist already
    - Do NOT add `aws_caller_identity` or `aws_region` data sources — these are managed in `infra/main.tf`
    - _Requirements: 18.1, 18.2, 18.3, 18.4_

- [x] 2. Reference existing SSM parameter data source
  - [x] 2.1 Verify `data.aws_ssm_parameter.sfgov_geofoodtruck_aws_ssm_parameter` is available from `infra/ssm.tf`
    - Confirm the SSM parameter data source is defined in `infra/ssm.tf` by the ssm-parameter-store-retrieval feature
    - Do NOT create or redeclare the `data "aws_ssm_parameter"` in `infra/cloudfront.tf` — reference it directly via `data.aws_ssm_parameter.sfgov_geofoodtruck_aws_ssm_parameter.value`
    - _Requirements: 2.1, 2.2_

- [x] 3. Add managed cache and request/response policy data sources
  - [x] 3.1 Add managed policy data sources to `infra/cloudfront.tf`
    - Define `data "aws_cloudfront_cache_policy" "geofoodtruck_cloudfront_cache_policy"` with `name = "Managed-CachingOptimized"`
    - Define `data "aws_cloudfront_cache_policy" "sfgov_geofoodtruck_cloudfront_cache_policy"` with `name = "Managed-CachingDisabled"`
    - Define `data "aws_cloudfront_origin_request_policy" "geofoodtruck_cloudfront_origin_request_policy"` with `name = "Managed-CORS-S3Origin"`
    - Define `data "aws_cloudfront_response_headers_policy" "sfgov_geofoodtruck_cloudfront_response_header_policy"` with `name = "Managed-CORS-With-Preflight"`
    - _Requirements: 11.1, 11.2, 12.1, 13.1_

- [x] 4. Add Origin Access Control resource
  - [x] 4.1 Add `aws_cloudfront_origin_access_control` resource to `infra/cloudfront.tf`
    - Define `resource "aws_cloudfront_origin_access_control" "geofoodtruck_origin_access_control"` with `name = "geofoodtruck-app-oac"`, `origin_access_control_origin_type = "s3"`, `signing_behavior = "always"`, `signing_protocol = "sigv4"`, and `description = "Origin Access Control for GeoFoodTruck app"`
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6_

- [x] 5. Add custom origin request policy for SFGov
  - [x] 5.1 Add `aws_cloudfront_origin_request_policy` resource to `infra/cloudfront.tf`
    - Define `resource "aws_cloudfront_origin_request_policy" "sfgov_geofoodtruck_cloudfront_origin_request_policy"` with `name = "Custom-DataSFGov-CORS-Origin"`, `comment = "Custom CORS Origin Request Policy for SFGov Data API"`, `cookies_config` with `cookie_behavior = "none"`, `headers_config` with `header_behavior = "whitelist"` and items `["origin"]`, `query_strings_config` with `query_string_behavior = "all"`
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6_

- [x] 6. Add custom response headers policy
  - [x] 6.1 Add `aws_cloudfront_response_headers_policy` resource to `infra/cloudfront.tf`
    - Define `resource "aws_cloudfront_response_headers_policy" "geofoodtruck_cloudfront_response_header_policy"` with `name = "Custom-GeoFoodTruck-CORS-With-Preflight"` and `comment = "Custom CORS with Preflight Response Policy for GeoFoodTruck"`
    - Configure `cors_config` with `access_control_allow_credentials = false`, allow headers `["*"]`, allow methods `["GET", "HEAD", "PUT", "POST", "PATCH", "DELETE", "OPTIONS"]`, allow origins `["*"]`, expose headers `["*"]`, `origin_override = false`
    - Configure `remove_headers_config` to remove `Server`, `X-Amz-Server-Side-Encryption`, `X-Amz-Server-Side-Encryption-Aws-Kms-Key-Id`
    - Configure `security_headers_config` with `strict_transport_security` setting `access_control_max_age_sec = 31536000` and `override = true`
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.7, 10.8, 10.9, 10.10, 10.11_

- [x] 7. Add CloudFront distribution resource
  - [x] 7.1 Add `aws_cloudfront_distribution` resource to `infra/cloudfront.tf`
    - Define `resource "aws_cloudfront_distribution" "geofoodtruck_app_distribution"`
    - Configure S3 origin block with `domain_name` and `origin_id` referencing App_Bucket `bucket_regional_domain_name`, and `origin_access_control_id` referencing the OAC resource
    - Configure SFGov custom origin block with `domain_name = "data.sfgov.org"`, `origin_id = "data.sfgov.org"`, `custom_origin_config` (https-only, TLSv1.2), and `custom_header` for X-App-Token from SSM parameter
    - Set `enabled = true`, `is_ipv6_enabled = true`, `default_root_object = "index.html"`
    - Configure `logging_config` with Log_Bucket domain and `include_cookies = false`
    - Configure `default_cache_behavior` targeting S3 origin with GET/HEAD methods, compress, CachingOptimized cache policy, CORS-S3Origin request policy, custom response headers policy, `viewer_protocol_policy = "redirect-to-https"`
    - Configure `ordered_cache_behavior` for path `/resource/rqzj-sfat.json` targeting SFGov origin with GET/HEAD/OPTIONS methods, compress, CachingDisabled cache policy, custom origin request policy, CORS-With-Preflight response policy, `viewer_protocol_policy = "https-only"`
    - Configure `restrictions` with `geo_restriction` type `none`
    - Configure `viewer_certificate` with `cloudfront_default_certificate = true`
    - Set `web_acl_id` to WAF Web ACL ARN
    - _Requirements: 3.1, 3.2, 3.3, 4.1, 4.2, 4.3, 4.4, 5.1, 5.2, 5.3, 6.1, 6.2, 6.3, 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 7.8, 7.9, 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7, 8.8, 8.9, 8.10, 14.1, 14.2, 15.1, 15.2, 16.1_

- [x] 8. Add App Bucket policy for CloudFront OAC access
  - [x] 8.1 Add `aws_s3_bucket_policy.geofoodtruck_app_bucket_policy` resource to `infra/cloudfront.tf`
    - Set `bucket = aws_s3_bucket.geofoodtruck_app_bucket.id`
    - Define policy using `jsonencode` with single Allow statement: Principal Service `cloudfront.amazonaws.com`, Action `s3:GetObject`, Resource `${aws_s3_bucket.geofoodtruck_app_bucket.arn}/*`
    - Include `Condition.StringEquals["AWS:SourceArn"]` referencing `aws_cloudfront_distribution.geofoodtruck_app_distribution.arn`
    - Add `depends_on = [aws_cloudfront_distribution.geofoodtruck_app_distribution]`
    - _Requirements: 19.1, 19.2, 19.3, 19.4_

- [x] 9. Create outputs file
  - [x] 9.1 Create `infra/outputs.tf` with distribution domain name output
    - Define `output "cloudfront_distribution_domain"` with `value = aws_cloudfront_distribution.geofoodtruck_app_distribution.domain_name`
    - _Requirements: 17.1_

- [x] 10. Validation checkpoint
  - Ensure `terraform fmt -check` passes on `infra/` directory
  - Ensure `terraform validate` passes in the `infra/` directory
  - Verify all requirement references are satisfied
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- This feature adds to the EXISTING `infra/` module — it does not create `main.tf` or provider configuration.
- `data "aws_caller_identity" "current"`, `data "aws_region" "current"`, `required_providers`, and `provider "aws"` are already declared in `infra/main.tf` and must NOT be redeclared by this feature.
- The distribution references external resources (S3 buckets, WAF Web ACL) that must exist before `terraform apply`.
- The SSM parameter `/geofoodtruck/sfgovkey` must be pre-provisioned in Parameter Store before plan/apply.
- No property-based tests are generated since this is IaC; correctness is validated via `terraform validate`, `terraform plan` JSON assertions, and Checkov security scanning.
- Tasks are ordered by dependency: file creation → policies/OAC → distribution → outputs.
- The SSM parameter data source (`data.aws_ssm_parameter.sfgov_geofoodtruck_aws_ssm_parameter`) is defined in `infra/ssm.tf` by the ssm-parameter-store-retrieval feature and must NOT be redefined by this feature.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["2.1", "3.1", "4.1"] },
    { "id": 2, "tasks": ["5.1", "6.1"] },
    { "id": 3, "tasks": ["7.1"] },
    { "id": 4, "tasks": ["8.1"] },
    { "id": 5, "tasks": ["9.1"] }
  ]
}
```
