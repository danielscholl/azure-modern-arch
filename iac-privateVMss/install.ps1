<#
.SYNOPSIS
  Infrastructure as Code Component
.DESCRIPTION
  Install a Private Virtual Machine
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
  [string] $Location = $env:AZURE_LOCATION,
  [string] $Subnet = "container-tier",
  [string] $VMSize = "Standard_DS1_v2",
  [string] $VMName = "node"
)

if (Test-Path ..\scripts\functions.ps1) { . ..\scripts\functions.ps1 }
if (Test-Path .\scripts\functions.ps1) { . .\scripts\functions.ps1 }
if ( !$Subscription) { throw "Subscription Required" }
if ( !$ResourceGroupName) { throw "ResourceGroupName Required" }
if ( !$Location) { throw "Location Required" }

###############################
## Azure Intialize           ##
###############################
$BASE_DIR = Get-ScriptDirectory
$DEPLOYMENT = Split-Path $BASE_DIR -Leaf
LoginAzure
CreateResourceGroup $ResourceGroupName $Location

Write-Color -Text "Registering Provider..." -Color Yellow
Register-AzureRmResourceProvider -ProviderNamespace Microsoft.Compute

##############################
## Deploy Template          ##
##############################
Write-Color -Text "Gathering information for Key Vault..." -Color Green
$VaultName = GetKeyVault $env:AZURE_GROUP 

Write-Color -Text "Retrieving Diagnostic Storage Account Parameters..." -Color Green
$StorageAccountName = GetStorageAccount $ResourceGroupName
Write-Color -Text "$StorageAccountName" -Color White

Write-Color -Text "Retrieving Credential Parameters..." -Color Green
Write-Color -Text "Retrieving Credential Parameters..." -Color Green
$AdminUserName = (Get-AzureKeyVaultSecret -VaultName $VaultName -Name 'adminUserName').SecretValueText
$AdminPassword = (Get-AzureKeyVaultSecret -VaultName $VaultName -Name 'adminPassword').SecretValue
Write-Color -Text "$AdminUserName\*************" -Color White

Write-Color -Text "Retrieving Virtual Network Parameters..." -Color Green
$VirtualNetworkName = "${env:AZURE_GROUP}-vnet"
Write-Color -Text "$ResourceGroupName  $VirtualNetworkName $Subnet" -Color White


Write-Color -Text "`r`n---------------------------------------------------- "-Color Yellow
Write-Color -Text "Deploying ", "$DEPLOYMENT ", "template..." -Color Green, Red, Green
Write-Color -Text "---------------------------------------------------- "-Color Yellow

Write-Color -Text "Private Virtual Machines Servers..." -Color Green

$Servers = @($VMName)

ForEach ($vmName in $Servers) {
  New-AzureRmResourceGroupDeployment -Name "$DEPLOYMENT-$VMName" `
    -TemplateFile $BASE_DIR\azuredeploy.json `
    -TemplateParameterFile $BASE_DIR\azuredeploy.parameters.json `
    -prefix $env:AZURE_GROUP  `
    -vmName $VMName -vmSize $VMSize `
    -diagnosticsStorageName $StorageAccountName `
    -adminUserName $AdminUserName -adminPassword $AdminPassword `
    -vnetGroup $env:AZURE_GROUP -vnet $VirtualNetworkName -subnet $Subnet `
    -ResourceGroupName $ResourceGroupName
}
