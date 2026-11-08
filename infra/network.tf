resource "azurerm_virtual_network" "dev" {
  name                = "vnet-${local.name}"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name
  address_space       = ["10.10.0.0/16"]
  tags                = local.tags
}

# Subnet de aplicación: aquí vive la VM
resource "azurerm_subnet" "app" {
  name                 = "snet-app"
  resource_group_name  = azurerm_resource_group.dev.name
  virtual_network_name = azurerm_virtual_network.dev.name
  address_prefixes     = ["10.10.1.0/24"]

  # La VM necesita salir a Internet para llegar al Key Vault (ver nota)
  default_outbound_access_enabled = true
}

# Subnet de datos: reservada, sin salida a Internet
resource "azurerm_subnet" "data" {
  name                 = "snet-data"
  resource_group_name  = azurerm_resource_group.dev.name
  virtual_network_name = azurerm_virtual_network.dev.name
  address_prefixes     = ["10.10.2.0/24"]

  default_outbound_access_enabled = false
}

resource "azurerm_network_security_group" "app" {
  name                = "nsg-${var.project}-app"
  location            = azurerm_resource_group.dev.location
  resource_group_name = azurerm_resource_group.dev.name
  tags                = local.tags

  # SSH solo desde dentro de la VNet
  security_rule {
    name                       = "Allow-SSH-From-VNet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  # Explícito y visible: nada entra desde Internet
  security_rule {
    name                       = "Deny-Internet-Inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app.id
}
