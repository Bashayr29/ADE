// Main Bicep template for Azure Deployment Environment (ADE)
// This template creates a simple AKS cluster

@description('The location where resources will be deployed')
param location string = resourceGroup().location

@description('The number of nodes in the default node pool')
@allowed(['1', '2', '3', '5', '10'])
param nodeCount string = '1'

@description('The VM size for the node pool')
@allowed([
  'Standard_B2s'
  'Standard_B4ms'
  'Standard_D2s_v3'
  'Standard_D4s_v3'
])
param nodeVmSize string = 'Standard_B2s'

// Variables for resource naming
var uniqueSuffix = uniqueString(resourceGroup().id)
var aksClusterName = 'ade-aks-${uniqueSuffix}'
var logAnalyticsWorkspaceName = 'ade-law-${uniqueSuffix}'

// Log Analytics Workspace (for cluster monitoring)
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

// AKS Cluster
resource aksCluster 'Microsoft.ContainerService/managedClusters@2024-02-01' = {
  name: aksClusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: aksClusterName
    agentPoolProfiles: [
      {
        name: 'nodepool1'
        count: int(nodeCount)
        vmSize: nodeVmSize
        mode: 'System'
        osType: 'Linux'
      }
    ]
    addonProfiles: {
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspace.id
        }
      }
    }
  }
}

// Outputs
@description('The name of the AKS cluster')
output clusterName string = aksCluster.name

@description('The resource group of the AKS cluster')
output resourceGroupName string = resourceGroup().name

@description('Command to get cluster credentials')
output getCredentialsCommand string = 'az aks get-credentials --resource-group ${resourceGroup().name} --name ${aksCluster.name}'
