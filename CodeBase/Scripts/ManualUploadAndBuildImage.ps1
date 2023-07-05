<#
.SYNOPSIS
Combines the cleanup, script upload and build image steps into a single script to run manually.

.NOTES
This is not for running in a pipeline!  For pipelines, use separate tasks.
#>

param (
    [Parameter(Mandatory)]
    [String]$imageName,
    [String]$imageBuilderRG = "rg-imagebuilder-dev-uksouth-001",
    [String]$subscriptionID = "8eef5bcc-4fc3-43bc-b817-048a708743c3",
    [String]$repoName = "stibdevuksouth001",
    [String]$repoRG = "rg-imagebuilder-dev-uksouth-001",
    [String]$repoContainerScripts = "buildscripts",
    [Int]$ibTimeout = 120,
    [String]$ibVMSize = "Standard_D2s_v3",
    [Bool]$dologin = $true,
    [Bool]$runBuild = $true
)

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

Write-Host "Cleaning up templates" -ForegroundColor Green
&.\CleanUpTemplates.ps1 -subscriptionID $subscriptionID -imageBuilderRG $imageBuilderRG -imageName $imageName

Write-Host "Uploading build scripts" -ForegroundColor Green
&.\UploadBuildScripts.ps1 -subscriptionID $subscriptionID -repoRG $repoRG -repoName $repoName -repoContainerScripts $repoContainerScripts -imageName $imageName -runAsPipeline $false

if ($runBuild) {
    Write-Host "Build Image" -ForegroundColor Green
    &.\BuildImage.ps1 -subscriptionID $subscriptionID -imageRG $imageBuilderRG -imageName $imageName -ibTimeout $ibTimeout -ibVMSize $ibVMSize -doBuildImage $runBuild -runAsPipeline $false
}
