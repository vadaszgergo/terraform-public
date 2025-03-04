terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "xxxxxxxxxx"
}

# Create a Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "free-appservice-rg"
  location = "West US"
}

# Create an App Service Plan (F1 Free Tier)
resource "azurerm_service_plan" "appserviceplan" {
  name                = "free-appservice-plan"
  resource_group_name = azurerm_resource_group.rg.name
  location           = azurerm_resource_group.rg.location
  os_type            = "Linux"
  sku_name           = "F1"  # Free tier
}

# Create an App Service with a Docker Container
resource "azurerm_linux_web_app" "webapp" {
  name                = "ipcalculator-app"  # Name your App Service
  resource_group_name = azurerm_resource_group.rg.name
  location           = azurerm_resource_group.rg.location
  service_plan_id    = azurerm_service_plan.appserviceplan.id

  site_config {
    application_stack {
      docker_image_name = "vadaszgergo/ip-tools:latest"  # Pick your preferred docker image based on your requirements
    }
    always_on = false # Free tier doesn't allow you to use always_on = true
  }
  depends_on = [azurerm_service_plan.appserviceplan]  # Ensure App Service Plan exists first

}

