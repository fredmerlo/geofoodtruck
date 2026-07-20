# Requirements Document

## Introduction

This document defines the requirements for IAM roles and policy documents supporting the GeoFoodTruck infrastructure. The GeoFoodTruck application is a React-based web application deployed to AWS using S3, CloudFront, WAF, KMS, Lambda@Edge, and GitHub Actions CI/CD pipelines. IAM roles and policies must follow the principle of least privilege, granting only the permissions necessary for each service to perform its function. All Terraform HCL output goes into an `infra` directory at the project root.

## Glossary

- **IAM_Module**: The Terraform HCL configuration within the `infra` directory that defines IAM roles, policies, and policy attachments for the GeoFoodTruck infrastructure.
- **Lambda_Execution_Role**: An IAM role assumed by the Lambda service and Lambda@Edge service to execute the XSS protection function.
- **WAF_Logging_Policy**: An IAM policy document that grants the WAF log delivery service permission to write logs to CloudWatch Logs.
- **Policy_Document**: A Terraform `data "aws_iam_policy_document"` resource that defines IAM permissions in a structured, composable format.
- **Inline_Policy**: An IAM policy embedded directly within an IAM role resource using the `inline_policy` block.
- **Managed_Policy**: An AWS-managed or customer-managed IAM policy attached to a role via ARN reference.
- **Assume_Role_Policy**: A trust policy that defines which principals (services or accounts) may assume a given IAM role.

## Requirements

### Requirement 1: Lambda Execution Role

**User Story:** As a platform engineer, I want a dedicated IAM role for the Lambda@Edge XSS function, so that the function has only the permissions it needs to execute and log.

#### Acceptance Criteria

1. THE IAM_Module SHALL define a Lambda_Execution_Role with the name prefix "GeoFoodTruck" and a Terraform resource identifier using the "geofoodtruck_" prefix.
2. THE Lambda_Execution_Role SHALL include an Assume_Role_Policy, defined as a Policy_Document data source, that grants `sts:AssumeRole` to the `lambda.amazonaws.com` and `edgelambda.amazonaws.com` service principals.
3. THE Lambda_Execution_Role SHALL include an Inline_Policy named with the "GeoFoodTruck" prefix, granting `logs:CreateLogGroup`, `logs:CreateLogStream`, and `logs:PutLogEvents` permissions scoped to `arn:aws:logs:*:*:*` to accommodate Lambda@Edge execution across multiple regions with dynamic log stream names.
4. THE Lambda_Execution_Role SHALL attach the AWS Managed_Policy `AmazonS3ReadOnlyAccess` using a `data "aws_iam_policy"` lookup by ARN.
5. WHEN a new permission is added to the Lambda_Execution_Role, THE IAM_Module SHALL define the permission using a Policy_Document data source rather than raw JSON.

### Requirement 2: WAF Log Delivery Policy

**User Story:** As a platform engineer, I want a structured policy document for WAF log delivery, so that the WAF service can write logs to CloudWatch Logs with proper authorization.

#### Acceptance Criteria

1. THE IAM_Module SHALL define a WAF_Logging_Policy as a Policy_Document data source with a single "Allow" statement.
2. THE WAF_Logging_Policy SHALL grant `logs:CreateLogStream` and `logs:PutLogEvents` permissions to the `delivery.logs.amazonaws.com` service principal using a "Service" principal type.
3. THE WAF_Logging_Policy SHALL scope the resource to the WAF CloudWatch log group ARN with a `:*` suffix to encompass all log streams within the group named "aws-waf-logs-geofoodtruck-log-group".
4. THE WAF_Logging_Policy SHALL include an "ArnLike" condition on `aws:SourceArn` with the value pattern `arn:aws:logs:<region>:<account-id>:*`, using dynamic references from `data "aws_region"` and `data "aws_caller_identity"`.
5. THE WAF_Logging_Policy SHALL include a "StringEquals" condition on `aws:SourceAccount` with the value derived from `data "aws_caller_identity"` for the owning account identifier.
6. THE WAF_Logging_Policy SHALL specify the policy document version as "2012-10-17".

### Requirement 3: Terraform Module Structure

**User Story:** As a platform engineer, I want the IAM Terraform configuration organized in the `infra` directory with clear file separation, so that the codebase is maintainable and follows Terraform best practices.

#### Acceptance Criteria

1. THE IAM_Module SHALL place all Terraform HCL configuration files (`.tf` extension) in the `infra` directory at the project root, excluding state files, lock files, and `.terraform` directories.
2. THE IAM_Module SHALL define IAM role resources and their inline policies in a dedicated `roles.tf` file.
3. THE IAM_Module SHALL define Policy_Document data sources and IAM policy attachment resources in a dedicated `policies.tf` file.
4. THE IAM_Module SHALL define Terraform variables in a dedicated `variables.tf` file.
5. THE IAM_Module SHALL rely on the existing `main.tf` file specifying the AWS provider in the `us-east-1` region and the `terraform` block with required providers — this feature SHALL NOT create or modify `infra/main.tf`.
6. THE IAM_Module SHALL rely on the existing data sources (`aws_caller_identity`, `aws_region`) declared in `infra/main.tf` — this feature SHALL NOT redeclare them.
7. THE IAM_Module SHALL use the existing `data "aws_caller_identity"` and `data "aws_region"` for dynamic account and region references instead of hardcoded values.
8. THE IAM_Module SHALL apply a `Name` tag to all IAM role resources using the convention `geofoodtruck-<role-purpose>` where `<role-purpose>` is a lowercase, hyphen-separated identifier matching the role's function (e.g., `geofoodtruck-lambda-execution`, `geofoodtruck-cicd-deployment`).

### Requirement 4: Least Privilege Enforcement

**User Story:** As a security engineer, I want all IAM policies to follow least-privilege principles, so that no role has more permissions than required for its function.

#### Acceptance Criteria

1. THE IAM_Module SHALL scope all IAM policy resource ARNs to specific resources for the S3 app bucket, CloudFront distribution, and WAF log group rather than using wildcards.
2. THE IAM_Module SHALL grant only the actions explicitly listed in Requirements 1 and 2 for each role, with no additional actions beyond those documented for the role's function.
3. WHEN a role requires access to multiple services, THE IAM_Module SHALL define separate policy statements for each service.
4. THE IAM_Module SHALL use `data "aws_iam_policy_document"` for all custom policy definitions to enable Terraform validation and composition.
5. IF a wildcard resource ARN is necessary (e.g., for CloudWatch Logs with dynamic log stream names), THEN THE IAM_Module SHALL include a code comment on the policy statement explaining which dynamic resource requires the wildcard and why the ARN cannot be fully specified.
6. THE IAM_Module SHALL NOT use wildcard (`"*"`) in the Action field of any IAM policy statement; all permitted actions SHALL be individually enumerated.

### Requirement 5: KMS Key Policy - Administrative Access

**User Story:** As a cloud engineer, I want the KMS key policy to grant full administrative permissions to the designated admin role and the root account, so that authorized principals can manage the key lifecycle.

#### Acceptance Criteria

1. THE IAM_Module SHALL define a `data "aws_iam_policy_document"` with identifier `geofoodtruck_kms_key_policy` in `infra/policies.tf` containing a statement with `Effect` set to `Allow`, granting `kms:*` action on resource `*` to the KMS_Admin_Role ARN and the root account principal (`arn:aws:iam::<account_id>:root`).
2. THE IAM_Module SHALL reference the KMS_Admin_Role ARN dynamically from the `aws_iam_role.geofoodtruck_kms_admin_role` resource defined in `infra/roles.tf`.
3. THE IAM_Module SHALL reference the AWS account ID using the existing `var.aws_account_id` sensitive variable.

### Requirement 6: KMS Key Policy - CloudFront Service Access

**User Story:** As a cloud engineer, I want the KMS key policy to permit CloudFront to encrypt and decrypt data, so that CloudFront can serve encrypted content from S3 origins.

#### Acceptance Criteria

1. THE IAM_Module SHALL include a statement in the `geofoodtruck_kms_key_policy` policy document with Sid `AllowCloudFrontServiceAccess` and Effect `Allow`, granting `kms:Encrypt`, `kms:Decrypt`, and `kms:GenerateDataKey*` actions to the `cloudfront.amazonaws.com` service principal on resource `*`.

### Requirement 7: KMS Key Policy - Log Delivery Service Access

**User Story:** As a cloud engineer, I want the KMS key policy to permit the log delivery service to generate data keys and decrypt, so that AWS logging services can write encrypted log data.

#### Acceptance Criteria

1. THE IAM_Module SHALL include a statement in the `geofoodtruck_kms_key_policy` policy document with effect `Allow` granting `kms:GenerateDataKey*` and `kms:Decrypt` actions to the `delivery.logs.amazonaws.com` service principal on resource `*`.
2. THE IAM_Module SHALL condition the log delivery statement with a `StringEquals` test on `aws:SourceAccount` matching `var.aws_account_id`.

### Requirement 8: KMS Key Policy - CloudWatch Logs Service Access

**User Story:** As a cloud engineer, I want the KMS key policy to permit CloudWatch Logs to perform cryptographic operations, so that the WAF log group can be encrypted at rest.

#### Acceptance Criteria

1. THE IAM_Module SHALL include a statement in the `geofoodtruck_kms_key_policy` policy document with Effect `Allow` granting `kms:Encrypt*`, `kms:Decrypt*`, `kms:ReEncrypt*`, `kms:GenerateDataKey*`, and `kms:Describe*` actions on resource `*` to the regional CloudWatch Logs service principal (`logs.<region>.amazonaws.com`), where `<region>` is resolved from `data.aws_region.current.name`.
2. THE IAM_Module SHALL condition the CloudWatch Logs statement with an `ArnLike` test on `kms:EncryptionContext:aws:logs:arn` matching the pattern `arn:aws:logs:<region>:<account_id>:log-group:aws-waf-logs-geofoodtruck-log-group`.
3. THE IAM_Module SHALL use `data.aws_region.current.name` and `var.aws_account_id` for all dynamic references — no hardcoded region or account IDs.

### Requirement 9: KMS Admin Role Definition

**User Story:** As a cloud engineer, I want an IAM role provisioned for KMS key administration, so that key management operations are performed under a dedicated least-privilege role.

#### Acceptance Criteria

1. THE IAM_Module SHALL define an `aws_iam_role` resource in `infra/roles.tf` with the Terraform resource identifier `geofoodtruck_kms_admin_role` and the role name set to `GeoFoodTruckKmsAdmin`.
2. THE IAM_Module SHALL attach the `AWSKeyManagementServicePowerUser` managed policy using an `aws_iam_role_policy_attachment` resource in `infra/policies.tf`.
3. THE IAM_Module SHALL define an `aws_iam_role_policy_attachments_exclusive` resource in `infra/policies.tf` to ensure only explicitly declared policy attachments exist on the role.
4. THE IAM_Module SHALL configure the trust policy (assume role policy) to allow `sts:AssumeRole` by the account root principal (`arn:aws:iam::<account_id>:root`), referencing `var.aws_account_id`.
5. THE IAM_Module SHALL tag the role with `Name = "geofoodtruck-kms-admin"`.

### Requirement 10: KMS Key Policy Output for Cross-Feature Reference

**User Story:** As a cloud engineer, I want the KMS key policy document available for the customer-managed-kms feature to attach to the KMS key, so that policy management is centralized in the IAM feature.

#### Acceptance Criteria

1. THE IAM_Module SHALL ensure `data.aws_iam_policy_document.geofoodtruck_kms_key_policy.json` is available as a Terraform expression that the customer-managed-kms feature can reference for the `policy` attribute of the `aws_kms_key` resource.
