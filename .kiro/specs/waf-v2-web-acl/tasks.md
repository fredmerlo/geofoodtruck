# Implementation Plan: WAFv2 Web ACL Terraform Module

## Overview

This plan implements WAF resources in the existing `infra/` directory that provision an AWS WAFv2 Web ACL with four managed rule groups, CloudWatch logging with KMS encryption, and a log resource policy. Tasks are ordered by resource dependency: variable and file creation first, then the Web ACL, logging infrastructure, IAM policy, and finally outputs and validation. This feature does NOT create provider configuration, `aws_caller_identity`, or `aws_region` data sources — those are already managed in `infra/main.tf`.

## Tasks

- [x] 1. Create module structure and variable
  - [x] 1.1 Add the `kms_key_arn` input variable to existing `infra/variables.tf`
    - Append `variable "kms_key_arn"` of type `string` with description "ARN of the KMS key used to encrypt the WAF CloudWatch Log Group"
    - _Requirements: 6.3, 9.1_

  - [x] 1.2 Create `infra/waf.tf` for WAF resources
    - Create the file that will hold all WAF-related resources
    - Do NOT create `infra/main.tf` or add provider/required_providers — these exist already
    - Do NOT add `aws_caller_identity` or `aws_region` data sources — these are managed in `infra/main.tf`
    - _Requirements: 8.7, 9.3, 9.6_

- [x] 2. Implement WAFv2 Web ACL resource with managed rule groups
  - [x] 2.1 Add Web ACL resource shell with default action and top-level visibility_config
    - Define `resource "aws_wafv2_web_acl" "geofoodtruck_waf_web_acl"` in `infra/waf.tf`
    - Set `name = "GeoFoodTruckWebACL"`, `scope = "CLOUDFRONT"`, `description = "Web ACL for GeoFoodTruck app"`
    - Configure `default_action { allow {} }`
    - Add top-level `visibility_config` with `cloudwatch_metrics_enabled = true`, `metric_name = "GeoFoodTruckWebACL"`, `sampled_requests_enabled = true`
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

  - [x] 2.2 Add IP Reputation managed rule group (priority 0)
    - Add rule block with `name = "GeoFoodTruck-AWSManagedRulesAmazonIpReputationList"` and `priority = 0`
    - Configure `managed_rule_group_statement` with `name = "AWSManagedRulesAmazonIpReputationList"` and `vendor_name = "AWS"`
    - Set `override_action { none {} }`
    - Add `visibility_config` with metric name `"GeoFoodTruck-AWSManagedRulesAmazonIpReputationList"`, metrics enabled, sampled requests enabled
    - _Requirements: 2.1, 2.2, 2.3, 2.4_

  - [x] 2.3 Add Common Rule Set managed rule group (priority 1)
    - Add rule block with `name = "GeoFoodTruck-AWSManagedRulesCommonRuleSet"` and `priority = 1`
    - Configure `managed_rule_group_statement` with `name = "AWSManagedRulesCommonRuleSet"` and `vendor_name = "AWS"`
    - Set `override_action { none {} }`
    - Add `visibility_config` with metric name `"GeoFoodTruck-AWSManagedRulesCommonRuleSet"`, metrics enabled, sampled requests enabled
    - _Requirements: 3.1, 3.2, 3.3, 3.4_

  - [x] 2.4 Add Known Bad Inputs managed rule group (priority 2)
    - Add rule block with `name = "GeoFoodTruck-AWSManagedRulesKnownBadInputsRuleSet"` and `priority = 2`
    - Configure `managed_rule_group_statement` with `name = "AWSManagedRulesKnownBadInputsRuleSet"` and `vendor_name = "AWS"`
    - Set `override_action { none {} }`
    - Add `visibility_config` with metric name `"GeoFoodTruck-AWSManagedRulesKnownBadInputsRuleSet"`, metrics enabled, sampled requests enabled
    - _Requirements: 4.1, 4.2, 4.3, 4.4_

  - [x] 2.5 Add Bot Control managed rule group (priority 3) with 17 rule action overrides
    - Add rule block with `name = "GeoFoodTruck-AWSManagedRulesBotControlRuleSet"` and `priority = 3`
    - Configure `managed_rule_group_statement` with `name = "AWSManagedRulesBotControlRuleSet"` and `vendor_name = "AWS"`
    - Add `managed_rule_group_configs` with `aws_managed_rules_bot_control_rule_set { inspection_level = "COMMON" }`
    - Add all 17 `rule_action_override` blocks with `action_to_use { count {} }` for: CategoryAdvertising, CategoryArchiver, CategoryContentFetcher, CategoryEmailClient, CategoryHttpLibrary, CategoryLinkChecker, CategoryMiscellaneous, CategoryMonitoring, CategoryScrapingFramework, CategorySearchEngine, CategorySecurity, CategorySeo, CategorySocialMedia, CategoryAI, SignalAutomatedBrowser, SignalKnownBotDataCenter, SignalNonBrowserUserAgent
    - Set `override_action { none {} }`
    - Add `visibility_config` with metric name `"GeoFoodTruck-AWSManagedRulesBotControlRuleSet"`, metrics enabled, sampled requests enabled
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7_

- [x] 3. Checkpoint - Validate Web ACL structure
  - Ensure `terraform validate` passes on the `infra/` directory, ask the user if questions arise.

- [x] 4. Implement CloudWatch logging infrastructure
  - [x] 4.1 Add CloudWatch Log Group resource
    - Define `resource "aws_cloudwatch_log_group" "geofoodtruck_waf_log_group"` in `infra/waf.tf`
    - Set `name = "aws-waf-logs-geofoodtruck-log-group"`
    - Set `kms_key_id = var.kms_key_arn`
    - Omit `retention_in_days` (defaults to indefinite retention)
    - _Requirements: 6.1, 6.2, 6.4_

  - [x] 4.2 Add WAFv2 Logging Configuration resource
    - Define `resource "aws_wafv2_web_acl_logging_configuration" "geofoodtruck_waf_logging_configuration"` in `infra/waf.tf`
    - Set `log_destination_configs = [aws_cloudwatch_log_group.geofoodtruck_waf_log_group.arn]`
    - Set `resource_arn = aws_wafv2_web_acl.geofoodtruck_waf_web_acl.arn`
    - _Requirements: 7.1, 7.2, 7.3, 7.4_

- [x] 5. Implement log resource policy using existing policy document
  - [x] 5.1 Add CloudWatch Log Resource Policy referencing existing policy document
    - Define `resource "aws_cloudwatch_log_resource_policy" "geofoodtruck_waf_log_resource_policy"` in `infra/waf.tf`
    - Set `policy_document = data.aws_iam_policy_document.geofoodtruck_waf_log_delivery.json` (defined in `infra/policies.tf` by the iam-roles-and-policy-documents feature)
    - Set `policy_name = "geofoodtruck-webacl-log-resource-policy"`
    - Do NOT create a `data "aws_iam_policy_document"` in `infra/waf.tf` — the policy document already exists in `infra/policies.tf`
    - _Requirements: 8.1, 8.2, 8.3, 8.4_

- [x] 6. Add module outputs
  - [x] 6.1 Create `infra/outputs.tf` with Web ACL ARN output
    - Define `output "web_acl_arn"` with `description = "ARN of the WAFv2 Web ACL for CloudFront association"`
    - Set `value = aws_wafv2_web_acl.geofoodtruck_waf_web_acl.arn`
    - _Requirements: 9.2, 9.4, 9.5_

- [x] 7. Final checkpoint - Validate complete module
  - Run `terraform validate` and `terraform fmt -check` against the `infra/` directory. Ensure all resources pass validation, ask the user if questions arise.

## Notes

- This feature adds to the EXISTING `infra/` module — it does not create `main.tf` or provider configuration.
- `data "aws_caller_identity" "current"`, `data "aws_region" "current"`, `required_providers`, and `provider "aws"` are already declared in `infra/main.tf` and must NOT be redeclared by this feature.
- The design uses HCL (Terraform), so no language selection is needed.
- No property-based tests are applicable — correctness properties are verified through `terraform validate` and plan-based assertions.
- Each task references specific requirements for traceability.
- Checkpoints ensure incremental validation via `terraform validate`.
- The Bot Control rule group task (2.5) is the largest single task due to 17 rule action overrides.
- The WAF log delivery policy document (`data.aws_iam_policy_document.geofoodtruck_waf_log_delivery`) is defined in `infra/policies.tf` by the iam-roles-and-policy-documents feature and must NOT be redefined by this feature.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2"] },
    { "id": 1, "tasks": ["2.1"] },
    { "id": 2, "tasks": ["2.2", "2.3", "2.4", "2.5"] },
    { "id": 3, "tasks": ["4.1"] },
    { "id": 4, "tasks": ["4.2", "5.1"] },
    { "id": 5, "tasks": ["6.1"] }
  ]
}
```
