terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.50" # cualquier 4.x desde la 4.50, nunca la 5.0
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }

  # El state vive en el Storage de la Parte 1
  backend "azurerm" {
    resource_group_name  = "rg-andes-tfstate"
    storage_account_name = "standestfstate0811"
    container_name       = "tfstate"
    key                  = "andes-dev.tfstate"
    use_azuread_auth     = true # entra con Entra ID, no con llaves
  }
}

provider "azurerm" {
  features {
    key_vault {
      # Al hacer destroy, borra el Key Vault de verdad (no lo deja en la papelera)
      purge_soft_delete_on_destroy = true
    }
  }
  # Suscripción, tenant, client ID y secreto (u OIDC) salen de las variables ARM_*
}
