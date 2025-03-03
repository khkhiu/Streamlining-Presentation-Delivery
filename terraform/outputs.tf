output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.rg.name
}

output "resource_group_location" {
  description = "Location of the created resource group"
  value       = azurerm_resource_group.rg.location
}

output "storage_account_name" {
  description = "Name of the created storage account"
  value       = azurerm_storage_account.storage.name
}

output "storage_account_primary_blob_endpoint" {
  description = "Primary blob endpoint of the storage account"
  value       = azurerm_storage_account.storage.primary_blob_endpoint
}

output "storage_account_primary_connection_string" {
  description = "Primary connection string of the storage account"
  value       = azurerm_storage_account.storage.primary_connection_string
  sensitive   = true
}

output "speech_service_key" {
  description = "Key for accessing Speech Service"
  value       = azurerm_cognitive_account.speech.primary_access_key
  sensitive   = true
}

output "speech_service_endpoint" {
  description = "Endpoint for Speech Service"
  value       = azurerm_cognitive_account.speech.endpoint
}

output "openai_key" {
  description = "Key for accessing OpenAI Service"
  value       = azurerm_cognitive_account.openai.primary_access_key
  sensitive   = true
}

output "openai_endpoint" {
  description = "Endpoint for OpenAI Service"
  value       = azurerm_cognitive_account.openai.endpoint
}

output "openai_deployment_name" {
  description = "Name of the deployed OpenAI model"
  value       = azurerm_cognitive_deployment.gpt4.name
}

output "backend_app_url" {
  description = "URL of the backend application"
  value       = "https://${azurerm_linux_web_app.backend.default_hostname}"
}

output "frontend_url" {
  description = "URL of the frontend application"
  value       = azurerm_static_site.frontend.default_host_name
}

output "cosmos_db_connection_string" {
  description = "Connection string for Cosmos DB"
  value       = azurerm_cosmosdb_account.db.connection_strings[0]
  sensitive   = true
}

output "cosmos_db_endpoint" {
  description = "Endpoint for Cosmos DB"
  value       = azurerm_cosmosdb_account.db.endpoint
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.vault.vault_uri
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = azurerm_application_insights.insights.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string for Application Insights"
  value       = azurerm_application_insights.insights.connection_string
  sensitive   = true
}

output "face_api_key" {
  description = "Key for accessing Face API"
  value       = azurerm_cognitive_account.face.primary_access_key
  sensitive   = true
}

output "face_api_endpoint" {
  description = "Endpoint for Face API"
  value       = azurerm_cognitive_account.face.endpoint
}

output "vision_api_key" {
  description = "Key for accessing Custom Vision API"
  value       = azurerm_cognitive_account.vision.primary_access_key
  sensitive   = true
}

output "vision_api_endpoint" {
  description = "Endpoint for Custom Vision API"
  value       = azurerm_cognitive_account.vision.endpoint
}