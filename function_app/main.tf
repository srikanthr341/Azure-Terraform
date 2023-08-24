
locals {
  resource_group="sa_rg"
  location="East US"
}


resource "azurerm_resource_group" "app_grp"{
  name=local.resource_group
  location=local.location
}

resource "azurerm_storage_account" "functionstore_089889" {
  name                     = "srikanthboyapalli"
  resource_group_name      = azurerm_resource_group.app_grp.name
  location                 = azurerm_resource_group.app_grp.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "function_app_plan" {
  name                = "function-app-plan"
  location            = azurerm_resource_group.app_grp.location
  resource_group_name = azurerm_resource_group.app_grp.name

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_function_app" "functionapp_1234000" {
  name                       = "sri-fa"
  location                   = azurerm_resource_group.app_grp.location
  resource_group_name        = azurerm_resource_group.app_grp.name
  app_service_plan_id        = azurerm_app_service_plan.function_app_plan.id
  storage_account_name       = azurerm_storage_account.functionstore_089889.name
  storage_account_access_key = azurerm_storage_account.functionstore_089889.primary_access_key

  app_settings = {
    APPINSIGHTS_INSTRUMENTATIONKEY = "${azurerm_application_insights.test.instrumentation_key}"
  }

  site_config {
    dotnet_framework_version = "v6.0"
  }
  
}


resource "azurerm_application_insights" "test" {
  name                = "test-terraform-insights"
  location            = "${azurerm_resource_group.app_grp.location}"
  resource_group_name = "${azurerm_resource_group.app_grp.name}"
  application_type    = "web"
}

