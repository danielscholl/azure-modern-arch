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
  [string] $Location = $env:AZURE_LOCATION,
  [string] $Subnet = "mgmt-tier",
  [string] $ImageGroup = $env:AZURE_DEVOPS,
  [string] $ImageName = $env:AZURE_SERVER_IMAGE,
  [string] $ImagePublisher = "MicrosoftWindowsServer",
  [string] $ImageOffer = "WindowsServer",
  [string] $ImageSku = "2016-Datacenter",
  [string] $VmName = "jump"
)

if (Test-Path ..\scripts\functions.ps1) { . ..\scripts\functions.ps1 }
if (Test-Path .\scripts\functions.ps1) { . .\scripts\functions.ps1 }
if (!$Subscription) { throw "Subscription Required" }
if (!$ResourceGroupName) { throw "ResourceGroupName Required" }
if (!$Location) { throw "Location Required" }

if (( $ImageGroup ) -and ( $ImageName ) -and ( $Image -eq $true )) {
  $UseImage = "Yes"
}
else {
  $UseImage = "No"
}

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
$AdminUserName = (Get-AzureKeyVaultSecret -VaultName $VaultName -Name 'adminUserName').SecretValueText
$AdminPassword = (Get-AzureKeyVaultSecret -VaultName $VaultName -Name 'adminPassword').SecretValue

if (!$AdminUserName) {
  Write-Color -Text "`r`n---------------------------------------------------- "-Color Blue
  Write-Color -Text "Collecting Server Admin Credentials... " -Color Red
  Write-Color -Text "---------------------------------------------------- "-Color Blue
  $credential = Get-Credential -Message "Enter Server Admin Credentials"
  Set-AzureKeyVaultSecret -VaultName $VaultName -Name "adminUserName" -SecretValue (ConvertTo-SecureString $credential.UserName -AsPlainText -Force)
  Set-AzureKeyVaultSecret -VaultName $VaultName -Name "adminPassword" -SecretValue $credential.Password

  $AdminUserName = (Get-AzureKeyVaultSecret -VaultName $VaultName -Name 'adminUserName').SecretValueText
  $AdminPassword = (Get-AzureKeyVaultSecret -VaultName $VaultName -Name 'adminPassword').SecretValue
}
Write-Color -Text "$AdminUserName\*************" -Color White

Write-Color -Text "Retrieving Virtual Network Parameters..." -Color Green
$VirtualNetworkName = "${env:AZURE_GROUP}-vnet"
Write-Color -Text "$env:AZURE_GROUP  $VirtualNetworkName $Subnet" -Color White

Write-Color -Text "`r`n---------------------------------------------------- "-Color Yellow
Write-Color -Text "Deploying ", "$DEPLOYMENT ", "template..." -Color Green, Red, Green
Write-Color -Text "---------------------------------------------------- "-Color Yellow
New-AzureRmResourceGroupDeployment -Name "${DEPLOYMENT}-${ImageOffer}" `
  -TemplateFile $BASE_DIR\azuredeploy.json `
  -TemplateParameterFile $BASE_DIR\azuredeploy.parameters.json `
  -prefix $env:AZURE_GROUP -vmName $VmName `
  -imagePublisher $ImagePublisher -imageOffer $ImageOffer -imageSku $ImageSku `
  -diagnosticsStorageName $StorageAccountName `
  -adminUserName $AdminUserName -adminPassword $AdminPassword `
  -vnetGroup $env:AZURE_GROUP -vnet $VirtualNetworkName -subnet $Subnet `
  -ResourceGroupName $ResourceGroupName
