# Requirements Document

## Introduction

This document specifies the requirements for a WAFv2 Web ACL Terraform module that protects the GeoFoodTruck CloudFront distribution. The module provisions an AWS WAFv2 Web ACL with four managed rule groups (including Bot Control with action overrides), CloudWatch logging with KMS encryption, and a log resource policy for log delivery. All resources are defined in Terraform HCL within an `infra` directory at the project root.

## Glossary

- **Web_ACL**: An AWS WAFv2 Web Access Control List that inspects and filters HTTP requests to protected resources
- **Managed_Rule_Group**: A pre-configured set of WAF rules maintained by AWS that can be referenced by a Web ACL
- **Bot_Control_Rule_Group**: The AWSManagedRulesBotControlRuleSet managed rule group that detects and categorizes bot traffic
- **Rule_Action_Override**: A configuration that changes the action for a specific rule within a managed rule group from block to count
- **Log_Group**: An AWS CloudWatch Logs log group that stores WAF request logs
- **Logging_Configuration**: An AWS WAFv2 resource that connects a Web ACL to a log destination
- **Log_Resource_Policy**: An AWS CloudWatch Logs resource policy that grants a service permission to write logs
- **KMS_Key**: An AWS Key Management Service encryption key used to encrypt log data at rest
- **Terraform_Module**: A set of Terraform HCL files organized in a directory that define related infrastructure resources
- **Infra_Directory**: The `infra` directory at the project root containing the Terraform module files

## Requirements

### Requirement 1: WAFv2 Web ACL Resource Definition

**User Story:** As a DevOps engineer, I want a WAFv2 Web ACL configured for CloudFront scope with a permissive default action, so that legitimate traffic is allowed while managed rules can inspect and act on malicious requests.

#### Acceptance Criteria

1. THE Terraform_Module SHALL define an `aws_wafv2_web_acl` resource with the identifier `geofoodtruck_waf_web_acl` and scope set to "CLOUDFRONT"
2. THE Web_ACL SHALL use "GeoFoodTruckWebACL" as the resource name
3. THE Web_ACL SHALL include a description of "Web ACL for GeoFoodTruck app"
4. THE Web_ACL SHALL configure the default action to allow requests with an empty `allow {}` block (no custom headers or responses)
5. THE Web_ACL SHALL include a top-level `visibility_config` block with `cloudwatch_metrics_enabled` set to true, metric name set to "GeoFoodTruckWebACL", and `sampled_requests_enabled` set to true
6. THE Web_ACL SHALL contain exactly 4 rule blocks corresponding to the managed rule groups defined in Requirements 2 through 5

### Requirement 2: IP Reputation Managed Rule Group

**User Story:** As a DevOps engineer, I want the AWS IP Reputation List rule group attached to the Web ACL, so that known malicious IP addresses are blocked.

#### Acceptance Criteria

1. THE Web_ACL SHALL include a rule referencing the AWSManagedRulesAmazonIpReputationList managed rule group from vendor "AWS"
2. THE Web_ACL SHALL assign priority 0 to the IP Reputation rule
3. THE Web_ACL SHALL set the override action to none for the IP Reputation rule
4. THE Web_ACL SHALL enable CloudWatch metrics for the IP Reputation rule with metric name "GeoFoodTruck-AWSManagedRulesAmazonIpReputationList" and sampled requests enabled

### Requirement 3: Common Rule Set Managed Rule Group

**User Story:** As a DevOps engineer, I want the AWS Common Rule Set attached to the Web ACL, so that common web exploits such as SQL injection and cross-site scripting are blocked.

#### Acceptance Criteria

1. THE Web_ACL SHALL include a rule referencing the AWSManagedRulesCommonRuleSet managed rule group from vendor "AWS"
2. THE Web_ACL SHALL assign priority 1 to the Common Rule Set rule
3. THE Web_ACL SHALL set the override action to none for the Common Rule Set rule
4. THE Web_ACL SHALL enable CloudWatch metrics for the Common Rule Set rule with metric name "GeoFoodTruck-AWSManagedRulesCommonRuleSet" and sampled requests enabled

### Requirement 4: Known Bad Inputs Managed Rule Group

**User Story:** As a DevOps engineer, I want the AWS Known Bad Inputs Rule Set attached to the Web ACL, so that requests with known malicious patterns are blocked.

#### Acceptance Criteria

1. THE Web_ACL SHALL include a rule referencing the AWSManagedRulesKnownBadInputsRuleSet managed rule group from vendor "AWS"
2. THE Web_ACL SHALL assign priority 2 to the Known Bad Inputs rule
3. THE Web_ACL SHALL set the override action to none for the Known Bad Inputs rule
4. THE Web_ACL SHALL enable CloudWatch metrics for the Known Bad Inputs rule with metric name "GeoFoodTruck-AWSManagedRulesKnownBadInputsRuleSet" and sampled requests enabled

### Requirement 5: Bot Control Managed Rule Group with Action Overrides

**User Story:** As a DevOps engineer, I want the AWS Bot Control Rule Set attached to the Web ACL with specific bot categories set to count-only mode, so that bot traffic is monitored without blocking legitimate automated access.

#### Acceptance Criteria

1. THE Web_ACL SHALL include a rule named "GeoFoodTruck-AWSManagedRulesBotControlRuleSet" referencing the AWSManagedRulesBotControlRuleSet managed rule group from vendor "AWS"
2. THE Web_ACL SHALL assign priority 3 to the Bot Control rule
3. THE Web_ACL SHALL set the override action to `none {}` for the Bot Control rule, allowing individual rule actions within the group to take effect
4. THE Bot_Control_Rule_Group SHALL configure the inspection level to "COMMON" within the `managed_rule_group_configs` block
5. THE Bot_Control_Rule_Group SHALL include exactly 17 `rule_action_override` entries, each setting the action to `count {}` for the following rules: CategoryAdvertising, CategoryArchiver, CategoryContentFetcher, CategoryEmailClient, CategoryHttpLibrary, CategoryLinkChecker, CategoryMiscellaneous, CategoryMonitoring, CategoryScrapingFramework, CategorySearchEngine, CategorySecurity, CategorySeo, CategorySocialMedia, CategoryAI, SignalAutomatedBrowser, SignalKnownBotDataCenter, SignalNonBrowserUserAgent
6. IF a bot rule is not listed in the 17 Rule_Action_Override entries, THEN THE Bot_Control_Rule_Group SHALL apply the managed rule group's default action (block) to that rule
7. THE Web_ACL SHALL enable CloudWatch metrics for the Bot Control rule with metric name "GeoFoodTruck-AWSManagedRulesBotControlRuleSet" and `sampled_requests_enabled` set to true

### Requirement 6: CloudWatch Log Group for WAF Logging

**User Story:** As a DevOps engineer, I want a KMS-encrypted CloudWatch Log Group for WAF logs, so that request data is stored securely and meets compliance requirements.

#### Acceptance Criteria

1. THE Terraform_Module SHALL define an `aws_cloudwatch_log_group` resource with name "aws-waf-logs-geofoodtruck-log-group"
2. THE Log_Group SHALL set the `kms_key_id` attribute to the value of the KMS key ARN variable defined in criterion 3
3. THE Terraform_Module SHALL define a variable of type `string` for the KMS key ARN, allowing the encryption key to be supplied externally by the calling module
4. THE Log_Group SHALL configure `retention_in_days` to retain logs indefinitely (no expiration) to meet compliance retention requirements

### Requirement 7: WAFv2 Web ACL Logging Configuration

**User Story:** As a DevOps engineer, I want the Web ACL connected to the CloudWatch Log Group, so that all WAF request logs are captured for monitoring and analysis.

#### Acceptance Criteria

1. THE Terraform_Module SHALL define an `aws_wafv2_web_acl_logging_configuration` resource
2. THE Logging_Configuration SHALL set the `log_destination_configs` attribute to a single-element list containing the Log_Group ARN
3. THE Logging_Configuration SHALL set the `resource_arn` attribute to the Web_ACL ARN defined in Requirement 1
4. IF the Log_Group or Web_ACL resource does not exist, THEN THE Terraform_Module SHALL fail at plan time due to unresolved resource references

### Requirement 8: CloudWatch Log Resource Policy

**User Story:** As a DevOps engineer, I want a CloudWatch Log Resource Policy that grants the log delivery service permission to write to the WAF log group, so that WAF can deliver logs without manual IAM intervention.

#### Acceptance Criteria

1. THE Terraform_Module SHALL define an `aws_cloudwatch_log_resource_policy` resource with the identifier `geofoodtruck_waf_log_resource_policy` and policy name "geofoodtruck-webacl-log-resource-policy"
2. THE Terraform_Module SHALL reference the existing `data.aws_iam_policy_document.geofoodtruck_waf_log_delivery` defined in `infra/policies.tf` by the iam-roles-and-policy-documents feature — this feature SHALL NOT define its own policy document for WAF log delivery
3. THE Log_Resource_Policy SHALL set `policy_document = data.aws_iam_policy_document.geofoodtruck_waf_log_delivery.json`
4. THE existing WAF_Logging_Policy in `infra/policies.tf` grants `logs:CreateLogStream` and `logs:PutLogEvents` to `delivery.logs.amazonaws.com`, scoped to the WAF log group ARN with `:*` suffix, with ArnLike and StringEquals conditions — this feature relies on that definition being correct

### Requirement 9: Terraform Module Structure and Outputs

**User Story:** As a DevOps engineer, I want the WAF resources organized as a Terraform module in the `infra` directory with appropriate outputs, so that the Web ACL ARN can be referenced by the CloudFront distribution.

#### Acceptance Criteria

1. THE Terraform_Module SHALL place all resource definitions in the Infra_Directory at the project root
2. THE Terraform_Module SHALL define a Terraform output named "web_acl_arn" that exposes the Web_ACL ARN value for CloudFront association
3. THE Terraform_Module SHALL rely on the existing AWS provider configured with region "us-east-1" in `infra/main.tf` — this feature SHALL NOT declare its own provider configuration
4. THE Terraform_Module SHALL use the `geofoodtruck_` prefix for all Terraform resource identifier labels (the local names used in HCL `resource` blocks)
5. THE Terraform_Module SHALL use the "GeoFoodTruck" prefix for AWS resource display names (the `name` attribute values visible in the AWS console)
6. THE Terraform_Module SHALL rely on the existing `main.tf` file containing the `terraform` block and provider configuration — this feature SHALL NOT create or modify `infra/main.tf`
