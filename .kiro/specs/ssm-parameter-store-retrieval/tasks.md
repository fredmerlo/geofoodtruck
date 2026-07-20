# Implementation Plan

## Overview

Implement SSM Parameter Store retrieval in the existing `infra/` Terraform module. This feature adds an SSM parameter data source, a variable, and a sensitive output to the existing infrastructure. It does NOT create provider configuration, `aws_caller_identity`, or `aws_region` data sources — those are already managed in `infra/main.tf`.

## Tasks

- [x] 1. Add variable definition to existing infra/variables.tf
  - Append the `ssm_parameter_name` variable to `infra/variables.tf`
  - Declare variable of type `string` with description containing "SSM" and "parameter"
  - Set default value to `/geofoodtruck/sfgovkey`
  - Add validation block with regex `^/geofoodtruck/[a-zA-Z0-9._\\-]{1,128}$`
  - Include descriptive error_message indicating required format
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 5.1, 5.2, 5.3, 5.5_

- [x] 2. Create infra/ssm.tf with SSM parameter data source
  - Create `infra/ssm.tf` with only the `data "aws_ssm_parameter" "sfgov_geofoodtruck_aws_ssm_parameter"` block
  - Set `name = var.ssm_parameter_name`
  - Set `with_decryption = true`
  - Do NOT add `aws_caller_identity`, `aws_region`, provider blocks, or `required_providers` — these exist in `infra/main.tf`
  - _Requirements: 1.1, 1.2, 1.3, 3.1, 5.4, 7.1, 7.2, 7.3, 7.4, 8.2_

- [x] 3. Add output definition to existing infra/outputs.tf
  - Append `output "geofoodtruck_ssm_parameter_value"` to `infra/outputs.tf`
  - Set `description` explaining the output's purpose for API authentication
  - Set `value = data.aws_ssm_parameter.sfgov_geofoodtruck_aws_ssm_parameter.value`
  - Set `sensitive = true`
  - _Requirements: 4.1, 4.2, 4.3, 6.1, 6.3, 8.4_

- [x] 4. Validate module structure and correctness
  - Run `terraform fmt -check` on all files in `infra/`
  - Run `terraform validate` after `terraform init` in `infra/`
  - Verify `infra/ssm.tf` contains only the SSM parameter data source — no provider, no aws_caller_identity, no aws_region
  - Verify no `provisioner`, `null_resource`, or `terraform_data` blocks exist in the new files
  - _Requirements: 6.2, 8.1, 8.5_

## Task Dependency Graph

```json
{
  "waves": [
    {
      "name": "wave1",
      "tasks": [1, 2, 3],
      "description": "Add SSM variable, data source, and output to the existing infra/ module"
    },
    {
      "name": "wave2",
      "tasks": [4],
      "description": "Validate the module compiles and passes formatting checks",
      "dependsOn": ["wave1"]
    }
  ]
}
```

## Notes

- This feature adds to the EXISTING `infra/` module — it does not create `main.tf` or provider configuration.
- `data "aws_caller_identity" "current"`, `data "aws_region" "current"`, `required_providers`, and `provider "aws"` are already declared in `infra/main.tf` and must NOT be redeclared by this feature.
- No property-based testing applies since this is Infrastructure as Code (Terraform HCL).
- Correctness is validated through `terraform validate`, `terraform fmt`, and structural checks.
- The module does NOT include error-handling code — it relies on Terraform's native AWS API error surfacing.
