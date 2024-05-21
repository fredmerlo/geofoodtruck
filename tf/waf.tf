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
