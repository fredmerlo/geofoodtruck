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
