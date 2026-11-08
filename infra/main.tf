# Quién está ejecutando Terraform (sp-andes-iac)
data "azurerm_client_config" "current" {}

# Sufijo aleatorio para nombres que deben ser únicos en todo Azure
resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

locals {
  name = "${var.project}-${var.environment}" # "andes-dev"

  tags = {
    project     = var.project
    environment = var.environment
    owner       = var.owner
    managed_by  = "terraform"
  }
}

resource "azurerm_resource_group" "dev" {
  name     = "rg-${local.name}"
  location = var.location
  tags     = local.tags
}
