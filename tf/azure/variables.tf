variable "app_build_dir" {
  description = "Path to the application build directory"
  type        = string
  default     = "../../build"
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

  frontdoor_postfix = "19aab"
}
