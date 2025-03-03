variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
}

variable "environment" {
  description = "Environment (dev, test, prod)"
  type        = string
}

variable "app_service_id" {
  description = "App Service ID to secure"
  type        = string
}

variable "storage_account_id" {
  description = "Storage Account ID to secure"
  type        = string
}

variable "cosmos_db_id" {
  description = "Cosmos DB ID to secure"
  type        = string
}

variable "key_vault_id" {
  description = "Key Vault ID to secure"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Azure Security Center
resource "azurerm_security_center_subscription_pricing" "app_service" {
  tier          = "Standard"
  resource_type = "AppServices"
}

resource "azurerm_security_center_subscription_pricing" "storage" {
  tier          = "Standard"
  resource_type = "StorageAccounts"
}

resource "azurerm_security_center_subscription_pricing" "key_vault" {
  tier          = "Standard"
  resource_type = "KeyVaults"
}

resource "azurerm_security_center_subscription_pricing" "cosmos_db" {
  tier          = "Standard"
  resource_type = "CosmosDBs"
}

# Security Center Contact
resource "azurerm_security_center_contact" "example" {
  name  = "contact"
  email = "khiu_kim_hong@outlook.com"
  #phone = "+1-555-555-5555"

  alert_notifications = true
  alerts_to_admins    = true
}

# Security Center Auto Provisioning
resource "azurerm_security_center_auto_provisioning" "main" {
  auto_provision = "On"
}

# Azure Policy Assignments
resource "azurerm_policy_assignment" "require_https" {
  name                 = "eduplatform-require-https-${var.environment}"
  scope                = var.app_service_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/a4af4a39-4135-47fb-b175-47fbdf85311d" # Require HTTPS for App Services
  display_name         = "Web applications should only be accessible over HTTPS"
  description          = "Ensures that web applications are only accessible over HTTPS"

  parameters = <<PARAMETERS
  {
    "effect": {
      "value": "Audit"
    }
  }
PARAMETERS
}

resource "azurerm_policy_assignment" "secure_transfer" {
  name                 = "eduplatform-secure-transfer-${var.environment}"
  scope                = var.storage_account_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/404c3081-a854-4457-ae30-26a93ef643f9" # Require secure transfer for storage accounts
  display_name         = "Secure transfer to storage accounts should be enabled"
  description          = "Ensures that secure transfer is enabled for storage accounts"

  parameters = <<PARAMETERS
  {
    "effect": {
      "value": "Audit"
    }
  }
PARAMETERS
}

# Web Application Firewall (WAF) for App Service
resource "azurerm_cdn_frontdoor_profile" "main" {
  name                = "eduplatform-fd-${var.environment}"
  resource_group_name = var.resource_group_name
  sku_name            = "Standard_AzureFrontDoor"

  tags = var.tags
}

resource "azurerm_cdn_frontdoor_firewall_policy" "main" {
  name                = "eduplatform-waf-${var.environment}"
  resource_group_name = var.resource_group_name
  sku_name            = azurerm_cdn_frontdoor_profile.main.sku_name
  enabled             = true
  mode                = "Prevention"

  managed_rule {
    type    = "DefaultRuleSet"
    version = "1.0"
    action  = "Block"
  }

  managed_rule {
    type    = "Microsoft_BotManagerRuleSet"
    version = "1.0"
    action  = "Block"
  }

  tags = var.tags
}

# Private Endpoint for Key Vault
resource "azurerm_subnet" "privateendpoints" {
  name                 = "privateendpoints-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]

  #enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_virtual_network" "main" {
  name                = "eduplatform-vnet-${var.environment}"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_private_endpoint" "keyvault" {
  name                = "eduplatform-kv-pe-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.privateendpoints.id

  private_service_connection {
    name                           = "keyvault-privateserviceconnection"
    private_connection_resource_id = var.key_vault_id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  tags = var.tags
}

# Azure DDoS Protection Plan
resource "azurerm_network_ddos_protection_plan" "main" {
  name                = "eduplatform-ddos-protection-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Associate the DDoS protection plan with the VNet
resource "azurerm_virtual_network" "ddos_protected" {
  name                = "eduplatform-vnet-protected-${var.environment}"
  address_space       = ["10.1.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name

  ddos_protection_plan {
    id     = azurerm_network_ddos_protection_plan.main.id
    enable = true
  }

  tags = var.tags
}

# IP Restriction for App Service
resource "azurerm_app_service_virtual_network_swift_connection" "main" {
  app_service_id = var.app_service_id
  subnet_id      = azurerm_subnet.app_service.id
}

resource "azurerm_subnet" "app_service" {
  name                 = "appservice-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]

  delegation {
    name = "appServiceDelegation"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# Outputs
output "policy_assignment_id" {
  description = "ID of the secure HTTPS policy assignment"
  value       = azurerm_policy_assignment.require_https.id
}

output "waf_policy_id" {
  description = "ID of the WAF policy"
  value       = azurerm_cdn_frontdoor_firewall_policy.main.id
}

output "key_vault_private_endpoint_id" {
  description = "ID of the Key Vault private endpoint"
  value       = azurerm_private_endpoint.keyvault.id
}

output "ddos_protection_plan_id" {
  description = "ID of the DDoS protection plan"
  value       = azurerm_network_ddos_protection_plan.main.id
}