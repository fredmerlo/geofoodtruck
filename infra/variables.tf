variable "aws_account_id" {
  description = "AWS account ID for IAM principal ARN construction"
  type        = string
  sensitive   = true

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aws_account_id))
    error_message = "aws_account_id must be a 12-digit numeric string."
  }
}

variable "ssm_parameter_name" {
  description = "SSM parameter path for the GeoFoodTruck API key"
  type        = string
  default     = "/geofoodtruck/sfgovkey"

  validation {
    condition     = can(regex("^/geofoodtruck/[a-zA-Z0-9._\\-]{1,128}$", var.ssm_parameter_name))
    error_message = "Parameter name must follow /geofoodtruck/<parameter_name> format where parameter_name contains alphanumeric characters, hyphens, underscores, or periods (max 128 chars)."
  }
}

variable "app_build_dir" {
  description = "Path to the application build directory"
  type        = string
  default     = "../build"
}

locals {
  app_build_files = fileset(var.app_build_dir, "**/**")

  content_types = {
    "html" = "text/html"
    "css"  = "text/css"
    "js"   = "application/javascript"
    "png"  = "image/png"
    "ico"  = "image/x-icon"
    "txt"  = "text/plain"
    "json" = "application/json"
    "map"  = "application/json"
  }
}

variable "kms_key_arn" {
  description = "ARN of the KMS key used to encrypt the WAF CloudWatch Log Group"
  type        = string
}
