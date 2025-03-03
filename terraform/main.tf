# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.90.0"
    }
  }
  backend "azurerm" {
    # You should configure this according to your environment
    # resource_group_name  = "tfstate"
    # storage_account_name = "tfstate"
    # container_name       = "tfstate"
    # key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# Variables
variable "resource_group_name" {
  description = "Name of the resource group"
  default     = "education-platform-rg"
}

variable "location" {
  description = "Azure region to deploy resources"
  default     = "East US"
}

variable "environment" {
  description = "Environment (dev, test, prod)"
  default     = "dev"
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    Environment = var.environment
  }
}

# Storage Account for lesson content, transcripts, and media
resource "azurerm_storage_account" "storage" {
  name                     = "eduplatformstorage${var.environment}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  #enable_https_traffic_only = true
  min_tls_version          = "TLS1_2"

  blob_properties {
    cors_rule {
      allowed_headers    = ["*"]
      allowed_methods    = ["GET", "HEAD", "POST", "PUT", "DELETE"]
      allowed_origins    = ["*"] # In production, restrict to your domains
      exposed_headers    = ["*"]
      max_age_in_seconds = 3600
    }
  }

  tags = {
    Environment = var.environment
  }
}

# Create containers for different types of content
resource "azurerm_storage_container" "lessons" {
  name                  = "lessons"
  storage_account_id    = azurerm_storage_account.example.id
  container_access_type = "blob"
}

resource "azurerm_storage_container" "media" {
  name                  = "media"
  storage_account_id    = azurerm_storage_account.example.id
  container_access_type = "blob"
}

resource "azurerm_storage_container" "transcripts" {
  name                  = "transcripts"
  storage_account_id    = azurerm_storage_account.example.id
  container_access_type = "blob"
}

# Cognitive Services - Azure Speech Services
resource "azurerm_cognitive_account" "speech" {
  name                = "eduplatform-speech-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "SpeechServices"
  sku_name            = "S0"

  tags = {
    Environment = var.environment
  }
}

# Cognitive Services - Azure OpenAI
resource "azurerm_cognitive_account" "openai" {
  name                = "eduplatform-openai-${var.environment}"
  location            = azurerm_resource_group.rg.location # Note: OpenAI might only be available in specific regions
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "OpenAI"
  sku_name            = "S0"

  tags = {
    Environment = var.environment
  }
}

# OpenAI Model Deployment (GPT-4)
resource "azurerm_cognitive_deployment" "gpt4" {
  name                 = "gpt4-deployment"
  cognitive_account_id = azurerm_cognitive_account.openai.id
  model {
    format  = "OpenAI"
    name    = "gpt-4" # or "gpt-4o" for the latest model
    version = "0314"   # Specify the appropriate version
  }
  sku {
    name = "Standard"
  }
}

# App Service Plan for the backend
resource "azurerm_service_plan" "backend" {
  name                = "eduplatform-backend-plan-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "P1v2" # Production workload with reasonable performance

  tags = {
    Environment = var.environment
  }
}

# App Service for the backend API
resource "azurerm_linux_web_app" "backend" {
  name                = "eduplatform-backend-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.backend.id

  site_config {
    always_on        = true
    application_stack {
      node_version   = "18-lts"
    }
    cors {
      allowed_origins = ["*"] # Restrict in production
    }
  }

  app_settings = {
    "WEBSITE_NODE_DEFAULT_VERSION" = "~18"
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.insights.instrumentation_key
    
    # Storage settings
    "AZURE_STORAGE_CONNECTION_STRING" = azurerm_storage_account.storage.primary_connection_string
    
    # Speech service settings
    "SPEECH_KEY" = azurerm_cognitive_account.speech.primary_access_key
    "SPEECH_REGION" = azurerm_resource_group.rg.location
    
    # OpenAI settings
    "OPENAI_API_KEY" = azurerm_cognitive_account.openai.primary_access_key
    "OPENAI_API_ENDPOINT" = azurerm_cognitive_account.openai.endpoint
    "OPENAI_DEPLOYMENT_NAME" = azurerm_cognitive_deployment.gpt4.name
  }

  tags = {
    Environment = var.environment
  }
}

# Static Web App for the frontend
resource "azurerm_static_site" "frontend" {
  name                = "eduplatform-frontend-${var.environment}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku_tier            = "Standard"
  
  tags = {
    Environment = var.environment
  }
}

# Application Insights for monitoring
resource "azurerm_application_insights" "insights" {
  name                = "eduplatform-insights-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
  
  tags = {
    Environment = var.environment
  }
}

# Key Vault for secrets management
resource "azurerm_key_vault" "vault" {
  name                     = "eduplatform-kv-${var.environment}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  tenant_id                = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days = 7
  purge_protection_enabled = false
  sku_name                 = "standard"

  tags = {
    Environment = var.environment
  }
}

# Get current client configuration
data "azurerm_client_config" "current" {}

# Key Vault Access Policy for the backend app
resource "azurerm_key_vault_access_policy" "backend" {
  key_vault_id = azurerm_key_vault.vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_linux_web_app.backend.identity[0].principal_id

  key_permissions = [
    "Get",
  ]

  secret_permissions = [
    "Get",
    "List",
  ]
}

# Key Vault Access Policy for Terraform/deployment user
resource "azurerm_key_vault_access_policy" "terraform" {
  key_vault_id = azurerm_key_vault.vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get", "List", "Create", "Delete", "Update",
  ]

  secret_permissions = [
    "Get", "List", "Set", "Delete",
  ]
}

# Store sensitive credentials in Key Vault
resource "azurerm_key_vault_secret" "storage_connection" {
  name         = "storage-connection-string"
  value        = azurerm_storage_account.storage.primary_connection_string
  key_vault_id = azurerm_key_vault.vault.id
  depends_on   = [azurerm_key_vault_access_policy.terraform]
}

resource "azurerm_key_vault_secret" "speech_key" {
  name         = "speech-key"
  value        = azurerm_cognitive_account.speech.primary_access_key
  key_vault_id = azurerm_key_vault.vault.id
  depends_on   = [azurerm_key_vault_access_policy.terraform]
}

resource "azurerm_key_vault_secret" "openai_key" {
  name         = "openai-key"
  value        = azurerm_cognitive_account.openai.primary_access_key
  key_vault_id = azurerm_key_vault.vault.id
  depends_on   = [azurerm_key_vault_access_policy.terraform]
}

# Cosmos DB for structured data (lesson metadata, user progress)
resource "azurerm_cosmosdb_account" "db" {
  name                = "eduplatform-cosmos-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "MongoDB"
  
  capabilities {
    name = "EnableMongo"
  }
  
  capabilities {
    name = "DisableRateLimitingResponses"
  }

  consistency_policy {
    consistency_level       = "Session"
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }

  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0
  }

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_cosmosdb_mongo_database" "database" {
  name                = "education-platform"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.db.name
  throughput          = 400
}

# Cognitive Services - Face API for Avatar
resource "azurerm_cognitive_account" "face" {
  name                = "eduplatform-face-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "Face"
  sku_name            = "S0"

  tags = {
    Environment = var.environment
  }
}

# Cognitive Services - Custom Vision for avatars
resource "azurerm_cognitive_account" "vision" {
  name                = "eduplatform-vision-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "CustomVision.Training"
  sku_name            = "S0"

  tags = {
    Environment = var.environment
  }
}

# Outputs
output "backend_url" {
  value = "https://${azurerm_linux_web_app.backend.default_hostname}"
}

output "frontend_url" {
  value = azurerm_static_site.frontend.default_host_name
}

output "storage_account_name" {
  value = azurerm_storage_account.storage.name
}

output "openai_endpoint" {
  value = azurerm_cognitive_account.openai.endpoint
}

output "speech_region" {
  value = azurerm_cognitive_account.speech.location
}