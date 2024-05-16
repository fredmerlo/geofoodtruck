variable "app_build_dir" {
  description = "Path to the application build directory"
  type        = string
  default     = "../build"
}

locals {
  app_build_files = fileset(var.react_build_dir, "**/**")
}
