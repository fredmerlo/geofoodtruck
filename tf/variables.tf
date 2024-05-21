variable "app_build_dir" {
  description = "Path to the application build directory"
  type        = string
  default     = "../build"
}

variable "lambda_dir" {
  description = "Path to the lambda source directory"
  type        = string
  default     = "../lambda"
}

variable "aws_account_id" {
  description = "AWS account id"
  type        = string
  default     = "1234567890"
}

locals {
  app_build_files = fileset(var.app_build_dir, "**/**")

  content_types = {
    "html"  = "text/html"
    "css"   = "text/css"
    "js"    = "application/javascript"
    "png"   = "image/png"
    "ico"   = "image/x-icon"
    "txt"   = "text/plain"
    "json"  = "application/json"
    "map"   = "application/json"
  }
}
