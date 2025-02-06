output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "storage_account_name" {
  value = azurerm_storage_account.storage.name
}

output "storage_connection_string" {
  value     = azurerm_storage_account.storage.primary_connection_string
  sensitive = true
}

output "openai_endpoint" {
  value = azurerm_cognitive_account.openai.endpoint
}

output "speech_endpoint" {
  value = azurerm_cognitive_account.speech.endpoint
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "frontend_url" {
  value = "https://${azurerm_linux_web_app.frontend.default_hostname}"
}

output "backend_url" {
  value = "https://${azurerm_linux_web_app.backend.default_hostname}"
}