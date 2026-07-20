data "aws_ssm_parameter" "sfgov_geofoodtruck_aws_ssm_parameter" {
  name            = var.ssm_parameter_name
  with_decryption = true
}
