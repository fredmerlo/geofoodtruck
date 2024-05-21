provider "aws" {
  region = "us-east-1"
}

data "archive_file" "geofoodtruck_xss_lambda_zip" {
  type        = "zip"
  source_dir  = "${var.lambda_dir}/xss"
  output_path = "${var.lambda_dir}/geofoodtruck_xss_lambda.zip"
}

data "aws_iam_policy" "aws_policy_geofoodtruck_s3_read_only" {
  arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

data "aws_iam_policy_document" "aws_iam_policy_geofoodtruck_xss_lambda_basic_execution" {
  statement {
    actions = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_role" "aws_iam_role_geofoodtruck_xss_lambda_role" {
  name                = "AWSGeoFoodTruckLambdaRole"

  assume_role_policy  = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "edgelambda.amazonaws.com"
          ]
        }
      }
    ]
  })

  inline_policy {
    name   = "AWSGeoFoodTruckLambdaRoleBasicExecution"
    policy = data.aws_iam_policy_document.aws_iam_policy_geofoodtruck_xss_lambda_basic_execution.json
  }

  managed_policy_arns = [data.aws_iam_policy.aws_policy_geofoodtruck_s3_read_only.arn]
}

resource "aws_lambda_function" "geofoodtruck_xss_lambda_edge" {
  filename         = data.archive_file.geofoodtruck_xss_lambda_zip.output_path
  function_name    = "GeoFoodTruckXssLambda"
  role             = aws_iam_role.aws_iam_role_geofoodtruck_xss_lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  publish          = true
  source_code_hash = data.archive_file.geofoodtruck_xss_lambda_zip.output_base64sha256
  skip_destroy     = true
}
