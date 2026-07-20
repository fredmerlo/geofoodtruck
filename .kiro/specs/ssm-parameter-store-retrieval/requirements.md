# Requirements Document

## Introduction

This specification defines the Terraform HCL infrastructure for retrieving encrypted parameters from AWS Systems Manager (SSM) Parameter Store. The infrastructure enables secure retrieval of API keys and secrets stored in SSM Parameter Store using KMS decryption, making them available as Terraform outputs for consumption by other infrastructure resources such as CloudFront custom headers. All resources are defined in the `infra` directory at the project root.

## Glossary

- **SSM_Parameter_Data_Source**: A Terraform `data "aws_ssm_parameter"` resource that retrieves a parameter value from AWS Systems Manager Parameter Store
- **Parameter_Path**: The hierarchical name of an SSM parameter using forward-slash-delimited segments (e.g., `/geofoodtruck/sfgovkey`)
- **KMS_Decryption**: The process of decrypting a SecureString SSM parameter using AWS Key Management Service
- **Terraform_Output**: A declared output value in Terraform that exposes a computed value for use by other modules or resources
- **Infra_Module**: The Terraform configuration located in the `infra` directory at the project root
- **Parameter_Name_Variable**: A Terraform input variable that specifies the SSM parameter path, enabling flexible parameter name configuration without code changes

## Requirements

### Requirement 1: SSM Parameter Data Source Declaration

**User Story:** As a DevOps engineer, I want to declare SSM Parameter Store data sources in Terraform, so that I can retrieve encrypted parameter values for use in infrastructure resources.

#### Acceptance Criteria

1. THE Infra_Module SHALL declare exactly one Terraform `data "aws_ssm_parameter"` resource with the resource identifier following the `<purpose>_geofoodtruck_aws_ssm_parameter` naming convention (e.g., `sfgov_geofoodtruck_aws_ssm_parameter`)
2. THE SSM_Parameter_Data_Source SHALL specify `with_decryption = true` to enable KMS_Decryption of SecureString parameters
3. THE Infra_Module SHALL use the Parameter_Name_Variable as the `name` argument in the SSM_Parameter_Data_Source, resolving to the parameter path at plan time via `var.<variable_name>` reference syntax
4. IF the SSM parameter specified by Parameter_Name_Variable does not exist in the target AWS account and region, THEN THE Infra_Module SHALL surface the AWS API error during `terraform plan` or `terraform apply` without masking the parameter name that failed lookup

### Requirement 2: Parameter Naming Convention

**User Story:** As a DevOps engineer, I want SSM parameters to follow a consistent path hierarchy, so that parameters are organized and discoverable within the AWS account.

#### Acceptance Criteria

1. THE Infra_Module SHALL retrieve parameters using the `/geofoodtruck/` prefix path hierarchy
2. THE Parameter_Name_Variable SHALL have a default value of `/geofoodtruck/sfgovkey`
3. WHEN a Parameter_Path is specified, THE Infra_Module SHALL validate that the path matches the pattern starting with `/geofoodtruck/` followed by at least one character representing the parameter name segment
4. IF the Parameter_Path fails validation, THEN THE Infra_Module SHALL produce a Terraform variable validation error indicating the required `/geofoodtruck/<parameter_name>` format
5. THE Parameter_Name_Variable SHALL restrict the parameter name segment to alphanumeric characters, hyphens, underscores, and periods with a maximum length of 128 characters

### Requirement 3: KMS Decryption Integration

**User Story:** As a security engineer, I want SSM parameters to be decrypted using KMS at retrieval time, so that secrets remain encrypted at rest and are only decrypted when needed by Terraform.

#### Acceptance Criteria

1. THE SSM_Parameter_Data_Source SHALL enable decryption by setting `with_decryption = true`
2. WHEN the SSM_Parameter_Data_Source retrieves a SecureString parameter, THE Infra_Module SHALL require the IAM execution role to have both `kms:Decrypt` permission on the GeoFoodTruck KMS key and `ssm:GetParameter` permission on the target parameter path
3. IF the KMS_Decryption fails due to insufficient permissions, a disabled KMS key, or a deleted KMS key, THEN THE Infra_Module SHALL surface the AWS API error to the Terraform operator without additional error-handling code, relying on Terraform's native data source failure behavior
4. THE SSM_Parameter_Data_Source SHALL decrypt parameters using the GeoFoodTruck KMS key, which is a symmetric key with key usage `ENCRYPT_DECRYPT`

### Requirement 4: Terraform Output of Parameter Values

**User Story:** As a DevOps engineer, I want the retrieved SSM parameter value exposed as a Terraform output, so that other resources (such as CloudFront custom headers) can consume the decrypted value.

#### Acceptance Criteria

1. THE Infra_Module SHALL declare a Terraform_Output with a resource identifier prefixed with `geofoodtruck_` that exposes the decrypted parameter value from the SSM_Parameter_Data_Source and includes a `description` attribute explaining the output's purpose
2. THE Terraform_Output SHALL be marked as `sensitive = true` to prevent the decrypted value from appearing in CLI output or logs
3. THE Terraform_Output SHALL set its `value` attribute to the `.value` property of the SSM_Parameter_Data_Source, referencing the decrypted parameter content

### Requirement 5: Variable-Driven Parameter Names

**User Story:** As a DevOps engineer, I want SSM parameter names to be configurable through Terraform variables, so that I can reuse the configuration across environments without modifying the HCL source.

#### Acceptance Criteria

1. THE Infra_Module SHALL declare a Terraform input variable of type `string` for the SSM parameter name
2. THE Parameter_Name_Variable SHALL include a `description` attribute containing at minimum the words "SSM" and "parameter" to indicate the variable controls the SSM parameter path
3. THE Parameter_Name_Variable SHALL have a default value of `/geofoodtruck/sfgovkey`
4. THE SSM_Parameter_Data_Source SHALL use `var.<parameter_name_variable>` as its `name` argument instead of a hardcoded string literal
5. THE Parameter_Name_Variable SHALL include a `validation` block that rejects values not starting with a forward slash (`/`) character

### Requirement 6: Security and Sensitive Value Handling

**User Story:** As a security engineer, I want decrypted parameter values to be treated as sensitive throughout the Terraform lifecycle, so that secrets are not inadvertently exposed in plan output, state logs, or console output.

#### Acceptance Criteria

1. THE Infra_Module SHALL mark every `output` block that references a value derived from a `data.aws_ssm_parameter` resource (where `with_decryption = true`) with `sensitive = true`
2. THE Infra_Module SHALL NOT contain any `provisioner` block (including `local-exec` and `remote-exec`), `null_resource`, or `terraform_data` resource that references or could log a decrypted parameter value
3. WHEN Terraform renders the execution plan, THE Infra_Module SHALL ensure decrypted parameter values appear as `(sensitive value)` in all plan and apply output by applying the `sensitive` attribute on every variable, output, and local that carries or derives from the decrypted value
4. THE Infra_Module SHALL mark any `variable` block used to pass a decrypted parameter value into or between modules with `sensitive = true`

### Requirement 7: AWS Provider and Shared Data Sources

**User Story:** As a DevOps engineer, I want the SSM parameter retrieval to use the shared AWS provider and data sources already configured in the infrastructure module, so that there is no duplication of provider or identity configurations.

#### Acceptance Criteria

1. THE Infra_Module SHALL rely on the existing `terraform` block with `required_providers` in `infra/main.tf` — this feature SHALL NOT declare its own provider configuration
2. THE Infra_Module SHALL rely on the existing AWS provider configured with `region = "us-east-1"` in `infra/main.tf`
3. THE Infra_Module SHALL rely on the existing `data "aws_caller_identity" "current"` data source declared in `infra/main.tf` — this feature SHALL NOT redeclare it
4. THE Infra_Module SHALL rely on the existing `data "aws_region" "current"` data source declared in `infra/main.tf` — this feature SHALL NOT redeclare it

### Requirement 8: Infra Directory Structure

**User Story:** As a DevOps engineer, I want the SSM parameter retrieval resources to be added to the existing `infra` directory, so that they integrate with the already-established infrastructure module.

#### Acceptance Criteria

1. THIS feature SHALL add resources to the existing `infra/` directory — it SHALL NOT create `main.tf` or modify the existing provider configuration
2. THE Infra_Module SHALL include a `ssm.tf` file containing only the `data "aws_ssm_parameter"` data source declaration
3. THE Infra_Module SHALL add the Parameter_Name_Variable declaration to the existing `infra/variables.tf` file
4. THE Infra_Module SHALL add the Terraform_Output declaration to the existing `infra/outputs.tf` file
5. THE Infra_Module SHALL NOT include Terraform state files, `.terraform` directories, or `.terraform.lock.hcl` files in the `infra` directory under version control
