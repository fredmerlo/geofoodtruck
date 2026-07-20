# Implementation Plan: IAM Roles and Policy Documents

## Overview

Implement the Terraform HCL infrastructure in the existing `infra` directory that defines IAM roles and policy documents for the GeoFoodTruck application. This includes Lambda execution role, WAF log delivery policy, KMS key policy document, and KMS admin role with policy attachments. Each task targets a specific `.tf` file. This feature does NOT create provider configuration, `aws_caller_identity`, or `aws_region` data sources — those are already managed in `infra/main.tf`.

## Tasks

- [x] 1. Set up input variables
  - [x] 1.1 Add input variable definitions to existing `infra/variables.tf`
    - Append `aws_account_id` variable with type `string`, `sensitive = true`
    - Add `validation` block with condition `can(regex("^[0-9]{12}$", var.aws_account_id))`
    - Add descriptive error message for validation failure
    - Do NOT create `infra/main.tf` or add provider/required_providers — these exist already
    - Do NOT add `aws_caller_identity` or `aws_region` data sources — these are managed in `infra/main.tf`
    - _Requirements: 3.4, 3.5, 3.6, 3.7_

- [x] 2. Implement policy documents
  - [x] 2.1 Create `infra/policies.tf` with managed policy lookups
    - Define `data "aws_iam_policy" "geofoodtruck_s3_read_only"` referencing ARN `arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess`
    - _Requirements: 1.4_

  - [x] 2.2 Add Lambda assume role policy document to `infra/policies.tf`
    - Define `data "aws_iam_policy_document" "geofoodtruck_lambda_assume_role"` with `sts:AssumeRole` for `lambda.amazonaws.com` and `edgelambda.amazonaws.com` service principals
    - _Requirements: 1.2, 4.4_

  - [x] 2.3 Add Lambda logging policy document to `infra/policies.tf`
    - Define `data "aws_iam_policy_document" "geofoodtruck_lambda_logging"` granting `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents`
    - Set resources to `arn:aws:logs:*:*:*` with an explanatory comment about Lambda@Edge multi-region execution
    - _Requirements: 1.3, 4.5_

  - [x] 2.4 Add WAF log delivery policy document to `infra/policies.tf`
    - Define `data "aws_iam_policy_document" "geofoodtruck_waf_log_delivery"` with `version = "2012-10-17"`
    - Grant `logs:CreateLogStream` and `logs:PutLogEvents` to `delivery.logs.amazonaws.com`
    - Scope resource to WAF log group ARN using dynamic `data.aws_region` and `data.aws_caller_identity` references
    - Add `ArnLike` condition on `aws:SourceArn` and `StringEquals` condition on `aws:SourceAccount`
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

  - [x] 2.5 Add KMS key policy document to `infra/policies.tf`
    - Define `data "aws_iam_policy_document" "geofoodtruck_kms_key_policy"` with 4 statements:
    - Statement 1 (Sid: "EnableIAMUserPermissions"): Allow `kms:*` on `*` for KMS admin role ARN and account root principal
    - Statement 2 (Sid: "AllowCloudFrontServiceAccess"): Allow `kms:Encrypt`, `kms:Decrypt`, `kms:GenerateDataKey*` to `cloudfront.amazonaws.com` on `*`
    - Statement 3 (Sid: "AllowLogDeliveryServiceAccess"): Allow `kms:GenerateDataKey*`, `kms:Decrypt` to `delivery.logs.amazonaws.com` with `StringEquals` condition on `aws:SourceAccount`
    - Statement 4 (Sid: "AllowCloudWatchLogsServiceAccess"): Allow `kms:Encrypt*`, `kms:Decrypt*`, `kms:ReEncrypt*`, `kms:GenerateDataKey*`, `kms:Describe*` to `logs.${data.aws_region.current.name}.amazonaws.com` with `ArnLike` condition on `kms:EncryptionContext:aws:logs:arn`
    - Use `data.aws_region.current.name` and `var.aws_account_id` for all dynamic references
    - _Requirements: 5.1, 5.2, 5.3, 6.1, 7.1, 7.2, 8.1, 8.2, 8.3, 10.1_

- [x] 3. Implement IAM roles
  - [x] 3.1 Create `infra/roles.tf` with Lambda execution role
    - Define `aws_iam_role "geofoodtruck_lambda_execution"` with name `GeoFoodTruckLambdaExecution`
    - Set `assume_role_policy` to `data.aws_iam_policy_document.geofoodtruck_lambda_assume_role.json`
    - Add `inline_policy` block named `GeoFoodTruckLambdaBasicExecution` using the lambda logging policy document
    - Attach managed policy via `managed_policy_arns` referencing the S3 read-only data source ARN
    - Add `Name` tag with value `geofoodtruck-lambda-execution`
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 3.2, 3.8_

  - [x] 3.2 Add KMS admin role to `infra/roles.tf`
    - Define `aws_iam_role "geofoodtruck_kms_admin_role"` with name `GeoFoodTruckKmsAdmin`
    - Set `assume_role_policy` allowing `sts:AssumeRole` by `arn:aws:iam::${var.aws_account_id}:root`
    - Add `Name` tag with value `geofoodtruck-kms-admin`
    - _Requirements: 9.1, 9.4, 9.5, 3.8_

- [x] 4. Implement policy attachments
  - [x] 4.1 Add KMS admin policy attachment to `infra/policies.tf`
    - Define `aws_iam_role_policy_attachment "geofoodtruck_kms_admin_policy_attachment"` with `role = aws_iam_role.geofoodtruck_kms_admin_role.name` and `policy_arn = "arn:aws:iam::aws:policy/AWSKeyManagementServicePowerUser"`
    - Define `aws_iam_role_policy_attachments_exclusive "geofoodtruck_kms_admin_policy_exclusive"` with `role_name` and `policy_arns` referencing the attachment
    - _Requirements: 9.2, 9.3_

- [x] 5. Validation checkpoint
  - Run `terraform validate` and `terraform fmt -check` on the `infra` directory
  - Ensure all files are properly formatted and the configuration is syntactically valid
  - Ask the user if questions arise.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["2.1", "2.2", "2.3", "2.4"] },
    { "id": 2, "tasks": ["3.1", "3.2"] },
    { "id": 3, "tasks": ["2.5", "4.1"] },
    { "id": 4, "tasks": ["5"] }
  ]
}
```

## Notes

- This feature adds to the EXISTING `infra/` module — it does not create `main.tf` or provider configuration.
- `data "aws_caller_identity" "current"`, `data "aws_region" "current"`, `required_providers`, and `provider "aws"` are already declared in `infra/main.tf` and must NOT be redeclared by this feature.
- This feature is Infrastructure as Code (Terraform HCL) — property-based testing does not apply.
- All policy documents use `data "aws_iam_policy_document"` for Terraform-native validation and composition per Requirement 4.4.
- The `aws_account_id` variable is marked sensitive to prevent exposure in plan output.
- The KMS key resource itself is managed in the "customer-managed-kms" feature (`infra/kms.tf`), but the KMS key policy document and KMS admin role are defined by THIS feature in `infra/policies.tf` and `infra/roles.tf`.
- Task 2.5 (KMS key policy) depends on task 3.2 (KMS admin role) because the policy references the role ARN — they are placed in the same wave since Terraform resolves this implicitly.
