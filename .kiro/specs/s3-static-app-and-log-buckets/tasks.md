# Implementation Plan: S3 Static App and Log Buckets

## Overview

This plan implements the Terraform HCL configuration for two S3 buckets (application and log) in the `infra` directory at the project root. Tasks are ordered by resource dependency: foundational provider/variables first, then KMS, then buckets with encryption and access controls, then resources that depend on external CloudFront distribution, and finally outputs. All files use Terraform HCL targeting the `hashicorp/aws` provider in `us-east-1`.

## Tasks

- [x] 1. Set up variables and locals
  - [x] 1.1 Add input variable and locals to existing `infra/variables.tf`
    - Append `variable "app_build_dir"` of type `string` with default `"../build"` and description `"Path to the application build directory"`
    - Add `locals` block with `app_build_files = fileset(var.app_build_dir, "**/**")`
    - Add `local.content_types` map with entries: html→text/html, css→text/css, js→application/javascript, png→image/png, ico→image/x-icon, txt→text/plain, json→application/json, map→application/json
    - Do NOT create `infra/main.tf` or add provider/required_providers — these exist already
    - Do NOT add `aws_caller_identity` or `aws_region` data sources — these are managed in `infra/main.tf`
    - _Requirements: 11.2, 11.3, 11.4, 11.5, 11.6, 10.9_

  - [x] 1.2 Create `infra/s3.tf` as empty file for S3 resources
    - Create the file that will hold all S3 bucket resources (populated in subsequent tasks)
    - _Requirements: 11.1_

- [x] 2. Reference existing KMS key
  - [x] 2.1 Verify `aws_kms_key.geofoodtruck_kms_key` is available from `infra/kms.tf`
    - Confirm the KMS key resource is defined in `infra/kms.tf` by the customer-managed-kms feature
    - Do NOT create or redeclare the `aws_kms_key` resource in `infra/s3.tf` — reference it directly via `aws_kms_key.geofoodtruck_kms_key.arn`
    - _Requirements: 2.3, 2.4, 6.3_

- [x] 3. Implement App Bucket with encryption and public access block
  - [x] 3.1 Add `aws_s3_bucket.geofoodtruck_app_bucket` resource to `infra/s3.tf`
    - Set `bucket = "geofoodtruck-app-bucket"`
    - Add `tags = { Name = "geofoodtruck-app-bucket" }`
    - _Requirements: 1.1, 1.2_

  - [x] 3.2 Add `aws_s3_bucket_server_side_encryption_configuration.geofoodtruck_s3_bucket_server_side_encryption_configuration` resource to `infra/s3.tf`
    - Set `bucket = aws_s3_bucket.geofoodtruck_app_bucket.id`
    - Configure `rule.apply_server_side_encryption_by_default` with `sse_algorithm = "aws:kms"` and `kms_master_key_id = aws_kms_key.geofoodtruck_kms_key.arn`
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

  - [x] 3.3 Add `aws_s3_bucket_public_access_block.geofoodtruck_s3_bucket_public_access_block` resource to `infra/s3.tf`
    - Set `bucket = aws_s3_bucket.geofoodtruck_app_bucket.id`
    - Set all four booleans to `true`: `block_public_acls`, `block_public_policy`, `ignore_public_acls`, `restrict_public_buckets`
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 4. Implement Log Bucket with encryption and public access block
  - [x] 4.1 Add `aws_s3_bucket.geofoodtruck_log_bucket` resource to `infra/s3.tf`
    - Set `bucket = "geofoodtruck-log-bucket"`
    - Add `tags = { Name = "geofoodtruck-log-bucket" }`
    - _Requirements: 5.1, 5.2, 5.3_

  - [x] 4.2 Add `aws_s3_bucket_server_side_encryption_configuration.geofoodtruck_s3_bucket_log_server_side_encryption_configuration` resource to `infra/s3.tf`
    - Set `bucket = aws_s3_bucket.geofoodtruck_log_bucket.id`
    - Configure `rule.apply_server_side_encryption_by_default` with `sse_algorithm = "aws:kms"` and `kms_master_key_id = aws_kms_key.geofoodtruck_kms_key.arn`
    - Set `bucket_key_enabled = true`
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

  - [x] 4.3 Add `aws_s3_bucket_public_access_block.geofoodtruck_s3_bucket_log_public_access_block` resource to `infra/s3.tf`
    - Set `bucket = aws_s3_bucket.geofoodtruck_log_bucket.id`
    - Set all four booleans to `true`: `block_public_acls`, `block_public_policy`, `ignore_public_acls`, `restrict_public_buckets`
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [x] 5. Implement Log Bucket ownership controls and ACL
  - [x] 5.1 Add `aws_s3_bucket_ownership_controls.geofoodtruck_s3_bucket_log_ownership_controls` resource to `infra/s3.tf`
    - Set `bucket = aws_s3_bucket.geofoodtruck_log_bucket.id`
    - Configure `rule` block with `object_ownership = "BucketOwnerPreferred"`
    - Add checkov skip annotation comment: `#checkov:skip=CKV2_AWS_65:CloudFront Standard Logging requires S3 log bucket to have ACLs enabled`
    - _Requirements: 8.1, 8.2, 8.3_

  - [x] 5.2 Add `aws_s3_bucket_acl.geofoodtruck_log_bucket_acl` resource to `infra/s3.tf`
    - Set `bucket = aws_s3_bucket.geofoodtruck_log_bucket.id`
    - Set `acl = "private"`
    - Add `depends_on = [aws_s3_bucket_ownership_controls.geofoodtruck_s3_bucket_log_ownership_controls]`
    - _Requirements: 9.1, 9.2, 9.3_

- [x] 7. Implement S3 object upload for static files
  - [x] 7.1 Add `aws_s3_object.app_files` resource to `infra/s3.tf`
    - Set `for_each = { for file in local.app_build_files : file => file }`
    - Set `bucket = aws_s3_bucket.geofoodtruck_app_bucket.id`
    - Set `key = each.value`
    - Set `source = "${var.app_build_dir}/${each.value}"`
    - Set `content_type` using `lookup(local.content_types, element(split(".", each.value), length(split(".", each.value)) - 1), "application/octet-stream")`
    - Set `etag = filemd5("${var.app_build_dir}/${each.value}")`
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.7, 10.9_

- [x] 8. Define module outputs
  - [x] 8.1 Create `infra/outputs.tf` with all output definitions
    - Define `output "app_bucket_name"` with value `aws_s3_bucket.geofoodtruck_app_bucket.bucket`
    - Define `output "app_bucket_arn"` with value `aws_s3_bucket.geofoodtruck_app_bucket.arn`
    - Define `output "app_bucket_regional_domain_name"` with value `aws_s3_bucket.geofoodtruck_app_bucket.bucket_regional_domain_name`
    - Define `output "log_bucket_name"` with value `aws_s3_bucket.geofoodtruck_log_bucket.bucket`
    - Define `output "log_bucket_arn"` with value `aws_s3_bucket.geofoodtruck_log_bucket.arn`
    - Define `output "log_bucket_regional_domain_name"` with value `aws_s3_bucket.geofoodtruck_log_bucket.bucket_regional_domain_name`
    - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5, 12.6_

- [x] 9. Validation checkpoint
  - Ensure `terraform validate` passes in the `infra` directory
  - Ensure `terraform fmt -check` reports no formatting issues
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- This feature adds to the EXISTING `infra/` module — it does not create `main.tf` or provider configuration.
- `data "aws_caller_identity" "current"`, `data "aws_region" "current"`, `required_providers`, and `provider "aws"` are already declared in `infra/main.tf` and must NOT be redeclared by this feature.
- `aws_kms_key.geofoodtruck_kms_key` is already defined in `infra/kms.tf` by the customer-managed-kms feature and must NOT be redeclared — reference it via `aws_kms_key.geofoodtruck_kms_key.arn`.
- This is an Infrastructure as Code (Terraform) feature — property-based testing with randomized inputs does not apply.
- Each task references specific requirements for traceability.
- The CloudFront distribution resource (`aws_cloudfront_distribution.geofoodtruck_app_distribution`) is defined in a separate feature; S3 object uploads do not depend on it.
- The checkpoint in task 9 uses `terraform validate` and `terraform fmt` as the primary validation mechanisms for HCL correctness.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2"] },
    { "id": 1, "tasks": ["2.1"] },
    { "id": 2, "tasks": ["3.1", "4.1"] },
    { "id": 3, "tasks": ["3.2", "3.3", "4.2", "4.3"] },
    { "id": 4, "tasks": ["5.1"] },
    { "id": 5, "tasks": ["5.2", "7.1"] },
    { "id": 6, "tasks": ["8.1"] }
  ]
}
```
