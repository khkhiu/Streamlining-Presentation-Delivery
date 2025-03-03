# Azure Education Platform with Talking Avatar

This Terraform configuration creates an Azure-based education platform with a talking avatar, slide shows, and Q&A functionality.

## Architecture

This platform is built using the following Azure services:

- **Azure App Service**: For hosting the backend API
- **Azure Static Web Apps**: For hosting the frontend application
- **Azure Storage Account**: For storing lesson content, transcripts, and media
- **Azure Cognitive Services**:
  - **Speech Service**: For text-to-speech capabilities
  - **OpenAI Service**: For Q&A functionality
  - **Face API**: For avatar expressions
  - **Custom Vision**: For avatar rendering
- **Azure Cosmos DB**: For structured data storage (lesson metadata, user progress)
- **Azure Key Vault**: For secure credential management
- **Azure Application Insights**: For monitoring and logging
- **Azure Front Door**: For global content delivery and security

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) (>=1.0.0)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) (>=2.30.0)
- An Azure subscription

## Getting Started

1. **Login to Azure**

```bash
az login
```

2. **Initialize Terraform**

```bash
terraform init
```

3. **Plan the deployment**

```bash
terraform plan -out=tfplan
```

4. **Apply the configuration**

```bash
terraform apply tfplan
```

## Configuration Variables

Key variables that can be customized include:

| Variable | Description | Default |
|----------|-------------|---------|
| `resource_group_name` | Name of the resource group | `education-platform-rg` |
| `location` | Azure region to deploy resources | `East US` |
| `environment` | Environment (dev, test, prod) | `dev` |
| `openai_model_name` | Name of the OpenAI model to deploy | `gpt-4` |
| `openai_model_version` | Version of the OpenAI model to deploy | `0314` |
| `backend_service_plan_sku` | SKU for backend service plan | `P1v2` |

See `variables.tf` for all available configuration options.

## Module Structure

- **Main Configuration**: `main.tf`, `variables.tf`, `outputs.tf`
- **Modules**:
  - `modules/monitoring`: Azure Monitor setup for observability
  - `modules/security`: Security configuration including WAF, Private Endpoints
  - `modules/networking`: Network setup with VNet, subnets, and Front Door

## Next Steps After Deployment

1. **Configure the backend**:
   - Deploy your Node.js application to the App Service
   - Configure environment variables using the outputs from Terraform

2. **Set up the frontend**:
   - Deploy your React application to the Static Web App
   - Configure the frontend to use the backend API

3. **Prepare lesson content**:
   - Upload lessons, transcripts, and media to the storage account
   - Set up metadata in Cosmos DB

4. **Configure the avatar**:
   - Set up avatar configurations in the Face API and Custom Vision
   - Configure the Speech Service for text-to-speech

## Security Considerations

- All sensitive credentials are stored in Azure Key Vault
- Service-to-service communication is secured via VNet integration and private endpoints
- Web Application Firewall (WAF) is configured to protect against common web vulnerabilities
- DDoS Protection is enabled for the Virtual Network
- HTTPS is enforced for all web applications
- Storage accounts are configured to require secure transfer

## Monitoring and Maintenance

- Application Insights is set up to monitor the application
- Diagnostic settings are configured to collect logs and metrics
- Alerts are configured for critical service health issues
- A monitoring dashboard is created for visualizing platform health

## Cost Optimization

To reduce costs for non-production environments:

1. Modify SKUs in `variables.tf` (e.g., change to B1 for App Service Plan in dev)
2. Adjust retention periods for logs and diagnostics
3. Consider scaling down or pausing services when not in use

## Troubleshooting

1. **Check deployment logs**:
   ```bash
   terraform state show <resource_name>
   ```

2. **View resource logs in Azure Portal**:
   - Navigate to the Azure Portal
   - Go to the resource in question
   - Check "Activity logs" or "Logs" section

3. **Common issues**:
   - Resource name conflicts: Ensure resource names are unique
   - Service availability: Verify selected services are available in your region
   - Permissions: Ensure your account has sufficient permissions

## Contributing

1. Clone the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.