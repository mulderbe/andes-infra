output "resource_group_name" {
  value = azurerm_resource_group.dev.name
}

output "vm_name" {
  value = azurerm_linux_virtual_machine.app01.name
}

output "vm_private_ip" {
  value = azurerm_network_interface.app01.private_ip_address
}

output "key_vault_name" {
  value = azurerm_key_vault.dev.name
}
