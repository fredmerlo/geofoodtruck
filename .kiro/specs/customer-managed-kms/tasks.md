# Implementation Plan: Customer-Managed KMS Key

## Overview

This plan implements the Terraform HCL configuration for a customer-managed AWS KMS key in the existing `infra` directory. The feature defines only the KMS key resource and alias in `infra/kms.tf`. The key policy document and admin role are managed by the iam-roles-and-policy-documents feature in `infra/policies.tf` and `infra/roles.tf`. This feature does NOT create provider configuration, `aws_caller_identity`, or `aws_region` data sources — those are already managed in `infra/main.tf`.

## Tasks

- [x] 1. Set up variables
  - [x] 1.1 Add the `aws_account_id` variable to existing `infra/variables.tf`
    - Define `variable "aws_account_id"` with type `string`, `sensitive = true`, and a validation rule ensuring exactly 12 digits using `can(regex("^[0-9]{12}$", var.aws_account_id))`
    - Do NOT create `infra/main.tf` — it exists already
    - _Requirements: 10.1, 10.3_

  - [x] 1.2 Verify `infra/main.tf` exists with provider and data sources
    - Confirm `infra/main.tf` already contains `terraform` block, `provider "aws"`, `data "aws_caller_identity" "current"`, and `data "aws_region" "current"`
    - _Requirements: 10.2_

- [x] 2. Verify key policy and admin role are available
  - [x] 2.1 Confirm external resources from iam-roles-and-policy-documents feature
    - Verify `data.aws_iam_policy_document.geofoodtruck_kms_key_policy` is defined in `infra/policies.tf`
    - Verify `aws_iam_role.geofoodtruck_kms_admin_role` is defined in `infra/roles.tf`
    - Do NOT create these resources in `infra/kms.tf` — reference them directly
    - _Requirements: 3.1, 3.2, 3.3_

- [x] 3. Implement KMS key resource
  - [x] 3.1 Create `infra/kms.tf` with the `aws_kms_key` resource
    - Resource identifier: `geofoodtruck_kms_key`
    - Set `description` to "KMS key for GeoFoodTruck"
    - Set `is_enabled = true`, `key_usage = "ENCRYPT_DECRYPT"`, `customer_master_key_spec = "SYMMETRIC_DEFAULT"`
    - Set `enable_key_rotation = true`, `rotation_period_in_days = 180`
    - Set `deletion_window_in_days = 30`, `multi_region = false`
    - Set `policy` to `data.aws_iam_policy_document.geofoodtruck_kms_key_policy.json`
    - Tag with `Name = "geofoodtruck-kms-key"`
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 2.1, 2.2, 2.3, 3.1, 8.1_

- [x] 4. Implement KMS alias
  - [x] 4.1 Add the `aws_kms_alias` resource to `infra/kms.tf`
    - Resource identifier: `geofoodtruck_kms_alias`
    - Set `name` to `alias/geofoodtruck-kms-key`
    - Set `target_key_id` to `aws_kms_key.geofoodtruck_kms_key.key_id`
    - _Requirements: 8.2_

- [x] 5. Implement outputs
  - [x] 5.1 Add the `kms_key_arn` output to existing `infra/outputs.tf`
    - Define `output "kms_key_arn"` with `description` set to "ARN of the customer-managed KMS key"
    - Set `value` to `aws_kms_key.geofoodtruck_kms_key.arn`
    - _Requirements: 3.4, 10.4_

- [x] 6. Validation checkpoint
  - Run `terraform fmt -check` against the `infra/` directory
  - Run `terraform validate` in the `infra/` directory
  - Ensure all tests pass, ask the user if questions arise.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2"] },
    { "id": 1, "tasks": ["2.1"] },
    { "id": 2, "tasks": ["3.1"] },
    { "id": 3, "tasks": ["4.1", "5.1"] }
  ]
}
```

## Notes

- This feature adds to the EXISTING `infra/` module — it does not create `main.tf` or provider configuration.
- `data "aws_caller_identity" "current"`, `data "aws_region" "current"`, `required_providers`, and `provider "aws"` are already declared in `infra/main.tf` and must NOT be redeclared by this feature.
- The KMS key policy document (`data.aws_iam_policy_document.geofoodtruck_kms_key_policy`) is defined in `infra/policies.tf` by the iam-roles-and-policy-documents feature — it is NOT defined in `infra/kms.tf`.
- The KMS admin role (`aws_iam_role.geofoodtruck_kms_admin_role`) and its policy attachments are defined in `infra/roles.tf` and `infra/policies.tf` by the iam-roles-and-policy-documents feature — they are NOT defined in `infra/kms.tf`.
- S3 bucket encryption is managed in the "s3-static-app-and-log-buckets" feature and should NOT be duplicated here.
- This is Infrastructure as Code (Terraform HCL) — property-based testing does not apply.
