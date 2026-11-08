resource "azurerm_log_analytics_workspace" "dev" {
  name                = "log-${local.name}"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

resource "azurerm_monitor_action_group" "dev" {
  name                = "ag-${local.name}"
  resource_group_name = azurerm_resource_group.dev.name
  short_name          = "andesdev" # máximo 12 caracteres, sale en el SMS/correo
  tags                = local.tags

  email_receiver {
    name                    = "owner"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }
}
