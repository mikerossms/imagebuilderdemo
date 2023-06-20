# Scripts

The scripts folder provides a number of automation scripts required by the manual build process and pipelines to deploy the appropriate resources, configure them and keep them tidy.

## AssignUMI.ps1
### Description
Assigns the UMI of the ImageBuilder to the appropriate resources in the ImageBuilder resource group to permit it access while building an image

### Parameters

| Type   | Variable name          | Description                                                | Default value                            |
|--------|------------------------|------------------------------------------------------------|------------------------------------------|
| String | $umiName               | The name of the User Managed Identity (UMI)                | "umi-imagebuilder-prod-uksouth-001"      |
| String | $umiRG                 | The resource group that the UMI resides in                 | "rg-imagebuilder-prod-uksouth-001"       |
| String | $acgName               | The name of the Azure Compute Gallery                      | "acg_imagebuilder_prod_uksouth_001"      |
| String | $acgRG                 | The Resource Group that the ACG resides in                 | "rg-imagebuilder-prod-uksouth-001"       |
| String | $repoName              | The name of the repository storage account                 | "stibproduksouth001"                     |
| String | $repoRG                | The resource group that the repository resides in          | "rg-imagebuilder-prod-uksouth-001"       |
| String | $repoContainerScripts  | The storage account container that holds the build scripts | "buildscripts"                           |
| String | $repoContainerSoftware | The storage account container that holds required software | "software"                               |
| String | $subscriptionID        | The subscription ID where everything is deployed           | "f258c6c4-0a76-40eb-b002-b20a8fde7d70"   |


## BuildImage.ps1
### Description
This PowerShell script deploys an image template using BICEP and then builds an image based on the template. It provides a set of parameters that can be customized for the deployment and building process.  The script also checks if the Azure Image Builder module is installed and installs it if necessary. It verifies the subscription and resource group existence, deploys the image template, and then initiates the image building process. The progress of the image build is periodically polled until it reaches a completion state (succeeded, partially succeeded, or failed).

### Parameters
| Type    | Variable name    | Description                                                                                   | Default value                       |
|---------|------------------|-----------------------------------------------------------------------------------------------|-------------------------------------|
| String  | imageName        | (Required) The name of the Image and Folder in which the image build scripts are deployed.   | N/A                                 |
| String  | imageRG          | The name of the resource group where the image will be deployed.                              | "rg-imagebuilder-prod-uksouth-001"  |
| String  | subscriptionID   | The ID of the Azure subscription to use for the deployment.                                    | "f258c6c4-0a76-40eb-b002-b20a8fde7d70" |
| String  | storageRepoName  | The name of the storage repository.                                                           | "stibproduksouth001"                |
| String  | storageRepoRG    | The name of the resource group where the storage repository is located.                       | "rg-imagebuilder-prod-uksouth-001"  |
| String  | localenv         | The environment name (e.g., "prod").                                                          | "prod"                              |
| String  | location         | The location/region for the deployment.                                                       | "uksouth"                           |
| String  | workloadName     | The name of the image builder workload.                                                       | "imagebuilder"                      |
| String  | workloadNameShort| The short name of the image builder workload.                                                 | "ib"                                |
| String  | publisher        | The publisher of the image.                                                                   | "AVDSquad"                          |
| String  | sequenceNum      | The sequence number of the image.                                                             | "001"                               |
| Int     | ibTimeout        | The timeout duration for the image builder process in minutes.                                | 120                                 |
| String  | ibVMSize         | The size of the virtual machine used during the image building process.                       | "Standard_D2s_v3"                   |
| Int     | pollingTime      | The interval in seconds between image build progress polling.                                 | 60                                  |
| Bool    | doBuildImage     | Specifies whether to build the image after template deployment.                               | $true                               |


## CheckResourceProviders.ps1
### Description
This PowerShell script checks if a set of required Azure resource providers are registered in the subscription and attempts to register them if they are not.

### Parameters
| Type   | Variable name  | Description                                                                 | Default value |
|--------|----------------|-----------------------------------------------------------------------------|---------------|
| String | subscriptionID | (Mandatory) The ID of the Azure subscription where the registration is checked. | N/A           |


## CleanUpTemplates.ps1
TBD

## CreateUMI.ps1
### Description
This PowerShell script checks for the existence of a User Assigned Managed Identity (UMI) and creates it if it does not already exist. The script is typically used as part of the Image Builder setup process.

### Parameters
| Type   | Variable name  | Description                                                                         | Default value                       |
|--------|----------------|-------------------------------------------------------------------------------------|-------------------------------------|
| String | umiName        | The name of the User Assigned Managed Identity (UMI) to check and create if missing. | "umi-imagebuilder-prod-uksouth-001" |
| String | umiRG          | The name of the resource group where the UMI will exist or be created.               | "rg-imagebuilder-prod-uksouth-001"  |
| String | umiLocation    | The location of the UMI.                                                            | "uksouth"                           |
| String | subscriptionID | The ID of the Azure subscription to use for the UMI creation.                        | "f258c6c4-0a76-40eb-b002-b20a8fde7d70" |

## GetLatestPowershell.ps1
### Description

This script dpownloads the latest version of Powershell from Github

## ManualUploadAndBuildImage.ps1
### Description
This PowerShell script combines the cleanup, script upload, and build image steps into a single script that can be run manually. It is not intended for use in a pipeline.

### Parameters
| Type   | Variable name          | Description                                                                                      | Default value                           |
|--------|------------------------|--------------------------------------------------------------------------------------------------|-----------------------------------------|
| String | imageName              | The name of the image.                                                                           | Mandatory                               |
| String | imageBuilderRG          | The name of the resource group where the image builder is located.                                | "rg-imagebuilder-prod-uksouth-001"      |
| String | subscriptionID          | The ID of the Azure subscription to use.                                                         | "f258c6c4-0a76-40eb-b002-b20a8fde7d70"  |
| String | repoName               | The name of the repository.                                                                       | "stibproduksouth001"                    |
| String | repoRG                 | The name of the resource group where the repository is located.                                   | "rg-imagebuilder-prod-uksouth-001"      |
| String | repoContainerScripts    | The name of the container for build scripts within the repository.                                | "buildscripts"                          |
| Int    | ibTimeout              | The timeout value (in minutes) for the image building process.                                    | 120                                     |
| String | ibVMSize               | The size of the virtual machine to use for the image building process.                            | "Standard_D2s_v3"                       |
| Bool   | dologin                | Indicates whether to log in to Azure using an account with necessary permissions.                 | $true                                   |
| Bool   | runBuild               | Indicates whether to perform the image building process.                                          | $true                                   |


## UploadBuildScripts.ps1
### Description
This PowerShell script pulls together a set of build scripts into a single zip file and uploads it to a specified container in a storage repository.

### Parameters
| Type   | Variable name             | Description                                                                                           | Default value                            |
|--------|---------------------------|-------------------------------------------------------------------------------------------------------|------------------------------------------|
| String | imageName                 | The name of the image being deployed.                                                                 | Mandatory                                |
| String | repoName                  | The name of the storage repository.                                                                   | "stibproduksouth001"                     |
| String | repoRG                    | The name of the resource group where the storage repository is located.                                | "rg-imagebuilder-prod-uksouth-001"       |
| String | repoContainerScripts      | The name of the container in the storage repository to upload the build scripts to.                    | "buildscripts"                           |
| String | subscriptionID            | The ID of the Azure subscription to use.                                                              | "f258c6c4-0a76-40eb-b002-b20a8fde7d70"   |
| Bool   | runAsPipeline             | Indicates whether the script is being run in a pipeline.                                              | $true                                    |

## ManualDeployBaseSetup.ps1
### Description
This PowerShell script runs the base component setup deploying the resource group, compute gallery, storage account and managed identity.  the script itself is not for use as part of a pipeline.

### Parameters
**to be added**