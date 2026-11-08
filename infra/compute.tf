resource "azurerm_network_interface" "app01" {
  name                = "nic-${var.project}-app01"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name
  tags                = local.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"
    # Sin public_ip_address_id: la VM no tiene IP pública
  }
}

resource "azurerm_linux_virtual_machine" "app01" {
  name                            = "vm-${var.project}-app01"
  location                        = azurerm_resource_group.dev.location
  resource_group_name             = azurerm_resource_group.dev.name
  size                            = var.vm_size
  admin_username                  = "azureadmin"
  admin_password                  = random_password.vm_admin.result
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.app01.id]
  disk_controller_type            = "NVMe"
  tags                            = local.tags

  # Managed Identity: la VM tiene su propia identidad en Entra ID
  identity {
    type = "SystemAssigned"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  boot_diagnostics {} # usa un storage administrado por Azure, sin costo extra
}

# La VM puede LEER secretos del Key Vault (y nada más)
resource "azurerm_role_assignment" "kv_user_vm" {
  scope                = azurerm_key_vault.dev.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_virtual_machine.app01.identity[0].principal_id
  principal_type       = "ServicePrincipal"
}

# Alerta: CPU > 80 % durante 5 minutos -> correo
resource "azurerm_monitor_metric_alert" "cpu" {
  name                = "alert-${var.project}-cpu"
  resource_group_name = azurerm_resource_group.dev.name
  scopes              = [azurerm_linux_virtual_machine.app01.id]
  description         = "CPU de vm-andes-app01 sobre 80 % por 5 minutos"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  tags                = local.tags

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.dev.id
  }
}
