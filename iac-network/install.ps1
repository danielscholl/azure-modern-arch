<#
.SYNOPSIS
  Infrastructure as Code Component
.DESCRIPTION
  Install a Network
.EXAMPLE
  .\install.ps1
  Version History
  v1.0   - Initial Release
#>
#Requires -Version 5.1
#Requires -Module @{ModuleName='AzureRM.Resources'; ModuleVersion='5.0'}

Param(
  [string]$Subscription = $env:AZURE_SUBSCRIPTION,
  [string]$ResourceGroupName = $env:AZURE_GROUP,
  [string]$Location = $env:AZURE_LOCATION,
  [string]$NetworkSegment = "10.1"
)

if (Test-Path ..\scripts\functions.ps1) { . ..\scripts\functions.ps1 }
if (Test-Path .\scripts\functions.ps1) { . .\scripts\functions.ps1 }
if ( !$Subscription) { throw "Subscription Required" }
if ( !$ResourceGroupName) { throw "ResourceGroupName Required" }
if ( !$Location) { throw "Location Required" }
if ( !$NetworkSegment) { throw "Network Segment Required" }

###############################
## Azure Intialize           ##
###############################
$BASE_DIR = Get-ScriptDirectory
$DEPLOYMENT = Split-Path $BASE_DIR -Leaf
LoginAzure
CreateResourceGroup $ResourceGroupName $Location

Write-Color -Text "Registering Provider..." -Color Yellow
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.Network


##############################
## Deploy Template          ##
##############################
Write-Color -Text "`r`n---------------------------------------------------- "-Color Yellow
Write-Color -Text "Deploying ", "$DEPLOYMENT ", "template..." -Color Green, Red, Green
Write-Color -Text "---------------------------------------------------- "-Color Yellow

New-AzureRmResourceGroupDeployment -Name $DEPLOYMENT `
  -TemplateFile $BASE_DIR\azuredeploy.json `
  -TemplateParameterFile $BASE_DIR\azuredeploy.parameters.json `
  -prefix $ResourceGroupName `
  -vnetPrefix    "$NetworkSegment.0.0/16" `
  -subnet1Prefix "$NetworkSegment.0.0/28" `
  -subnet2Prefix "$NetworkSegment.0.16/28" `
  -subnet3Prefix "$NetworkSegment.1.0/24" `
  -subnet4Prefix "$NetworkSegment.2.0/24" `
  -ResourceGroupName $ResourceGroupName
