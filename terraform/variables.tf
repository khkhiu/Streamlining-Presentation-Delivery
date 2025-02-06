variable "project_name" {
  description = "Name of the project, used as prefix for all resources"
  type        = string
  default     = "virtual-trainer"
}

variable "location" {
  description = "Azure region where resources will be created"
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "storage_account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
}

variable "storage_replication_type" {
  description = "Storage replication type"
  type        = string
  default     = "LRS"
}

variable "app_service_sku" {
  description = "App Service Plan SKU"
  type        = string
  default     = "B1"
}

# Add these to your existing variables.tf file

variable "enable_video_archival" {
  description = "Enable automatic archival of old videos"
  type        = bool
  default     = true
}

variable "video_cool_tier_days" {
  description = "Number of days after which videos are moved to cool tier"
  type        = number
  default     = 30
}

variable "video_archive_tier_days" {
  description = "Number of days after which videos are moved to archive tier"
  type        = number
  default     = 90
}

variable "processing_retention_days" {
  description = "Number of days to retain temporary processing files"
  type        = number
  default     = 1
}

variable "delete_retention_days" {
  description = "Number of days to retain deleted blobs"
  type        = number
  default     = 7
}