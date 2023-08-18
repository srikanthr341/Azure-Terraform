terraform {
   required_providers {
     azurerm = {
        source = "hashicorp/azurerm"
        version = "=2.52.0"
     }
   }
}

provider "azurerm" {
    features {
    }
}

resource "azurerm_resource_group" "sa_rg" {
    name ="sa_rg"
    location = "East US"
}

resource "azurerm_storage_account" "storage" {
  name                     = "srikanthboyapalli"
  resource_group_name      = azurerm_resource_group.sa_rg.name
  location                 = azurerm_resource_group.sa_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_blob_public_access = true
}