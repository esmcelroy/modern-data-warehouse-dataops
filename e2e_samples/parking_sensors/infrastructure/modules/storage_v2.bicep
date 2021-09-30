param project string
@allowed([
  'dev'
  'stg'
  'prod'
])
param env string
param location string = resourceGroup().location
param deployment_id string
param contributor_principal_id string

//https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
var storage_blob_data_contributor = '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/ba92f5b4-2d11-453d-a403-e96b0029c9fe'

// Data Lake Storage
resource storage 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: '${project}st${env}${deployment_id}'
  location: location
  tags: {
    DisplayName: 'Data Lake Storage'
    Environment: env
  }
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    isHnsEnabled: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          enabled: true
        }
        blob: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

resource storage_roleassignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(storage.id)
  scope: storage
  properties: {
    roleDefinitionId: storage_blob_data_contributor
    principalId: contributor_principal_id
    principalType: 'ServicePrincipal'
  }
}

// Synapse Storage
resource synapseStorage 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: '${project}st2${env}${deployment_id}'
  location: location
  tags: {
    DisplayName: 'Synapse Storage'
    Environment: env
  }
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    isHnsEnabled: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        file: {
          enabled: true
        }
        blob: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

resource synapseStorageFileSystem 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-04-01' = {
  name: '${project}st2${env}${deployment_id}/default/container001'
  properties: {
    publicAccess: 'None'
  }
  dependsOn: [
    synapseStorage
  ]
}

resource synapseStorage_roleassignment 'Microsoft.Authorization/roleAssignments@2020-08-01-preview' = {
  name: guid(synapseStorage.id)
  scope: synapseStorage
  properties: {
    roleDefinitionId: storage_blob_data_contributor
    principalId: contributor_principal_id
    principalType: 'ServicePrincipal'
  }
}

output storage_account_name string = storage.name
output storage_account_name_synapse string = synapseStorage.name
