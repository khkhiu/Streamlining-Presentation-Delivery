variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "education-platform-rg"
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "East US"
}

variable "environment" {
  description = "Environment (dev, test, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be one of: dev, test, prod."
  }
}

variable "storage_account_name" {
  description = "Name of the storage account (must be globally unique)"
  type        = string
  default     = null # Will use the default from main.tf if not provided
}

variable "openai_sku" {
  description = "SKU for OpenAI service"
  type        = string
  default     = "S0"
}

variable "backend_service_plan_sku" {
  description = "SKU for backend service plan"
  type        = string
  default     = "P1v2"
}

variable "mongodb_throughput" {
  description = "MongoDB throughput (RU/s)"
  type        = number
  default     = 400
  validation {
    condition     = var.mongodb_throughput >= 400 && var.mongodb_throughput <= 100000
    error_message = "MongoDB throughput must be between 400 and 100,000 RU/s."
  }
}

variable "cosmos_db_locations" {
  description = "Locations for Cosmos DB geo-replication"
  type        = list(string)
  default     = [] # Will use the primary location by default
}

variable "allowed_origins" {
  description = "CORS allowed origins for the backend API"
  type        = list(string)
  default     = ["*"] # In production, restrict to specific domains
}

variable "tags" {
  description = "Additional tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "openai_model_name" {
  description = "Name of the OpenAI model to deploy"
  type        = string
  default     = "gpt-4"
}

variable "openai_model_version" {
  description = "Version of the OpenAI model to deploy"
  type        = string
  default     = "0314"
}

variable "key_vault_sku" {
  description = "SKU for Key Vault"
  type        = string
  default     = "standard"
}

variable "node_version" {
  description = "Node.js version for the backend"
  type        = string
  default     = "18-lts"
}