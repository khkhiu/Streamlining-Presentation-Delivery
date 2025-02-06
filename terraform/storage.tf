# Create Storage Account
resource "azurerm_storage_account" "storage" {
  name                     = lower(replace("${var.project_name}${var.environment}st", "-", ""))
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_replication_type
  
  # Enable hierarchical namespace for better video file organization
  is_hns_enabled          = true
  
  # Enable static website hosting for potential video streaming
  static_website {
    index_document = "index.html"
  }

  blob_properties {
    cors_rule {
      allowed_headers    = ["*"]
      allowed_methods    = ["GET", "POST", "PUT"]
      allowed_origins    = ["*"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 3600
    }

    # Configure versioning for video files
    versioning_enabled = true

    # Configure delete retention policy
    delete_retention_policy {
      days = 7
    }

    # Configure container deletion prevention
    container_delete_retention_policy {
      days = 7
    }
  }

  # Network rules for security
  network_rules {
    default_action = "Allow"  # In production, consider changing to "Deny"
    bypass         = ["AzureServices"]
  }
}

# Create Storage Container for Videos
resource "azurerm_storage_container" "videos" {
  name                  = "trainer-videos"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "blob"
}

# Create Storage Container for Video Thumbnails
resource "azurerm_storage_container" "thumbnails" {
  name                  = "video-thumbnails"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "blob"
}

# Create Storage Container for Temporary Processing
resource "azurerm_storage_container" "processing" {
  name                  = "processing-temp"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

# Create Lifecycle Management Policy
resource "azurerm_storage_management_policy" "lifecycle" {
  storage_account_id = azurerm_storage_account.storage.id

  rule {
    name    = "processingCleanup"
    enabled = true
    filters {
      prefix_match = ["processing-temp/"]
      blob_types   = ["blockBlob"]
    }
    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 1
      }
    }
  }

  rule {
    name    = "archiveOldVideos"
    enabled = true
    filters {
      prefix_match = ["trainer-videos/"]
      blob_types   = ["blockBlob"]
    }
    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than    = 30
        tier_to_archive_after_days_since_modification_greater_than = 90
      }
    }
  }
}