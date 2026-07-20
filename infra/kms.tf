resource "aws_kms_key" "geofoodtruck_kms_key" {
  description              = "KMS key for GeoFoodTruck"
  is_enabled               = true
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  enable_key_rotation      = true
  rotation_period_in_days  = 180
  deletion_window_in_days  = 30
  multi_region             = false
  policy                   = data.aws_iam_policy_document.geofoodtruck_kms_key_policy.json

  tags = {
    Name = "geofoodtruck-kms-key"
  }
}

resource "aws_kms_alias" "geofoodtruck_kms_alias" {
  name          = "alias/geofoodtruck-kms-key"
  target_key_id = aws_kms_key.geofoodtruck_kms_key.key_id
}
