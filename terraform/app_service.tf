# Create App Service Plan
resource "azurerm_service_plan" "app_plan" {
  name                = "${var.project_name}-${var.environment}-plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type            = "Linux"
  sku_name           = var.app_service_sku
}

# Create Web App for Frontend
resource "azurerm_linux_web_app" "frontend" {
  name                = "${var.project_name}-${var.environment}-frontend"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.app_plan.id

  site_config {
    application_stack {
      node_version = "18-lts"
    }
    cors {
      allowed_origins = ["*"]
    }
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "DOCKER_REGISTRY_SERVER_URL"          = azurerm_container_registry.acr.login_server
    "DOCKER_REGISTRY_SERVER_USERNAME"     = azurerm_container_registry.acr.admin_username
    "DOCKER_REGISTRY_SERVER_PASSWORD"     = azurerm_container_registry.acr.admin_password
  }
}

# Create Web App for Backend
resource "azurerm_linux_web_app" "backend" {
  name                = "${var.project_name}-${var.environment}-backend"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.app_plan.id

  site_config {
    application_stack {
      node_version = "18-lts"
    }
    cors {
      allowed_origins = ["*"]
    }
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "DOCKER_REGISTRY_SERVER_URL"          = azurerm_container_registry.acr.login_server
    "DOCKER_REGISTRY_SERVER_USERNAME"     = azurerm_container_registry.acr.admin_username
    "DOCKER_REGISTRY_SERVER_PASSWORD"     = azurerm_container_registry.acr.admin_password
    "AZURE_STORAGE_CONNECTION_STRING"     = azurerm_storage_account.storage.primary_connection_string
    "OPENAI_API_KEY"                      = azurerm_cognitive_account.openai.primary_access_key
    "SPEECH_API_KEY"                      = azurerm_cognitive_account.speech.primary_access_key
    "SPEECH_REGION"                       = azurerm_cognitive_account.speech.location
  }
}