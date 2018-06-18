<#
.SYNOPSIS
  Infrastructure as Code Component
.DESCRIPTION
  Install a Public Virtual Machine
.EXAMPLE
  .\install.ps1
  Version History
  v1.0   - Initial Release
#>
#Requires -Version 5.1
#Requires -Module @{ModuleName='AzureRM.Resources'; ModuleVersion='5.0'}

Param(
  [string] $Subscription = $env:AZURE_SUBSCRIPTION,
  [string] $ResourceGroupName = $env:AZURE_GROUP,
  [string] $StorageGroupName = $env:AZURE_GROUP,

  [Parameter(Mandatory = $true)]
  [string] $VmName
)

if (Test-Path ..\scripts\functions.ps1) { . ..\scripts\functions.ps1 }
if (Test-Path .\scripts\functions.ps1) { . .\scripts\functions.ps1 }
if ( !$Subscription) { throw "Subscription Required" }
if ( !$ResourceGroupName) { throw "ResourceGroupName Required" }

###############################
## Azure Intialize           ##
###############################
$BASE_DIR = Get-ScriptDirectory
$DEPLOYMENT = Split-Path $BASE_DIR -Leaf
LoginAzure

###############################
## Azure Intialize           ##
###############################
$BASE_DIR = Get-ScriptDirectory
$DEPLOYMENT = Split-Path $BASE_DIR -Leaf
LoginAzure


##############################
## Deploy Template          ##
##############################
Write-Color -Text "Retrieving Diagnostic Storage Account Parameters..." -Color Green
$StorageAccountName = GetStorageAccount $StorageGroupName
$StorageAccountKey = GetStorageAccountKey $StorageGroupName $StorageAccountName
$SecureStorageKey = $StorageAccountKey | ConvertTo-SecureString -AsPlainText -Force
Write-Color -Text "$StorageAccountName  $StorageAccountKey" -Color White

Write-Color -Text "`r`n---------------------------------------------------- "-Color Yellow
Write-Color -Text "Deploying ", "$DEPLOYMENT ", "template..." -Color Green, Red, Green
Write-Color -Text "---------------------------------------------------- "-Color Yellow
New-AzureRmResourceGroupDeployment -Name $DEPLOYMENT `
  -TemplateFile $BASE_DIR\azuredeploy.json `
  -TemplateParameterFile $BASE_DIR\azuredeploy.parameters.json `
  -vmName $VmName `
  -diagnosticsStorageName $StorageAccountName -diagnosticsStorageKey $SecureStorageKey `
  -ResourceGroupName $ResourceGroupName
