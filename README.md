# Azure Deployment Environment (ADE) Template

A simple and reusable Azure deployment template using Bicep Infrastructure as Code (IaC) for creating web application environments.

## 🏗️ Architecture

This template creates the following Azure resources:

- **Resource Group**: Container for all resources
- **App Service Plan**: Hosting plan for web applications
- **Web App**: Azure App Service for hosting web applications
- **Application Insights**: Application performance monitoring (optional)
- **Log Analytics Workspace**: Required for Application Insights

## 📁 Project Structure

```
ADE/
├── infra/                          # Infrastructure as Code files
│   ├── main.bicep                  # Main Bicep template
│   ├── parameters.dev.yaml         # Development environment parameters
│   ├── parameters.test.yaml        # Test environment parameters
│   └── parameters.prod.yaml        # Production environment parameters
├── scripts/                        # Deployment scripts
│   ├── deploy.ps1                  # PowerShell deployment script
│   ├── deploy.sh                   # Bash deployment script
│   └── cleanup.ps1                 # Resource cleanup script
└── README.md                       # This file
```

## 🚀 Quick Start

### Prerequisites

1. **Azure CLI**: [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
2. **Azure Subscription**: Active Azure subscription with appropriate permissions
3. **PowerShell** (for Windows) or **Bash** (for Linux/macOS)

### Authentication

```bash
# Login to Azure
az login

# Set your subscription (optional)
az account set --subscription "your-subscription-id"
```

### Deployment Options

#### Option 1: PowerShell Script (Windows)

```powershell
# Deploy to development environment
.\scripts\deploy.ps1 -Environment "dev" -ResourceGroupName "rg-ade-dev"

# Deploy to test environment
.\scripts\deploy.ps1 -Environment "test" -ResourceGroupName "rg-ade-test"

# Deploy to production environment
.\scripts\deploy.ps1 -Environment "prod" -ResourceGroupName "rg-ade-prod"

# Preview changes before deployment (what-if)
.\scripts\deploy.ps1 -Environment "dev" -ResourceGroupName "rg-ade-dev" -WhatIf
```

#### Option 2: Bash Script (Linux/macOS)

```bash
# Make the script executable
chmod +x scripts/deploy.sh

# Deploy to development environment
./scripts/deploy.sh dev rg-ade-dev

# Deploy to test environment
./scripts/deploy.sh test rg-ade-test

# Deploy to production environment
./scripts/deploy.sh prod rg-ade-prod

# Preview changes before deployment (what-if)
./scripts/deploy.sh dev rg-ade-dev --what-if
```

#### Option 3: Azure CLI Direct

```bash
# Create resource group
az group create --name "rg-ade-dev" --location "Sweden Central"

# Deploy template
az deployment group create \
  --resource-group "rg-ade-dev" \
  --template-file "infra/main.bicep" \
  --parameters "@infra/parameters.dev.yaml"
```

**Note**: If using Azure CLI directly with YAML files, you'll need to convert them to JSON first or use the provided deployment scripts that handle the conversion automatically.
```

## ⚙️ Configuration

### Environment Parameters

The template supports three environments with different configurations:

| Environment | App Service Plan SKU | Use Case |
|-------------|---------------------|----------|
| **dev** | F1 (Free) | Development and testing |
| **test** | B1 (Basic) | Integration testing |
| **prod** | P1v2 (Premium) | Production workloads |

### Customizable Parameters

Edit the parameters files (`infra/parameters.{env}.yaml`) to customize:

- **location**: Azure region for deployment (default: Sweden Central)
- **resourcePrefix**: Prefix for resource names
- **appServicePlanSku**: App Service Plan pricing tier
- **enableApplicationInsights**: Enable/disable monitoring
- **tags**: Resource tags for organization

### Example Parameter Customization

```yaml
# parameters.dev.yaml
parameters:
  location:
    value: "West Europe"
  
  resourcePrefix:
    value: "myapp"
  
  appServicePlanSku:
    value: "S1"
  
  tags:
    value:
      Environment: "dev"
      Project: "MyApp"
      Owner: "TeamName"
      CostCenter: "Engineering"
```

## 🔧 Advanced Usage

### Validate Before Deployment

```bash
# Validate the template
az deployment group validate \
  --resource-group "rg-ade-dev" \
  --template-file "infra/main.bicep" \
  --parameters "@infra/parameters.dev.json"

# Preview changes (what-if)
az deployment group what-if \
  --resource-group "rg-ade-dev" \
  --template-file "infra/main.bicep" \
  --parameters "@infra/parameters.dev.json"
```

### Custom Deployment Name

```bash
az deployment group create \
  --resource-group "rg-ade-dev" \
  --template-file "infra/main.bicep" \
  --parameters "@infra/parameters.dev.json" \
  --name "custom-deployment-name"
```

### Override Parameters

```bash
az deployment group create \
  --resource-group "rg-ade-dev" \
  --template-file "infra/main.bicep" \
  --parameters "@infra/parameters.dev.json" \
  --parameters appServicePlanSku=B2 enableApplicationInsights=false
```

## 🧹 Cleanup

To remove all deployed resources:

```powershell
# PowerShell
.\scripts\cleanup.ps1 -ResourceGroupName "rg-ade-dev"

# Force deletion without confirmation
.\scripts\cleanup.ps1 -ResourceGroupName "rg-ade-dev" -Force
```

```bash
# Azure CLI
az group delete --name "rg-ade-dev" --yes
```

## 📝 YAML Configuration

This template uses YAML parameter files for better readability and maintainability. The deployment scripts automatically convert YAML to JSON format as required by Azure CLI.

### Prerequisites for YAML Support

**PowerShell**: The script will automatically install the `powershell-yaml` module if not present.

**Bash/Linux**: Requires `yq` for YAML processing. The script will attempt to install it automatically or you can install manually:

```bash
# Ubuntu/Debian
sudo apt-get install yq

# macOS
brew install yq

# Or download from: https://github.com/mikefarah/yq#install
```

## 📊 Monitoring

When Application Insights is enabled, you can monitor your application:

1. Navigate to the Azure Portal
2. Go to your resource group
3. Open the Application Insights resource
4. View performance metrics, logs, and alerts

## 🔒 Security Features

- **HTTPS Only**: All web apps enforce HTTPS
- **TLS 1.2**: Minimum TLS version enforced
- **System-Assigned Managed Identity**: Secure authentication for Azure resources
- **FTPS Disabled**: FTP access is disabled for security

## 🏷️ Resource Naming Convention

Resources follow this naming pattern:
```
{resourcePrefix}-{resourceType}-{environment}-{uniqueSuffix}
```

Example:
- App Service Plan: `ade-asp-dev-abc123`
- Web App: `ade-webapp-dev-abc123`
- Application Insights: `ade-ai-dev-abc123`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the deployment
5. Submit a pull request

## 📝 License

This project is licensed under the MIT License.

## 🆘 Troubleshooting

### Common Issues

1. **Resource name conflicts**: The template uses `uniqueString()` to avoid conflicts
2. **Insufficient permissions**: Ensure you have Contributor access to the subscription
3. **Quota limits**: Check Azure quota limits for your subscription
4. **Region availability**: Verify the chosen region supports all required services

### Getting Help

- [Azure Bicep Documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [Azure CLI Reference](https://docs.microsoft.com/en-us/cli/azure/)
- [Azure App Service Documentation](https://docs.microsoft.com/en-us/azure/app-service/)

## 📈 Next Steps

After deployment, consider:

1. **Custom Domain**: Configure a custom domain for your web app
2. **SSL Certificate**: Add SSL certificates for secure connections
3. **CI/CD Pipeline**: Set up automated deployments with GitHub Actions or Azure DevOps
4. **Scaling**: Configure auto-scaling based on demand
5. **Backup**: Set up backup and disaster recovery
6. **Monitoring**: Configure alerts and monitoring dashboards