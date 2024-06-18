provider "azurerm" {
  use_oidc = true
  skip_provider_registration = true
  storage_use_azuread = true
  features {}
}

provider "azuread" {
}

data "azurerm_client_config" "current" {
}

data "azurerm_resource_group" "geofoodtruck_az_resource_group" {
  name = "geofoodtruck-rgp"
}

resource "azurerm_key_vault" "geofoodtruck_az_key_vault" {
  name                = "geofoodtruck-key-vault"
  location            = data.azurerm_resource_group.geofoodtruck_az_resource_group.location
  resource_group_name = data.azurerm_resource_group.geofoodtruck_az_resource_group.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  purge_protection_enabled    = true
}

resource "azurerm_key_vault_access_policy" "geofoodtruck_az_key_vault_access_policy_storage" {
  key_vault_id = azurerm_key_vault.geofoodtruck_az_key_vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_storage_account.geofoodtruck_az_storage_account.identity[0].principal_id

    key_permissions = [
      "Get",
      "UnwrapKey",
      "WrapKey"
    ]
}

resource "azurerm_key_vault_access_policy" "geofoodtruck_az_key_vault_access_policy_identity" {
  key_vault_id = azurerm_key_vault.geofoodtruck_az_key_vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

    key_permissions = [
      "Get",
      "Create",
      "Delete",
      "List",
      "Restore",
      "Recover",
      "UnwrapKey",
      "WrapKey",
      "Purge",
      "Encrypt",
      "Decrypt",
      "Sign",
      "Verify",
      "GetRotationPolicy",
      "SetRotationPolicy",
      "Update",
      "Backup",
      "Release",
      "Rotate",
      "Import",
    ]
}

resource "azurerm_key_vault_key" "geofoodtruck_az_key_vault_key" {
  name         = "geofoodtruckkey"
  key_vault_id = azurerm_key_vault.geofoodtruck_az_key_vault.id
  key_type     = "RSA"
  key_size     = 2048

    key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  rotation_policy {
    automatic {
      time_before_expiry = "P30D"
    }

    expire_after         = "P90D"
    notify_before_expiry = "P29D"
  }

  depends_on = [
    azurerm_key_vault_access_policy.geofoodtruck_az_key_vault_access_policy_storage,
    azurerm_key_vault_access_policy.geofoodtruck_az_key_vault_access_policy_identity
  ]
}

resource "azurerm_storage_account" "geofoodtruck_az_storage_account" {
  name                     = "geofoodtruck"
  resource_group_name      = data.azurerm_resource_group.geofoodtruck_az_resource_group.name
  location                 = data.azurerm_resource_group.geofoodtruck_az_resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  shared_access_key_enabled = false

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      customer_managed_key
    ]
  }
}

resource "azurerm_role_assignment" "geofoodtruck_az_role_assignment_managed_id" {
  scope                = azurerm_storage_account.geofoodtruck_az_storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_storage_encryption_scope" "geofoodtruck_az_storage_encryption_scope" {
  name               = "geofoodtruckmanagedscope"
  storage_account_id = azurerm_storage_account.geofoodtruck_az_storage_account.id
  key_vault_key_id   = azurerm_key_vault_key.geofoodtruck_az_key_vault_key.id
  source             = "Microsoft.KeyVault"
}

resource "azurerm_storage_account_customer_managed_key" "geofoodtruck_az_storage_account_customer_managed_key" {
  storage_account_id = azurerm_storage_account.geofoodtruck_az_storage_account.id
  key_vault_id       = azurerm_key_vault.geofoodtruck_az_key_vault.id
  key_name           = azurerm_key_vault_key.geofoodtruck_az_key_vault_key.name
}

resource "azurerm_storage_container" "geofoodtruck_az_storage_container" {
  name                  = "app"
  storage_account_name  = azurerm_storage_account.geofoodtruck_az_storage_account.name
  container_access_type = "blob"
}

resource "azurerm_storage_blob" "app_files" {
  depends_on = [
    azurerm_role_assignment.geofoodtruck_az_role_assignment_managed_id,
  ]

  for_each = { for file in local.app_build_files : file => file }
  storage_account_name = azurerm_storage_account.geofoodtruck_az_storage_account.name
  storage_container_name = azurerm_storage_container.geofoodtruck_az_storage_container.name
  type         = "Block"
  name         = each.value
  source       = "${var.app_build_dir}/${each.value}"
  content_type = lookup(
    local.content_types,
    element(split(".", each.value), length(split(".", each.value)) - 1),
    "application/octet-stream"
  )
  content_md5  = filemd5("${var.app_build_dir}/${each.value}")
}
