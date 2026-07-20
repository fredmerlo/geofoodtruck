# Requirements Document

## Introduction

This document specifies the requirements for a customer-managed AWS KMS key defined in Terraform HCL. The KMS key provides centralized encryption for the GeoFoodTruck application's data-at-rest needs, including CloudWatch Logs encryption for WAF logging. The Terraform configuration will reside in the `infra` directory at the project root.

## Glossary

- **KMS_Module**: The Terraform HCL configuration in the `infra` directory that defines the customer-managed KMS key and associated resources.
- **KMS_Key**: The AWS KMS symmetric encryption key resource (`aws_kms_key`) managed by the KMS_Module.
- **Key_Policy**: The JSON policy document attached to the KMS_Key that grants permissions to AWS principals and services.
- **KMS_Admin_Role**: The IAM role (GeoFoodTruckKmsAdmin) with AWSKeyManagementServicePowerUser policy used for key administration.
- **WAF_Log_Group**: The CloudWatch Logs log group used for WAF web ACL logging (named `aws-waf-logs-geofoodtruck-log-group`).

## Requirements

### Requirement 1: KMS Key Resource Definition

**User Story:** As a cloud engineer, I want a symmetric customer-managed KMS key provisioned via Terraform, so that the application has centralized control over data encryption.

#### Acceptance Criteria

1. THE KMS_Module SHALL define an `aws_kms_key` resource with the identifier `geofoodtruck_kms_key`, with `customer_master_key_spec` set to `SYMMETRIC_DEFAULT`.
2. THE KMS_Module SHALL configure the KMS_Key with `key_usage` set to `ENCRYPT_DECRYPT`.
3. THE KMS_Module SHALL configure the KMS_Key with `is_enabled` set to `true`.
4. THE KMS_Module SHALL set the KMS_Key `description` to "KMS key for GeoFoodTruck".
5. THE KMS_Module SHALL configure the KMS_Key with `deletion_window_in_days` set to `30`.
6. THE KMS_Module SHALL configure the KMS_Key with `multi_region` set to `false`.

### Requirement 2: Key Rotation Configuration

**User Story:** As a security engineer, I want automatic key rotation enabled with a defined rotation period, so that cryptographic material is refreshed regularly without manual intervention.

#### Acceptance Criteria

1. THE KMS_Module SHALL configure the KMS_Key with `enable_key_rotation` set to `true`.
2. THE KMS_Module SHALL configure the KMS_Key with `rotation_period_in_days` set to `180`, which falls within the AWS-permitted range of 90 to 2560 days.
3. THE KMS_Module SHALL configure the KMS_Key with a `deletion_window_in_days` value of 30 to prevent accidental loss of rotated cryptographic material.

### Requirement 3: Key Policy and Admin Role (managed by iam-roles-and-policy-documents feature)

**User Story:** As a cloud engineer, I want the KMS key policy and admin role to be managed alongside other IAM resources, so that all policy documents and roles are organized in `infra/policies.tf` and `infra/roles.tf`.

#### Acceptance Criteria

1. THE KMS_Module SHALL set the `policy` attribute of the KMS_Key to `data.aws_iam_policy_document.geofoodtruck_kms_key_policy.json`, referencing the policy document defined in `infra/policies.tf` by the iam-roles-and-policy-documents feature.
2. THE KMS_Module SHALL NOT define the `data "aws_iam_policy_document"` for the key policy — it is managed in `infra/policies.tf`.
3. THE KMS_Module SHALL NOT define the `aws_iam_role` for KMS administration — it is managed in `infra/roles.tf` by the iam-roles-and-policy-documents feature.
4. THE KMS_Module SHALL output the KMS_Key ARN as a full ARN string via the `kms_key_arn` Terraform output.

### Requirement 8: Tagging Conventions

**User Story:** As a cloud engineer, I want the KMS key tagged with the project naming convention, so that the key is identifiable in AWS console and cost reporting.

#### Acceptance Criteria

1. THE KMS_Module SHALL tag the KMS_Key with a `Name` tag set to `geofoodtruck-kms-key`.
2. THE KMS_Module SHALL define an `aws_kms_alias` resource with `name` set to `alias/geofoodtruck-kms-key` targeting the KMS_Key, so that the key is identifiable by name in the AWS KMS console.

### Requirement 10: Terraform Module Structure

**User Story:** As a cloud engineer, I want the KMS Terraform configuration organized in the `infra` directory at the project root, so that infrastructure code is separated from application code.

#### Acceptance Criteria

1. THE KMS_Module SHALL place all Terraform HCL files in the `infra` directory at the project root.
2. THE KMS_Module SHALL rely on the existing `main.tf` file containing the `terraform` block with `required_providers` and the AWS provider configured for `us-east-1` — this feature SHALL NOT create or modify `infra/main.tf`.
3. THE KMS_Module SHALL define a `variables.tf` file containing the `aws_account_id` variable marked as sensitive, with a validation rule that ensures the value is a 12-digit numeric string.
4. THE KMS_Module SHALL define an `outputs.tf` file exposing the `kms_key_arn` output.
5. THE KMS_Module SHALL define the KMS key resource and KMS alias resource in a `kms.tf` file. The IAM role, policy attachment, and policy document resources are managed by the iam-roles-and-policy-documents feature in `infra/roles.tf` and `infra/policies.tf`.
