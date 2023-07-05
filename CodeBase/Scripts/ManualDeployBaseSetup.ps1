<#
.SYNOPSIS
Combines the cleanup, script upload and build image steps into a single script to run manually.

.NOTES
This is not for running in a pipeline!  For pipelines, use separate tasks.
#>

param (
    [String]$workloadName = 'ImageBuilder',
    [String]$workloadNameShort = 'IB',
    [String]$sequenceNumber = '001',
    [String]$subscriptionID = "8eef5bcc-4fc3-43bc-b817-048a708743c3",
    [String]$repoContainerScripts = "buildscripts",
    [String]$location = "uksouth",
    [String]$localenv = "dev",
    [Bool]$dologin = $true
)

$imageBuilderRG = "rg-imagebuilder-$localenv-$location-$sequenceNumber".ToLower()
$umiName = "umi-imagebuilder-$localenv-$location-$sequenceNumber".ToLower()

if ($env::System.JobId) {
    Write-Error "This script should not be run in a pipeline.  It is designed to run manually."
    exit 1
}

#Login to azure
if ($dologin) {
    Write-Host "Log in to Azure using an account with permission to create Resource Groups and Assign Permissions" -ForegroundColor Green
    Connect-AzAccount -Subscription $subscriptionID
}

#Get the subsccription ID
$connectSubid = (Get-AzContext).Subscription.Id

#check that the subscription ID matchs that in the config
if ($connectSubid -ne $subscriptionID) {
    #they dont match so try and change the context
    Write-Host "Changing context to subscription: ($SubID)" -ForegroundColor Yellow
    $context = Set-AzContext -SubscriptionId $subscriptionID

    if ($context.Subscription.Id -ne $subscriptionID) {
        Write-Host "ERROR: Cannot change to subscription: ($subscriptionID)" -ForegroundColor Red
        exit 1
    }

    Write-Host "Changed context to subscription: ($subscriptionID)" -ForegroundColor Green
}

Write-Host "Deploy Imagebuilder Common Components" -ForegroundColor Green
#Create the RG
$rg = Get-AzResourceGroup -Name $imageBuilderRG -Location $location -ErrorAction SilentlyContinue
if (!$rg) {
    Write-Host "Creating resource group: $imageBuilderRG" -ForegroundColor Green
    New-AzResourceGroup -Name $imageBuilderRG -Location $location
}

#Deploy the Bicep/Common.bicep file to this RG with parameters listed
$deployOutput = New-AzResourceGroupDeployment -ResourceGroupName $imageBuilderRG -ErrorVariable deploy -TemplateFile ..\Bicep\Common.bicep -Verbose -TemplateParameterObject @{
    location=$location
    localenv=$localenv
    workloadName=$workloadName
    workloadNameShort=$workloadNameShort
    sequenceNumber=$sequenceNumber
}

if ($deploy) {
    Write-Error "ERROR: Failed to deploy the Resources"
    exit 1
}

Write-Host "Create Imagebuilder UMI" -ForegroundColor Green
&.\CreateUMI.ps1 -subscriptionID $subscriptionID -umiRG $imageBuilderRG -umiLocation $location -umiName $umiName


Write-Host "Assign Imagebuilder UMI" -ForegroundColor Green
&.\AssignUMI.ps1 -subscriptionID $subscriptionID `
    -umiRG $imageBuilderRG `
    -acgRG $imageBuilderRG `
    -repoRG $imageBuilderRG `
    -repoName $deployOutput.Outputs.storageRepoName.Value `
    -acgName $deployOutput.Outputs.galleryName.Value `
    -umiName $umiName


