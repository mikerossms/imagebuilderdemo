// Deploys the common infrastrcture required to support the Image Builder.  

targetScope = 'resourceGroup'

//Naming convention:
//resource-workload-environment-region-instance
//pip-sharepoint-prod-uksouth-001

//Parameters
@description('The local environment identifier.  Default: dev')
param localenv string = 'dev'

@description('Location of the Resources. Default: UK South')
param location string = 'uksouth'

@maxLength(4)
@description('Workload short code (max 4 chars)')
param workloadNameShort string = 'IB'

@description('Full name of the workload (without spaces)')
param workloadName string = 'ImageBuilder'

@description('Product sequence number - used to generate the product and resource group name as a unique identifier')
param sequenceNumber string = '001'

@description('Tags to be applied to all resources')
param tags object = {
  Environment: localenv
  WorkloadName: workloadName
  BusinessCriticality: 'medium'
  CostCentre: 'csu'
  Owner: 'AVD Squad'
  DataClassification: 'general'
}

@description('The name of the storage account to create as a software repo for the Image Builder and a place to host its common components')
param storageRepoName string = toLower('st${workloadNameShort}${localenv}${location}${sequenceNumber}')  //Storage names are alphanumeric only

@description('The name of the container to hold the scripts used to build the Image Builder')
param containerIBScripts string = 'buildscripts'

@description('The name of the container to hold the software to be installed by the Image Builder')
param containerIBSoftware string = 'software'

@description('The Name of the compute gallery')
param computeGalName string = toLower('acg_${workloadName}_${localenv}_${location}_${sequenceNumber}')   //Compute gallery names limited to alphanumeric, underscores and periods

//Create the storage account required for the script which will build the ADDS server
module RepoStorage '../ResourceModules/0.9.0/modules/Microsoft.Storage/storageAccounts/deploy.bicep' = {
  name: 'RepoStorage'
  params: {
    location: location
    tags: tags
    name: storageRepoName
    allowBlobPublicAccess: true   //Permits access from the deploying script
    publicNetworkAccess: 'Enabled'
    // diagnosticLogsRetentionInDays: 7
    // diagnosticWorkspaceId: LAWorkspace.id
    storageAccountSku: 'Standard_LRS'
    blobServices: {
      containers: [
        {
          name: containerIBScripts
          publicAccess: 'None'
        }
        {
          name: containerIBSoftware
          publicAccess: 'None'
        }
      ]
      //diagnosticWorkspaceId: LAWorkspace.id
    }
  }
}

//Build the Compute Gallery
module galleries '../ResourceModules/0.9.0/modules/Microsoft.Compute/galleries/deploy.bicep' = {
  name: computeGalName
  params: {
    location: location
    tags: tags
    name: computeGalName
  }
}

output storageRepoID string = RepoStorage.outputs.resourceId
output storageRepoName string = RepoStorage.outputs.name
output storageRepoRG string = RepoStorage.outputs.resourceGroupName
output storageRepoScriptsContainer string = containerIBScripts
output storageRepoSoftwareContainer string = containerIBSoftware
output galleryName string = galleries.outputs.name
