// Main Bicep template for Azure Deployment Environment (ADE)
// This template creates a simple "Hello World" web application using Azure Container Apps

@description('The location where resources will be deployed')
param location string = resourceGroup().location

@description('Number of CPU cores for the container app')
@allowed(['0.25', '0.5', '0.75', '1', '1.25', '1.5', '1.75', '2'])
param cpuCore string = '0.5'

@description('Amount of memory in GB for the container app')
@allowed(['0.5', '1', '1.5', '2', '3', '3.5', '4'])
param memorySize string = '1'

@description('Container image to deploy')
param containerImage string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

// Variables for resource naming
var uniqueSuffix = uniqueString(resourceGroup().id)
var containerAppEnvName = 'ade-env-${uniqueSuffix}'
var containerAppName = 'ade-app-${uniqueSuffix}'
var logAnalyticsWorkspaceName = 'ade-law-${uniqueSuffix}'

// Log Analytics Workspace (required for Container Apps)
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Container Apps Environment
resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: containerAppEnvName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }
}

// Container App - Simple Hello World Application
resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: containerAppEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 80
        allowInsecure: false
        traffic: [
          {
            weight: 100
            latestRevision: true
          }
        ]
      }
    }
    template: {
      containers: [
        {
          image: containerImage
          name: 'hello-world-app'
          resources: {
            cpu: json(cpuCore)
            memory: '${memorySize}Gi'
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
      }
    }
  }
}

// Outputs
@description('The URL of the deployed Hello World web application')
output webAppUrl string = 'https://${containerApp.properties.configuration.ingress.fqdn}'

@description('The name of the created container app')
output containerAppName string = containerApp.name

@description('The name of the container app environment')
output containerAppEnvironmentName string = containerAppEnvironment.name

@description('The name of the resource group')
output resourceGroupName string = resourceGroup().name