resource "azurerm_cdn_frontdoor_profile" "geofoodtruck_az_cdn_frontdoor_profile" {
  name                = "geofoodtruck-frontdoor-profile-${local.frontdoor_postfix}"
  resource_group_name = data.azurerm_resource_group.geofoodtruck_az_resource_group.name
  sku_name                 = "Premium_AzureFrontDoor"
}

resource "azurerm_cdn_frontdoor_endpoint" "geofoodtruck_az_cdn_frontdoor_endpoint" {
  depends_on               = [azurerm_cdn_frontdoor_profile.geofoodtruck_az_cdn_frontdoor_profile]

  name                     = "geofoodtruck-${local.frontdoor_postfix}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.geofoodtruck_az_cdn_frontdoor_profile.id
  enabled                  = true
}

resource "azurerm_cdn_frontdoor_origin_group" "geofoodtruck_az_cdn_frontdoor_origin_group" {
  depends_on               = [azurerm_cdn_frontdoor_profile.geofoodtruck_az_cdn_frontdoor_profile]

  name                     = "geofoodtruck-origin-group-${local.frontdoor_postfix}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.geofoodtruck_az_cdn_frontdoor_profile.id
  session_affinity_enabled = false

  health_probe {
    protocol            = "Http"
    interval_in_seconds = 100
    path                = "/"
    request_type        = "HEAD"
  }

  load_balancing {
    additional_latency_in_milliseconds = 50
    sample_size                        = 4
    successful_samples_required        = 3
  }
}

resource "azurerm_cdn_frontdoor_origin" "geofoodtruck_az_cdn_frontdoor_app_store_origin" {
  depends_on               = [azurerm_cdn_frontdoor_profile.geofoodtruck_az_cdn_frontdoor_profile,
                              azurerm_cdn_frontdoor_origin_group.geofoodtruck_az_cdn_frontdoor_origin_group]

  name                     = "geofoodtruck-app-storage-origin-${local.frontdoor_postfix}"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.geofoodtruck_az_cdn_frontdoor_origin_group.id
  enabled                       = true

  certificate_name_check_enabled = true
  host_name                       = azurerm_storage_account.geofoodtruck_az_storage_account.primary_blob_host
  origin_host_header              = azurerm_storage_account.geofoodtruck_az_storage_account.primary_blob_host
  priority                        = 1
  weight                         = 500

  private_link {
    request_message        = "Request access for Private Link Origin CDN Frontdoor"
    target_type            = "blob"
    location               = azurerm_storage_account.geofoodtruck_az_storage_account.location
    private_link_target_id = azurerm_storage_account.geofoodtruck_az_storage_account.id
  }
}

resource "azurerm_cdn_frontdoor_origin" "geofoodtruck_az_cdn_frontdoor_data_sforg_origin" {
  depends_on               = [azurerm_cdn_frontdoor_profile.geofoodtruck_az_cdn_frontdoor_profile,
                              azurerm_cdn_frontdoor_origin_group.geofoodtruck_az_cdn_frontdoor_origin_group,
                              azurerm_cdn_frontdoor_origin.geofoodtruck_az_cdn_frontdoor_app_store_origin]

  name                     = "geofoodtruck-data-sforg-origin-${local.frontdoor_postfix}"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.geofoodtruck_az_cdn_frontdoor_origin_group.id
  enabled                       = true

  certificate_name_check_enabled = false
  host_name                       = "data.sforg.gov"
  origin_host_header              = "data.sforg.gov"
  priority                        = 1
  weight                         = 500
}

resource "azurerm_cdn_frontdoor_route" "geofoodtruck_az_cdn_frontdoor_app_store_route" {
  depends_on               = [azurerm_cdn_frontdoor_profile.geofoodtruck_az_cdn_frontdoor_profile,
                              azurerm_cdn_frontdoor_endpoint.geofoodtruck_az_cdn_frontdoor_endpoint,
                              azurerm_cdn_frontdoor_origin_group.geofoodtruck_az_cdn_frontdoor_origin_group,
                              azurerm_cdn_frontdoor_origin.geofoodtruck_az_cdn_frontdoor_app_store_origin]

  name                     = "geofoodtruck-app-storage-route-${local.frontdoor_postfix}"
  cdn_frontdoor_endpoint_id = azurerm_cdn_frontdoor_endpoint.geofoodtruck_az_cdn_frontdoor_endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.geofoodtruck_az_cdn_frontdoor_origin_group.id
  cdn_frontdoor_origin_ids = [azurerm_cdn_frontdoor_origin.geofoodtruck_az_cdn_frontdoor_app_store_origin.id]
  cdn_frontdoor_origin_path = "/app"

  link_to_default_domain = true
  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]
}

resource "azurerm_cdn_frontdoor_rule_set" "geofoodtruck_az_cdn_frontdoor_data_sforg_rule_set" {
  depends_on               = [azurerm_cdn_frontdoor_profile.geofoodtruck_az_cdn_frontdoor_profile,
                              azurerm_cdn_frontdoor_endpoint.geofoodtruck_az_cdn_frontdoor_endpoint,
                              azurerm_cdn_frontdoor_origin_group.geofoodtruck_az_cdn_frontdoor_origin_group,
                              azurerm_cdn_frontdoor_origin.geofoodtruck_az_cdn_frontdoor_app_store_origin,
                              azurerm_cdn_frontdoor_origin.geofoodtruck_az_cdn_frontdoor_data_sforg_origin]

  name                     = "geofoodtruckdatasforgruleset${local.frontdoor_postfix}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.geofoodtruck_az_cdn_frontdoor_profile.id
}

resource "azurerm_cdn_frontdoor_rule" "geofoodtruck_az_cdn_frontdoor_data_sforg_rule" {
  depends_on               = [azurerm_cdn_frontdoor_profile.geofoodtruck_az_cdn_frontdoor_profile,
                              azurerm_cdn_frontdoor_endpoint.geofoodtruck_az_cdn_frontdoor_endpoint,
                              azurerm_cdn_frontdoor_origin_group.geofoodtruck_az_cdn_frontdoor_origin_group,
                              azurerm_cdn_frontdoor_origin.geofoodtruck_az_cdn_frontdoor_app_store_origin,
                              azurerm_cdn_frontdoor_origin.geofoodtruck_az_cdn_frontdoor_data_sforg_origin,
                              azurerm_cdn_frontdoor_route.geofoodtruck_az_cdn_frontdoor_app_store_route,
                              azurerm_cdn_frontdoor_rule_set.geofoodtruck_az_cdn_frontdoor_data_sforg_rule_set]

  name                      = "geofoodtruckdatasforgrule${local.frontdoor_postfix}"
  cdn_frontdoor_rule_set_id = azurerm_cdn_frontdoor_rule_set.geofoodtruck_az_cdn_frontdoor_data_sforg_rule_set.id

  actions {
    request_header_action {
      header_action = "Append"
      header_name   = "X-App-Token"
      value         = "GrXGgigVGyUzWjE0ppVRMRUgR"
    }
  }

  conditions {
    request_header_condition {
      header_name = "X-App-Token"
      operator     = "NotAny"
    }
  }
}

resource "azurerm_cdn_frontdoor_route" "geofoodtruck_az_cdn_frontdoor_data_sforg_route" {
  depends_on               = [azurerm_cdn_frontdoor_profile.geofoodtruck_az_cdn_frontdoor_profile,
                              azurerm_cdn_frontdoor_endpoint.geofoodtruck_az_cdn_frontdoor_endpoint,
                              azurerm_cdn_frontdoor_origin_group.geofoodtruck_az_cdn_frontdoor_origin_group,
                              azurerm_cdn_frontdoor_origin.geofoodtruck_az_cdn_frontdoor_app_store_origin,
                              azurerm_cdn_frontdoor_origin.geofoodtruck_az_cdn_frontdoor_data_sforg_origin,
                              azurerm_cdn_frontdoor_route.geofoodtruck_az_cdn_frontdoor_app_store_route,
                              azurerm_cdn_frontdoor_rule_set.geofoodtruck_az_cdn_frontdoor_data_sforg_rule_set,
                              azurerm_cdn_frontdoor_rule.geofoodtruck_az_cdn_frontdoor_data_sforg_rule]

  name                     = "geofoodtruck-data-sforg-route-${local.frontdoor_postfix}"
  cdn_frontdoor_endpoint_id = azurerm_cdn_frontdoor_endpoint.geofoodtruck_az_cdn_frontdoor_endpoint.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.geofoodtruck_az_cdn_frontdoor_origin_group.id
  cdn_frontdoor_origin_ids = [azurerm_cdn_frontdoor_origin.geofoodtruck_az_cdn_frontdoor_data_sforg_origin.id]
  cdn_frontdoor_rule_set_ids = [azurerm_cdn_frontdoor_rule_set.geofoodtruck_az_cdn_frontdoor_data_sforg_rule_set.id]

  link_to_default_domain = true
  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  patterns_to_match      = ["/resource/rqzj-sfat.json"]
  supported_protocols    = ["Http", "Https"]
}
