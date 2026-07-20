# Requirements Document

## Introduction

This document specifies the requirements for AWS S3 bucket resources defined in Terraform HCL for the GeoFoodTruck application. The configuration provisions two S3 buckets: an application bucket for hosting static React build assets served via CloudFront, and a log bucket for storing CloudFront access logs. Both buckets enforce KMS server-side encryption, block all public access, and follow the project's naming conventions. The Terraform configuration will reside in the `infra` directory at the project root.

## Glossary

- **S3_Module**: The Terraform HCL configuration in the `infra` directory that defines the S3 bucket resources and associated configurations.
- **App_Bucket**: The S3 bucket (`geofoodtruck-app-bucket`) that hosts the React application static assets (HTML, CSS, JS, images, JSON).
- **Log_Bucket**: The S3 bucket (`geofoodtruck-log-bucket`) that stores CloudFront distribution access logs.
- **KMS_Key**: The customer-managed AWS KMS symmetric encryption key (`aws_kms_key.geofoodtruck_kms_key`) defined in `infra/kms.tf` by the customer-managed-kms feature, referenced by ARN for server-side encryption of both buckets.
- **CloudFront_Distribution**: The AWS CloudFront distribution that serves content from the App_Bucket and writes access logs to the Log_Bucket.
- **OAC**: Origin Access Control, the CloudFront mechanism that authenticates requests to the S3 origin using SigV4 signing.
- **Public_Access_Block**: The `aws_s3_bucket_public_access_block` resource that prevents any public access to an S3 bucket through four boolean settings.
- **Build_Directory**: The local directory (defaulting to `../build`) containing the compiled React application files to upload to the App_Bucket.
- **Content_Type_Map**: A Terraform locals block mapping file extensions to MIME content types for uploaded S3 objects.

## Requirements

### Requirement 1: App Bucket Definition

**User Story:** As a cloud engineer, I want an S3 bucket provisioned for hosting static application assets, so that the React build files have a dedicated storage location served by CloudFront.

#### Acceptance Criteria

1. THE S3_Module SHALL define an `aws_s3_bucket` resource with the Terraform identifier `geofoodtruck_app_bucket` and the `bucket` argument set to `geofoodtruck-app-bucket`.
2. THE S3_Module SHALL include a `tags` block on the App_Bucket resource with a `Name` key set to `geofoodtruck-app-bucket`.

### Requirement 2: App Bucket KMS Encryption

**User Story:** As a security engineer, I want the application bucket encrypted with a customer-managed KMS key, so that all stored objects are protected with centrally managed encryption.

#### Acceptance Criteria

1. THE S3_Module SHALL define an `aws_s3_bucket_server_side_encryption_configuration` resource with the Terraform identifier `geofoodtruck_s3_bucket_server_side_encryption_configuration` and its `bucket` argument set to the `id` attribute of the App_Bucket resource.
2. THE S3_Module SHALL configure the encryption resource with a `rule` block containing an `apply_server_side_encryption_by_default` block that sets `sse_algorithm` to `aws:kms`.
3. THE S3_Module SHALL set the `kms_master_key_id` argument within the `apply_server_side_encryption_by_default` block to the `arn` attribute of the `aws_kms_key.geofoodtruck_kms_key` resource defined in `infra/kms.tf` by the customer-managed-kms feature.
4. THE S3_Module SHALL reference the KMS_Key through the existing `aws_kms_key.geofoodtruck_kms_key.arn` attribute — this feature SHALL NOT declare its own KMS key resource.

### Requirement 3: App Bucket Public Access Block

**User Story:** As a security engineer, I want all public access blocked on the application bucket, so that static assets are only accessible through the CloudFront distribution.

#### Acceptance Criteria

1. THE S3_Module SHALL define an `aws_s3_bucket_public_access_block` resource with the Terraform identifier `geofoodtruck_s3_bucket_public_access_block` and its `bucket` argument set to the `id` attribute of the App_Bucket resource.
2. THE Public_Access_Block for the App_Bucket SHALL set `block_public_acls` to `true`.
3. THE Public_Access_Block for the App_Bucket SHALL set `block_public_policy` to `true`.
4. THE Public_Access_Block for the App_Bucket SHALL set `ignore_public_acls` to `true`.
5. THE Public_Access_Block for the App_Bucket SHALL set `restrict_public_buckets` to `true`.

### Requirement 5: Log Bucket Definition

**User Story:** As a cloud engineer, I want an S3 bucket provisioned for storing CloudFront access logs, so that distribution access patterns are captured for auditing and analysis.

#### Acceptance Criteria

1. THE S3_Module SHALL define an `aws_s3_bucket` resource with the Terraform identifier `geofoodtruck_log_bucket` and the `bucket` argument set to `geofoodtruck-log-bucket`.
2. THE S3_Module SHALL tag the Log_Bucket with a `Name` tag set to `geofoodtruck-log-bucket`.
3. THE S3_Module SHALL provision the Log_Bucket in the same AWS region as the CloudFront_Distribution, as determined by the provider configuration defined in Requirement 11.

### Requirement 6: Log Bucket KMS Encryption

**User Story:** As a security engineer, I want the log bucket encrypted with the same customer-managed KMS key, so that CloudFront access logs are protected at rest with centrally managed encryption.

#### Acceptance Criteria

1. THE S3_Module SHALL define an `aws_s3_bucket_server_side_encryption_configuration` resource with the Terraform identifier `geofoodtruck_s3_bucket_log_server_side_encryption_configuration` associated with the Log_Bucket.
2. THE S3_Module SHALL configure the Log_Bucket encryption with an `apply_server_side_encryption_by_default` rule block setting `sse_algorithm` to `aws:kms`.
3. THE S3_Module SHALL set the `kms_master_key_id` in the Log_Bucket encryption rule to the same KMS_Key ARN referenced by the App_Bucket encryption configuration defined in Requirement 2.
4. THE S3_Module SHALL set `bucket_key_enabled` to `true` in the Log_Bucket encryption rule to reduce KMS API call volume for log object encryption.

### Requirement 7: Log Bucket Public Access Block

**User Story:** As a security engineer, I want all public access blocked on the log bucket, so that CloudFront access logs are not exposed to unauthorized access.

#### Acceptance Criteria

1. THE S3_Module SHALL define an `aws_s3_bucket_public_access_block` resource with the Terraform identifier `geofoodtruck_s3_bucket_log_public_access_block`, with its `bucket` argument set to the `id` attribute of the Log_Bucket resource.
2. THE Public_Access_Block for the Log_Bucket SHALL set `block_public_acls` to `true`.
3. THE Public_Access_Block for the Log_Bucket SHALL set `block_public_policy` to `true`.
4. THE Public_Access_Block for the Log_Bucket SHALL set `ignore_public_acls` to `true`.
5. THE Public_Access_Block for the Log_Bucket SHALL set `restrict_public_buckets` to `true`.

### Requirement 8: Log Bucket Ownership Controls

**User Story:** As a cloud engineer, I want the log bucket ownership controls set to BucketOwnerPreferred, so that CloudFront Standard Logging can write logs using ACLs as required by the service.

#### Acceptance Criteria

1. THE S3_Module SHALL define an `aws_s3_bucket_ownership_controls` resource with the Terraform identifier `geofoodtruck_s3_bucket_log_ownership_controls`, with its `bucket` argument set to the `id` attribute of the Log_Bucket resource.
2. THE S3_Module SHALL configure a `rule` block within the ownership controls resource, setting `object_ownership` to `BucketOwnerPreferred`.
3. THE S3_Module SHALL include a checkov skip annotation `CKV2_AWS_65` with the justification "CloudFront Standard Logging requires S3 log bucket to have ACLs enabled".

### Requirement 9: Log Bucket ACL

**User Story:** As a cloud engineer, I want the log bucket ACL set to private, so that bucket access is restricted while still permitting CloudFront log delivery via ownership controls.

#### Acceptance Criteria

1. THE S3_Module SHALL define an `aws_s3_bucket_acl` resource with the Terraform identifier `geofoodtruck_log_bucket_acl`, with its `bucket` argument set to the `id` attribute of the Log_Bucket resource.
2. THE S3_Module SHALL set the `acl` argument to `private`.
3. THE S3_Module SHALL declare a `depends_on` relationship from the ACL resource to the ownership controls resource (`geofoodtruck_s3_bucket_log_ownership_controls`), ensuring ownership controls are applied before the ACL is set.

### Requirement 10: Static File Upload Mechanism

**User Story:** As a cloud engineer, I want all React build files uploaded to the application bucket with correct content types, so that the CloudFront distribution serves assets with appropriate MIME types and change detection.

#### Acceptance Criteria

1. THE S3_Module SHALL define an `aws_s3_object` resource with the Terraform identifier `app_files` using a `for_each` expression that constructs a map from `local.app_build_files` where each file path maps to itself (i.e., `{ for file in local.app_build_files : file => file }`).
2. THE S3_Module SHALL use a `fileset` function with the pattern `**/**` to enumerate all files in the Build_Directory recursively, storing the result in the `app_build_files` local value.
3. THE S3_Module SHALL set the `bucket` of each S3 object to the App_Bucket resource ID.
4. THE S3_Module SHALL set the `key` of each S3 object to the relative file path within the Build_Directory (the `each.value` from the for_each map).
5. THE S3_Module SHALL set the `source` of each S3 object to the interpolated path `"${var.app_build_dir}/${each.value}"`.
6. THE S3_Module SHALL determine the `content_type` of each S3 object by extracting the file extension as the last element after splitting the filename on `"."`, then performing a `lookup` against the Content_Type_Map, defaulting to `application/octet-stream` for unrecognized extensions.
7. THE S3_Module SHALL set the `etag` of each S3 object to the MD5 hash of the source file using the `filemd5("${var.app_build_dir}/${each.value}")` expression, enabling change detection on subsequent applies.
9. THE Content_Type_Map SHALL be defined as a Terraform local named `content_types` and include mappings for the extensions: `html` to `text/html`, `css` to `text/css`, `js` to `application/javascript`, `png` to `image/png`, `ico` to `image/x-icon`, `txt` to `text/plain`, `json` to `application/json`, and `map` to `application/json`.

### Requirement 11: Terraform Module Structure

**User Story:** As a cloud engineer, I want the S3 Terraform configuration added to the existing `infra` directory at the project root, so that infrastructure code is colocated with other infrastructure modules that share the same provider and data sources.

#### Acceptance Criteria

1. THE S3_Module SHALL place all Terraform HCL files in the existing `infra` directory at the project root.
2. THE S3_Module SHALL rely on the existing `terraform` block with `required_providers` and AWS provider configured for `us-east-1` in `infra/main.tf` — this feature SHALL NOT declare its own provider configuration.
3. THE S3_Module SHALL add the `app_build_dir` variable of type `string` with a default value of `../build` and a description of `"Path to the application build directory"` to the existing `infra/variables.tf` file.
4. THE S3_Module SHALL define a `locals` block containing the `app_build_files` local value using the expression `fileset(var.app_build_dir, "**/**")` and a `content_types` local value containing the Content_Type_Map.
5. THE S3_Module SHALL rely on the existing `data "aws_caller_identity" "current"` data source declared in `infra/main.tf` — this feature SHALL NOT redeclare it.
6. THE S3_Module SHALL rely on the existing `data "aws_region" "current"` data source declared in `infra/main.tf` — this feature SHALL NOT redeclare it.

### Requirement 12: Outputs for Cross-Module References

**User Story:** As a cloud engineer, I want the S3 module to export bucket names and ARNs as Terraform outputs, so that other modules (such as CloudFront and WAF) can reference the bucket resources.

#### Acceptance Criteria

1. THE S3_Module SHALL define a Terraform output named `app_bucket_name` with the value set to the `bucket` attribute of the App_Bucket resource.
2. THE S3_Module SHALL define a Terraform output named `app_bucket_arn` with the value set to the `arn` attribute of the App_Bucket resource.
3. THE S3_Module SHALL define a Terraform output named `app_bucket_regional_domain_name` with the value set to the `bucket_regional_domain_name` attribute of the App_Bucket resource.
4. THE S3_Module SHALL define a Terraform output named `log_bucket_name` with the value set to the `bucket` attribute of the Log_Bucket resource.
5. THE S3_Module SHALL define a Terraform output named `log_bucket_arn` with the value set to the `arn` attribute of the Log_Bucket resource.
6. THE S3_Module SHALL define a Terraform output named `log_bucket_regional_domain_name` with the value set to the `bucket_regional_domain_name` attribute of the Log_Bucket resource.
