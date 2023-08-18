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

resource "azurerm_resource_group" "gm_rg" {
    name ="gm_rg"
    location = "East US"
}
