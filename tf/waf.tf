resource "aws_wafv2_web_acl" "geofoodtruck_waf_web_acl" {
  name        = "GeoFoodTruckWebACL"
  scope       = "CLOUDFRONT"
  description = "Web ACL for GeoFoodTruck app"

  default_action {
    allow {}
  }

  rule {
    name     = "GeoFoodTruck-AWSManagedRulesAmazonIpReputationList"
    priority = 0

    statement {
      managed_rule_group_statement {
        name = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "GeoFoodTruck-AWSManagedRulesAmazonIpReputationList"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "GeoFoodTruck-AWSManagedRulesCommonRuleSet"
    priority = 1

    statement {
      managed_rule_group_statement {
        name = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "GeoFoodTruck-AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "GeoFoodTruck-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    statement {
      managed_rule_group_statement {
        name = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "GeoFoodTruck-AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "GeoFoodTruck-AWSManagedRulesBotControlRuleSet"
    priority = 3

    statement {
      managed_rule_group_statement {
        name = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"

        managed_rule_group_configs {
          aws_managed_rules_bot_control_rule_set {
            inspection_level = "COMMON"
          }
        }

        rule_action_override {
          name = "CategoryAdvertising"
          action_to_use {
            count {}
          }
        }
        rule_action_override {
          name = "CategoryArchiver"
          action_to_use {
            count {}
          }
        }
        rule_action_override {
          name = "CategoryContentFetcher"
          action_to_use {
            count {}
          }
        }
        rule_action_override {
          name = "CategoryEmailClient"
          action_to_use {
            count {}
          }
        }
        rule_action_override {
          name = "CategoryHttpLibrary"
          action_to_use {
            count {}
          }
        }
        rule_action_override {
          name = "CategoryLinkChecker"
          action_to_use {
            count {}
          }
        }
        rule_action_override {
          name = "CategoryMiscellaneous"
          action_to_use {
            count {}
          }
        }
        rule_action_override {
          name = "CategoryMonitoring"
          action_to_use {
            count {}
          }
        }
        rule_action_override {
          name = "CategoryScrapingFramework"
          action_to_use {
            count {}
          }
        }
        rule_action_override {
          name = "CategorySearchEngine"
          action_to_use {
            count {}
          }
        }
        rule_action_override {
          name = "CategorySecurity"
          action_to_use {
            count {}
          }
        }
        rule_action_override {
          name = "CategorySeo"
          action_to_use {
            count {}
          }
        }
        rule_action_override {
          name = "CategorySocialMedia"
          action_to_use {
            count {}
          }
        }
        rule_action_override {
          name = "CategoryAI"
          action_to_use {
            count {}
          }
        }
        rule_action_override {
          name = "SignalAutomatedBrowser"
          action_to_use {
            count {}
          }
        }
        rule_action_override {
          name = "SignalKnownBotDataCenter"
          action_to_use {
            count {}
          }
        }
        rule_action_override {
          name = "SignalNonBrowserUserAgent"
          action_to_use {
            count {}
          }
        }
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "GeoFoodTruck-AWSManagedRulesBotControlRuleSet"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "GeoFoodTruckWebACL"
    sampled_requests_enabled   = true
  }
}

resource "aws_cloudwatch_log_group" "geofoodtruck_waf_log_group" {
  name = "aws-waf-logs-geofoodtruck-log-group"
  kms_key_id = aws_kms_key.geofoodtruck_kms_key.arn
}

resource "aws_wafv2_web_acl_logging_configuration" "geofoodtruck_waf_logging_configuration" {
  log_destination_configs = [aws_cloudwatch_log_group.geofoodtruck_waf_log_group.arn]
  resource_arn            = aws_wafv2_web_acl.geofoodtruck_waf_web_acl.arn
}

resource "aws_cloudwatch_log_resource_policy" "geofoodtruck_waf_log_resource_policy" {
  policy_document = data.aws_iam_policy_document.geofoodtruck_waf_log_policy_document.json
  policy_name     = "geofoodtruck-webacl-log-resource-policy"
}

data "aws_iam_policy_document" "geofoodtruck_waf_log_policy_document" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    principals {
      identifiers = ["delivery.logs.amazonaws.com"]
      type        = "Service"
    }
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.geofoodtruck_waf_log_group.arn}:*"]
    condition {
      test     = "ArnLike"
      values   = ["arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"]
      variable = "aws:SourceArn"
    }
    condition {
      test     = "StringEquals"
      values   = [tostring(data.aws_caller_identity.current.account_id)]
      variable = "aws:SourceAccount"
    }
  }
}

data "aws_caller_identity" "current" {}
