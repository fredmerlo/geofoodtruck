resource "aws_iam_role" "geofoodtruck_lambda_execution" {
  name               = "GeoFoodTruckLambdaExecution"
  assume_role_policy = data.aws_iam_policy_document.geofoodtruck_lambda_assume_role.json

  inline_policy {
    name   = "GeoFoodTruckLambdaBasicExecution"
    policy = data.aws_iam_policy_document.geofoodtruck_lambda_logging.json
  }

  managed_policy_arns = [data.aws_iam_policy.geofoodtruck_s3_read_only.arn]

  tags = {
    Name = "geofoodtruck-lambda-execution"
  }
}

resource "aws_iam_role" "geofoodtruck_kms_admin_role" {
  name = "GeoFoodTruckKmsAdmin"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          AWS = "arn:aws:iam::${var.aws_account_id}:root"
        }
      }
    ]
  })

  tags = {
    Name = "geofoodtruck-kms-admin"
  }
}
