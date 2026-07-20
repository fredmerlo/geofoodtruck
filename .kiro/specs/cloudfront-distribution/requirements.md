# Requirements Document

## Introduction

This document specifies the requirements for an AWS CloudFront distribution defined in Terraform HCL for the GeoFoodTruck application. The distribution serves static React build assets from an S3 origin using Origin Access Control (OAC) and proxies API requests to the SFGov Data API through a custom origin with an authenticated API token. The configuration includes custom cache policies, origin request policies, response headers policies (CORS and security), WAF integration, and access logging to an S3 log bucket. The Terraform configuration will reside in the `infra` directory at the project root.

## Glossary

- **CF_Module**: The Terraform HCL configuration in the `infra` directory that defines the CloudFront distribution and associated resources.
- **Distribution**: The `aws_cloudfront_distribution` resource (`geofoodtruck_app_distribution`) that serves the GeoFoodTruck application content.
- **S3_Origin**: The CloudFront origin pointing to the App_Bucket's regional domain name, authenticated via OAC with SigV4 signing.
- **SFGov_Origin**: The CloudFront custom origin pointing to `data.sfgov.org` for proxying SFGov Data API requests.
- **OAC**: The `aws_cloudfront_origin_access_control` resource (`geofoodtruck_origin_access_control`) that enables SigV4 authentication between CloudFront and S3.
- **App_Bucket**: The S3 bucket (`geofoodtruck-app-bucket`) that hosts the React application static assets.
- **Log_Bucket**: The S3 bucket (`geofoodtruck-log-bucket`) that stores CloudFront distribution access logs.
- **SSM_Parameter**: The AWS Systems Manager Parameter Store entry at path `/geofoodtruck/sfgovkey` containing the SFGov API token.
- **Custom_Response_Headers_Policy**: The `aws_cloudfront_response_headers_policy` resource (`Custom-GeoFoodTruck-CORS-With-Preflight`) that applies CORS, security, and header removal rules to the default behavior.
- **Custom_Origin_Request_Policy**: The `aws_cloudfront_origin_request_policy` resource (`Custom-DataSFGov-CORS-Origin`) that forwards origin headers and query strings to the SFGov API.
- **WAF_Web_ACL**: The AWS WAFv2 Web ACL resource that provides firewall protection for the distribution, referenced by ARN.

## Requirements

### Requirement 1: Origin Access Control Resource

**User Story:** As a cloud engineer, I want an Origin Access Control resource defined for the S3 origin, so that CloudFront authenticates requests to the App_Bucket using SigV4 signing without requiring public bucket access.

#### Acceptance Criteria

1. THE CF_Module SHALL define an `aws_cloudfront_origin_access_control` resource with the Terraform identifier `geofoodtruck_origin_access_control`.
2. THE CF_Module SHALL set the `name` argument to `geofoodtruck-app-oac`.
3. THE CF_Module SHALL set the `origin_access_control_origin_type` argument to `s3`.
4. THE CF_Module SHALL set the `signing_behavior` argument to `always`.
5. THE CF_Module SHALL set the `signing_protocol` argument to `sigv4`.
6. THE CF_Module SHALL set the `description` argument to `Origin Access Control for GeoFoodTruck app`.

### Requirement 2: SSM Parameter Data Source Reference

**User Story:** As a cloud engineer, I want the SFGov API token retrieved from AWS Systems Manager Parameter Store, so that the CloudFront custom origin can authenticate with the SFGov Data API without hardcoding secrets in the Terraform configuration.

#### Acceptance Criteria

1. THE CF_Module SHALL reference the existing `data.aws_ssm_parameter.sfgov_geofoodtruck_aws_ssm_parameter` data source defined in `infra/ssm.tf` by the ssm-parameter-store-retrieval feature — this feature SHALL NOT define its own SSM parameter data source.
2. THE CF_Module SHALL use `data.aws_ssm_parameter.sfgov_geofoodtruck_aws_ssm_parameter.value` as the value for the X-App-Token custom header on the SFGov origin.

### Requirement 3: CloudFront Distribution S3 Origin

**User Story:** As a cloud engineer, I want the CloudFront distribution to have an S3 origin for the App_Bucket, so that static application assets are served from the bucket through CloudFront with OAC authentication.

#### Acceptance Criteria

1. THE CF_Module SHALL define an `origin` block within the Distribution resource with `domain_name` set to the `bucket_regional_domain_name` attribute of the App_Bucket resource.
2. THE CF_Module SHALL set the `origin_id` of the S3_Origin to the `bucket_regional_domain_name` attribute of the App_Bucket resource.
3. THE CF_Module SHALL set the `origin_access_control_id` of the S3_Origin to the `id` attribute of the OAC resource.

### Requirement 4: CloudFront Distribution SFGov Custom Origin

**User Story:** As a cloud engineer, I want the CloudFront distribution to have a custom origin for the SFGov Data API, so that API requests are proxied through CloudFront with HTTPS and an authenticated API token header.

#### Acceptance Criteria

1. THE CF_Module SHALL define an `origin` block within the Distribution resource with `domain_name` set to `data.sfgov.org`.
2. THE CF_Module SHALL set the `origin_id` of the SFGov_Origin to `data.sfgov.org`.
3. THE CF_Module SHALL configure a `custom_origin_config` block with `http_port` set to `80`, `https_port` set to `443`, `origin_protocol_policy` set to `https-only`, and `origin_ssl_protocols` set to `["TLSv1.2"]`.
4. THE CF_Module SHALL configure a `custom_header` block on the SFGov_Origin with `name` set to `X-App-Token` and `value` set to the `value` attribute of the SSM_Parameter data source.

### Requirement 5: Distribution General Settings

**User Story:** As a cloud engineer, I want the CloudFront distribution configured with standard settings for IPv6, default root object, and enablement, so that the distribution is active and serves the React application's entry point by default.

#### Acceptance Criteria

1. THE CF_Module SHALL set the `enabled` argument of the Distribution resource to `true`.
2. THE CF_Module SHALL set the `is_ipv6_enabled` argument of the Distribution resource to `true`.
3. THE CF_Module SHALL set the `default_root_object` argument of the Distribution resource to `index.html`.

### Requirement 6: Distribution Logging Configuration

**User Story:** As a cloud engineer, I want the CloudFront distribution to log access requests to the Log_Bucket, so that access patterns are captured for auditing and analysis.

#### Acceptance Criteria

1. THE CF_Module SHALL define a `logging_config` block within the Distribution resource.
2. THE CF_Module SHALL set the `bucket` argument within `logging_config` to the `bucket_regional_domain_name` attribute of the Log_Bucket resource.
3. THE CF_Module SHALL set the `include_cookies` argument within `logging_config` to `false`.

### Requirement 7: Default Cache Behavior (S3 Origin)

**User Story:** As a cloud engineer, I want the default cache behavior to serve compressed S3 content with optimized caching, CORS support, and custom response headers, so that static assets are delivered efficiently with proper security and CORS headers.

#### Acceptance Criteria

1. THE CF_Module SHALL define a `default_cache_behavior` block within the Distribution resource.
2. THE CF_Module SHALL set `allowed_methods` to `["GET", "HEAD"]`.
3. THE CF_Module SHALL set `cached_methods` to `["GET", "HEAD"]`.
4. THE CF_Module SHALL set `compress` to `true`.
5. THE CF_Module SHALL set `cache_policy_id` to the `id` attribute of a `data.aws_cloudfront_cache_policy` data source with name `Managed-CachingOptimized`.
6. THE CF_Module SHALL set `origin_request_policy_id` to the `id` attribute of a `data.aws_cloudfront_origin_request_policy` data source with name `Managed-CORS-S3Origin`.
7. THE CF_Module SHALL set `response_headers_policy_id` to the `id` attribute of the Custom_Response_Headers_Policy resource.
8. THE CF_Module SHALL set `target_origin_id` to the `bucket_regional_domain_name` attribute of the App_Bucket resource.
9. THE CF_Module SHALL set `viewer_protocol_policy` to `redirect-to-https`.

### Requirement 8: Ordered Cache Behavior (SFGov API)

**User Story:** As a cloud engineer, I want an ordered cache behavior for the SFGov API path pattern, so that API requests to the food truck data endpoint are proxied to the SFGov origin with caching disabled and CORS preflight support.

#### Acceptance Criteria

1. THE CF_Module SHALL define an `ordered_cache_behavior` block within the Distribution resource.
2. THE CF_Module SHALL set `path_pattern` to `/resource/rqzj-sfat.json`.
3. THE CF_Module SHALL set `allowed_methods` to `["GET", "HEAD", "OPTIONS"]`.
4. THE CF_Module SHALL set `cached_methods` to `["GET", "HEAD", "OPTIONS"]`.
5. THE CF_Module SHALL set `compress` to `true`.
6. THE CF_Module SHALL set `cache_policy_id` to the `id` attribute of a `data.aws_cloudfront_cache_policy` data source with name `Managed-CachingDisabled`.
7. THE CF_Module SHALL set `origin_request_policy_id` to the `id` attribute of the Custom_Origin_Request_Policy resource.
8. THE CF_Module SHALL set `response_headers_policy_id` to the `id` attribute of a `data.aws_cloudfront_response_headers_policy` data source with name `Managed-CORS-With-Preflight`.
9. THE CF_Module SHALL set `target_origin_id` to `data.sfgov.org`.
10. THE CF_Module SHALL set `viewer_protocol_policy` to `https-only`.

### Requirement 9: Custom Origin Request Policy for SFGov

**User Story:** As a cloud engineer, I want a custom origin request policy for the SFGov origin, so that CORS origin headers and all query strings are forwarded to the SFGov Data API while cookies are excluded.

#### Acceptance Criteria

1. THE CF_Module SHALL define an `aws_cloudfront_origin_request_policy` resource with the Terraform identifier `sfgov_geofoodtruck_cloudfront_origin_request_policy`.
2. THE CF_Module SHALL set the `name` argument to `Custom-DataSFGov-CORS-Origin`.
3. THE CF_Module SHALL set the `comment` argument to `Custom CORS Origin Request Policy for SFGov Data API`.
4. THE CF_Module SHALL configure a `cookies_config` block with `cookie_behavior` set to `none`.
5. THE CF_Module SHALL configure a `headers_config` block with `header_behavior` set to `whitelist` and a `headers` block containing `items` set to `["origin"]`.
6. THE CF_Module SHALL configure a `query_strings_config` block with `query_string_behavior` set to `all`.

### Requirement 10: Custom Response Headers Policy

**User Story:** As a cloud engineer, I want a custom response headers policy that applies CORS headers, removes sensitive server headers, and enforces HSTS, so that responses from the S3 origin include proper security headers and do not leak server implementation details.

#### Acceptance Criteria

1. THE CF_Module SHALL define an `aws_cloudfront_response_headers_policy` resource with the Terraform identifier `geofoodtruck_cloudfront_response_header_policy`.
2. THE CF_Module SHALL set the `name` argument to `Custom-GeoFoodTruck-CORS-With-Preflight`.
3. THE CF_Module SHALL set the `comment` argument to `Custom CORS with Preflight Response Policy for GeoFoodTruck`.
4. THE CF_Module SHALL configure a `cors_config` block with `access_control_allow_credentials` set to `false`.
5. THE CF_Module SHALL set `access_control_allow_headers` items to `["*"]`.
6. THE CF_Module SHALL set `access_control_allow_methods` items to `["GET", "HEAD", "PUT", "POST", "PATCH", "DELETE", "OPTIONS"]`.
7. THE CF_Module SHALL set `access_control_allow_origins` items to `["*"]`.
8. THE CF_Module SHALL set `access_control_expose_headers` items to `["*"]`.
9. THE CF_Module SHALL set `origin_override` to `false`.
10. THE CF_Module SHALL configure a `remove_headers_config` block that removes the headers `Server`, `X-Amz-Server-Side-Encryption`, and `X-Amz-Server-Side-Encryption-Aws-Kms-Key-Id`.
11. THE CF_Module SHALL configure a `security_headers_config` block with a `strict_transport_security` sub-block setting `access_control_max_age_sec` to `31536000` and `override` to `true`.

### Requirement 11: Managed Cache Policy Data Sources

**User Story:** As a cloud engineer, I want the managed AWS cache policies referenced as data sources, so that the distribution uses AWS-maintained caching strategies without custom policy duplication.

#### Acceptance Criteria

1. THE CF_Module SHALL define a `data.aws_cloudfront_cache_policy` data source with the Terraform identifier `geofoodtruck_cloudfront_cache_policy` and `name` set to `Managed-CachingOptimized`.
2. THE CF_Module SHALL define a `data.aws_cloudfront_cache_policy` data source with the Terraform identifier `sfgov_geofoodtruck_cloudfront_cache_policy` and `name` set to `Managed-CachingDisabled`.

### Requirement 12: Managed Origin Request Policy Data Source

**User Story:** As a cloud engineer, I want the managed CORS-S3Origin origin request policy referenced as a data source, so that the default behavior uses the AWS-maintained CORS configuration for S3 origins.

#### Acceptance Criteria

1. THE CF_Module SHALL define a `data.aws_cloudfront_origin_request_policy` data source with the Terraform identifier `geofoodtruck_cloudfront_origin_request_policy` and `name` set to `Managed-CORS-S3Origin`.

### Requirement 13: Managed Response Headers Policy Data Source

**User Story:** As a cloud engineer, I want the managed CORS-With-Preflight response headers policy referenced as a data source, so that the SFGov ordered cache behavior uses the AWS-maintained CORS preflight response policy.

#### Acceptance Criteria

1. THE CF_Module SHALL define a `data.aws_cloudfront_response_headers_policy` data source with the Terraform identifier `sfgov_geofoodtruck_cloudfront_response_header_policy` and `name` set to `Managed-CORS-With-Preflight`.

### Requirement 14: Geo Restriction

**User Story:** As a cloud engineer, I want the CloudFront distribution to have no geographic restrictions, so that the application is accessible from all geographic locations.

#### Acceptance Criteria

1. THE CF_Module SHALL define a `restrictions` block within the Distribution resource containing a `geo_restriction` block.
2. THE CF_Module SHALL set the `restriction_type` argument to `none`.

### Requirement 15: Viewer Certificate

**User Story:** As a cloud engineer, I want the distribution to use the default CloudFront certificate, so that HTTPS is enabled without requiring a custom domain or ACM certificate.

#### Acceptance Criteria

1. THE CF_Module SHALL define a `viewer_certificate` block within the Distribution resource.
2. THE CF_Module SHALL set `cloudfront_default_certificate` to `true`.

### Requirement 16: WAF Web ACL Association

**User Story:** As a security engineer, I want the CloudFront distribution associated with the WAF Web ACL, so that all traffic is inspected by the firewall rules before reaching the origins.

#### Acceptance Criteria

1. THE CF_Module SHALL set the `web_acl_id` argument of the Distribution resource to the `arn` attribute of the WAF_Web_ACL resource.

### Requirement 17: Distribution Output

**User Story:** As a cloud engineer, I want the CloudFront distribution domain name exported as a Terraform output, so that other modules and deployment scripts can reference the distribution endpoint.

#### Acceptance Criteria

1. THE CF_Module SHALL define a Terraform output named `cloudfront_distribution_domain` with the value set to the `domain_name` attribute of the Distribution resource.

### Requirement 18: Terraform Module Structure

**User Story:** As a cloud engineer, I want the CloudFront Terraform configuration added to the existing `infra` directory at the project root, so that infrastructure code is colocated with other infrastructure modules that share the same provider and data sources.

#### Acceptance Criteria

1. THE CF_Module SHALL place all Terraform HCL files in the existing `infra` directory at the project root.
2. THE CF_Module SHALL rely on the existing `terraform` block with `required_providers` and AWS provider configured for `us-east-1` in `infra/main.tf` — this feature SHALL NOT declare its own provider configuration.
3. THE CF_Module SHALL rely on the existing `data "aws_caller_identity" "current"` data source declared in `infra/main.tf` — this feature SHALL NOT redeclare it.
4. THE CF_Module SHALL rely on the existing `data "aws_region" "current"` data source declared in `infra/main.tf` — this feature SHALL NOT redeclare it.

### Requirement 19: App Bucket Policy for CloudFront OAC Access

**User Story:** As a cloud engineer, I want the application bucket policy to grant CloudFront read access via Origin Access Control, so that the distribution can serve objects from the bucket without public access.

#### Acceptance Criteria

1. THE CF_Module SHALL define an `aws_s3_bucket_policy` resource with the Terraform identifier `geofoodtruck_app_bucket_policy` associated with the App_Bucket resource in `infra/cloudfront.tf`.
2. THE CF_Module SHALL configure the bucket policy document with a single statement containing Effect set to `Allow`, Principal Service set to `cloudfront.amazonaws.com`, Action set to `s3:GetObject`, and Resource set to the App_Bucket ARN with a `/*` suffix targeting all objects.
3. THE CF_Module SHALL include a `Condition` block in the policy statement with a `StringEquals` test on the key `AWS:SourceArn` matching the CloudFront_Distribution ARN attribute, restricting access to only the designated distribution.
4. THE CF_Module SHALL declare a `depends_on` relationship from the bucket policy resource to the CloudFront_Distribution resource, ensuring the distribution exists before the policy references its ARN.
