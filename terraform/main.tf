# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.location
}

# Create Storage Account
resource "azurerm_storage_account" "storage" {
  name                     = lower(replace("${var.project_name}${var.environment}st", "-", ""))
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_replication_type

  blob_properties {
    cors_rule {
      allowed_headers    = ["*"]
      allowed_methods    = ["GET", "POST", "PUT"]
      allowed_origins    = ["*"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 3600
    }
  }
}

# Create Storage Container
resource "azurerm_storage_container" "videos" {
  name                  = "trainer-videos"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "blob"
}

# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "${var.project_name}-${var.environment}-rg"
  location = var.location
}

# Create Container Registry
resource "azurerm_container_registry" "acr" {
  name                = lower(replace("${var.project_name}${var.environment}acr", "-", ""))
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}