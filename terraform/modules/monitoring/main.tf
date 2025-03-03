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

variable "app_service_ids" {
  description = "List of App Service IDs to monitor"
  type        = list(string)
  default     = []
}

variable "storage_account_ids" {
  description = "List of Storage Account IDs to monitor"
  type        = list(string)
  default     = []
}

variable "cosmos_db_account_ids" {
  description = "List of Cosmos DB Account IDs to monitor"
  type        = list(string)
  default     = []
}

variable "cognitive_account_ids" {
  description = "List of Cognitive Account IDs to monitor"
  type        = list(string)
  default     = []
}

variable "app_insights_id" {
  description = "Application Insights ID"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Create an Action Group for alerts
resource "azurerm_monitor_action_group" "main" {
  name                = "eduplatform-actiongroup-${var.environment}"
  resource_group_name = var.resource_group_name
  short_name          = "eduaction"

  # Configure email receivers
  email_receiver {
    name                    = "admins"
    email_address           = "admin@example.com" # Replace with your email
    use_common_alert_schema = true
  }

  # Add Azure app push receiver for mobile notifications
  azure_app_push_receiver {
    name          = "mobile-app"
    email_address = "admin@example.com" # Replace with your email
  }

  tags = var.tags
}

# Create alert for App Service health
resource "azurerm_monitor_metric_alert" "app_service_health" {
  count               = length(var.app_service_ids)
  name                = "eduplatform-appservice-health-${var.environment}-${count.index}"
  resource_group_name = var.resource_group_name
  scopes              = [var.app_service_ids[count.index]]
  description         = "Alert when App Service health status changes"
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "HealthCheckStatus"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 100
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = var.tags
}

# Create alert for Storage Account availability
resource "azurerm_monitor_metric_alert" "storage_availability" {
  count               = length(var.storage_account_ids)
  name                = "eduplatform-storage-availability-${var.environment}-${count.index}"
  resource_group_name = var.resource_group_name
  scopes              = [var.storage_account_ids[count.index]]
  description         = "Alert when Storage Account availability drops"
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Storage/storageAccounts"
    metric_name      = "Availability"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 99.9
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = var.tags
}

# Create alert for Cosmos DB availability
resource "azurerm_monitor_metric_alert" "cosmos_db_availability" {
  count               = length(var.cosmos_db_account_ids)
  name                = "eduplatform-cosmosdb-availability-${var.environment}-${count.index}"
  resource_group_name = var.resource_group_name
  scopes              = [var.cosmos_db_account_ids[count.index]]
  description         = "Alert when Cosmos DB availability drops"
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.DocumentDB/databaseAccounts"
    metric_name      = "ServiceAvailability"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 99.9
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = var.tags
}

# Create alert for Cognitive Services quota usage
resource "azurerm_monitor_metric_alert" "cognitive_quota" {
  count               = length(var.cognitive_account_ids)
  name                = "eduplatform-cognitive-quota-${var.environment}-${count.index}"
  resource_group_name = var.resource_group_name
  scopes              = [var.cognitive_account_ids[count.index]]
  description         = "Alert when Cognitive Services quota usage is high"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.CognitiveServices/accounts"
    metric_name      = "QuotaUtilization"
    aggregation      = "Maximum"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = var.tags
}

# Create a log analytics workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "eduplatform-logs-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}

# Link Application Insights to Log Analytics
/*
resource "azurerm_application_insights_analytics_item" "main" {
  name                    = "eduplatform-insights-query-${var.environment}"
  application_insights_id = var.app_insights_id
  content                 = <<QUERY
// Sample query to monitor application performance
requests
| where timestamp > ago(24h)
| summarize count(), avg(duration), percentiles(duration, 50, 95, 99) by name
| order by count_ desc
QUERY

  type                    = "query"
  function_alias          = "appPerformance"
}
*/
# Define diagnostic settings for App Services
resource "azurerm_monitor_diagnostic_setting" "app_service" {
  count                      = length(var.app_service_ids)
  name                       = "eduplatform-appservice-diag-${var.environment}-${count.index}"
  target_resource_id         = var.app_service_ids[count.index]
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "AppServiceHTTPLogs"
  }

  enabled_log {
    category = "AppServiceConsoleLogs"
  }

  enabled_log {
    category = "AppServiceAppLogs"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# Create dashboard for monitoring
resource "azurerm_portal_dashboard" "main" {
  name                 = "eduplatform-dashboard-${var.environment}"
  resource_group_name  = var.resource_group_name
  location             = var.location
  dashboard_properties = <<DASHBOARD
{
  "lenses": {
    "0": {
      "order": 0,
      "parts": {
        "0": {
          "position": {
            "x": 0,
            "y": 0,
            "colSpan": 6,
            "rowSpan": 4
          },
          "metadata": {
            "inputs": [
              {
                "name": "resourceTypeMode",
                "value": "workspace"
              },
              {
                "name": "ComponentId",
                "value": "${var.app_insights_id}"
              }
            ],
            "type": "Extension/AppInsightsExtension/PartType/AvailabilityNavPartType"
          }
        },
        "1": {
          "position": {
            "x": 6,
            "y": 0,
            "colSpan": 6,
            "rowSpan": 4
          },
          "metadata": {
            "inputs": [
              {
                "name": "ComponentId",
                "value": "${var.app_insights_id}"
              }
            ],
            "type": "Extension/AppInsightsExtension/PartType/AppMapGalPt"
          }
        }
      }
    }
  }
}
DASHBOARD

  tags = var.tags
}

# Outputs
output "action_group_id" {
  description = "ID of the monitoring action group"
  value       = azurerm_monitor_action_group.main.id
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "dashboard_id" {
  description = "ID of the monitoring dashboard"
  value       = azurerm_portal_dashboard.main.id
}