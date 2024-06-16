terraform {
  backend "azurerm" {
    resource_group_name   = "geofoodtruck-rgp"
    storage_account_name  = "geofoodtruckterraform"
    container_name        = "state"
    key                   = "terraform.tfstate"
    use_oidc              = true
  }
}
