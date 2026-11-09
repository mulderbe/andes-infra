resource "azurerm_key_vault" "dev" {
  name                          = "kv-${local.name}-${random_string.suffix.result}"
  location                      = azurerm_resource_group.dev.location
  resource_group_name           = azurerm_resource_group.dev.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  rbac_authorization_enabled    = true # permisos con roles, no con access policies
  soft_delete_retention_days    = 7
  purge_protection_enabled      = false # en prod: true
  public_network_access_enabled = true  # el runner de GitHub entra por Internet
  tags                          = local.tags
}

# 1) Terraform (sp-andes-iac) se da permiso para escribir secretos
resource "azurerm_role_assignment" "kv_officer_terraform" {
  scope                = azurerm_key_vault.dev.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
  principal_type       = "ServicePrincipal"
}

# 2) Los roles tardan en aplicarse: espera antes de escribir
resource "time_sleep" "wait_rbac" {
  depends_on      = [azurerm_role_assignment.kv_officer_terraform]
  create_duration = "90s"
}

# 3) Contraseña aleatoria que cumple la complejidad de Azure
resource "random_password" "vm_admin" {
  length           = 24
  special          = true
  override_special = "!#$%*()-_=+[]"
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
}

# 4) La contraseña se guarda en el Key Vault
resource "azurerm_key_vault_secret" "vm_admin_password" {
  name         = "vm-admin-password"
  value        = random_password.vm_admin.result
  key_vault_id = azurerm_key_vault.dev.id
  content_type = "password"
  depends_on   = [time_sleep.wait_rbac]
}

# 5) Auditoría: cada acceso al Key Vault queda en Log Analytics
resource "azurerm_monitor_diagnostic_setting" "kv" {
  name                       = "diag-to-law"
  target_resource_id         = azurerm_key_vault.dev.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.dev.id

  enabled_log {
    category = "AuditEvent"
  }
}
