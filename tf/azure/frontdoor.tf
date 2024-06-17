resource "azurerm_cdn_frontdoor_profile" "geofoodtruck_az_cdn_frontdoor_profile" {
  name                = "geofoodtruck-frontdoor-profile"
  resource_group_name = data.azurerm_resource_group.geofoodtruck_az_resource_group.name
  location            = data.azurerm_resource_group.geofoodtruck_az_resource_group.location
  sku                 = "Standard_AzureFrontDoor"
}

resource "azurerm_cdn_frontdoor_endpoint" "geofoodtruck_az_cdn_frontdoor_endpoint" {
  name                     = "geofoodtruck-frontdoor-endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_profile.geofoodtruck_az_cdn_profile.id  
}

resource "azurerm_cdn_frontdoor_origin_group" "geofoodtruck_az_cdn_frontdoor_origin_group" {
  name                     = "geofoodtruck-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_profile.geofoodtruck_az_cdn_profile.id
  session_affinity_enabled = false

  health_probe {
    protocol            = "Https"
    interval_in_seconds = 30
  }

  load_balancing { }
}

resource "azurerm_cdn_frontdoor_origin" "geofoodtruck_az_cdn_frontdoor_app_store_origin" {
  name                     = "geofoodtruck-app-storage-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.geofoodtruck_az_cdn_frontdoor_origin_group.id

  certificate_name_check_enabled = true
  host_name                       = azurerm_storage_account.geofoodtruck_az_storage_account.primary_blob_endpoint
  origin_host_header              = azurerm_storage_account.geofoodtruck_az_storage_account.primary_blob_endpoint
  priority                        = 1
  weight                         = 500

  private_link {
    request_message        = "Request access for Private Link Origin CDN Frontdoor"
    target_type            = "blob"
    location               = azurerm_storage_account.geofoodtruck_az_storage_account.location
    private_link_target_id = azurerm_storage_account.geofoodtruck_az_storage_account.id
  }
}

resource "azurerm_cdn_frontdoor_rule_set" "geofoodtruck_az_cdn_frontdoor_rule_set" {
  name                     = "geofoodtruckruleset"
  cdn_frontdoor_profile_id = azurerm_cdn_profile.geofoodtruck_az_cdn_profile.id
}

resource "azurerm_cdn_frontdoor_route" "geofoodtruck_az_cdn_frontdoor_app_store_route" {
  name                     = "geofoodtruck-app-storage-route"
  cdn_frontdoor_endpoint_id = azurerm_cdn_frontdoor_endpoint.geofoodtruck_az_cdn_frontdoor_endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.geofoodtruck_az_cdn_frontdoor_origin_group.id
  cdn_frontdoor_origin_ids = [azurerm_cdn_frontdoor_origin.geofoodtruck_az_cdn_frontdoor_app_store_origin.id]
  cdn_frontdoor_rule_set_ids = [azurerm_cdn_frontdoor_rule_set.geofoodtruck_az_cdn_frontdoor_rule_set.id]

  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]

  cache {
    compression_enabled  = true
  }

}
