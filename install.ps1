<#
.SYNOPSIS
  Install the Full Infrastructure As Code Solution
.DESCRIPTION
  This Script will install all the infrastructure needed for the solution.

  1. Resource Group
  2. Virtual Network
  2. Storage Container
  3. Key Vault
  4. JumpBox Server(s)
  5. Common Diagnostics Storage
  6. Common Subnet Load Balancer
  7. Common Server(s)
  8. Container Diagnostics Storage
  9. Container Subnet Load Balancer
  10. Container Master Server(s)
  11. Container Worker Server(s)


.EXAMPLE
  .\install.ps1
  Version History
  v1.0   - Initial Release
#>
#Requires -Version 5.1
#Requires -Module @{ModuleName='AzureRM.Resources'; ModuleVersion='5.0'}

Param(
  [boolean] $Base = $false,
  [boolean] $Manage = $false,
  [boolean] $Common = $false,
  [boolean] $Container = $false,
  [string] $Prefix = $env:AZURE_GROUP
)
. ./.env.ps1
Get-ChildItem Env:AZURE*

if ($Base -eq $true) {
  Write-Host "Install Base Resources here we go...." -ForegroundColor "cyan"
  & ./iac-network/install.ps1
  & ./iac-storage/install.ps1
  & ./iac-keyvault/install.ps1

  Write-Host "---------------------------------------------" -ForegroundColor "blue"
  Write-Host "Base Components have been installed!!!!!" -ForegroundColor "red"
  Write-Host "---------------------------------------------" -ForegroundColor "blue"
}

if ($Manage -eq $true) {
  Write-Host "Install Management Resources here we go...." -ForegroundColor "cyan"
  $ResourceGroupName = $Prefix + "mgmt";

  # Create Diagnostics Storage Account
  & ./iac-storage/install.ps1 -ResourceGroupName $ResourceGroupName

  # Create Windows Jump Server
  & ./iac-publicVm/install.ps1 -ResourceGroupName $ResourceGroupName -VmName "jump-win"
  & ./ext-winBgInfo/install.ps1 -ResourceGroupName $ResourceGroupName -VmName "${Prefix}-jump-win"
  & ./ext-winDiagnostics/install.ps1 -ResourceGroupName $ResourceGroupName -VmName "${Prefix}-jump-win"

  # Create Linux Jump Server
  & ./iac-publicVM/install.ps1 -ResourceGroupName $ResourceGroupName -VmName 'jump-lin' `
    -ImagePublisher "Canonical" -ImageOffer "UbuntuServer" -ImageSku "16.04.0-LTS"
  
  Write-Host "---------------------------------------------" -ForegroundColor "blue"
  Write-Host "Management Components have been installed!!!!!" -ForegroundColor "red"
  Write-Host "---------------------------------------------" -ForegroundColor "blue"
}

if ($Common -eq $true) {
  Write-Host "Install Common Resources here we go...." -ForegroundColor "cyan"
  $ResourceGroupName = $Prefix + "comm";

  # Create Diagnostics Storage Account
  & ./iac-storage/install.ps1 -ResourceGroupName $ResourceGroupName

  # Create Internal Load Balancer
  & ./iac-internalLB/install.ps1 -ResourceGroupName $ResourceGroupName -Subnet "common-tier"

  # Create Common Windows Servers
  & ./iac-privateVM-win/install.ps1 -ResourceGroupName $ResourceGroupName -Subnet "common-tier" `
    -ImagePublisher "MicrosoftWindowsServer" -ImageOffer "WindowsServer" -ImageSku "2016-Datacenter"
}

if ($Container -eq $true) {
  Write-Host "Install Container Resources here we go...." -ForegroundColor "cyan"
  $ResourceGroupName = $Prefix + "cont";

  # Create Diagnostics Storage Account
  & ./iac-storage/install.ps1 -ResourceGroupName $ResourceGroupName

  # Create Internal Load Balancer
  & ./iac-internalLB/install.ps1 -ResourceGroupName $ResourceGroupName -Subnet "container-tier"

  # Create Container Master Nodes
  & ./iac-privateVM-linux/install.ps1 -ResourceGroupName $ResourceGroupName -Subnet "container-tier" `
    -ImagePublisher "Canonical" -ImageOffer "UbuntuServer" -ImageSku "16.04.0-LTS"

  # Create Container Worker Nodes
  & ./iac-privateVMss/install.ps1 -ResourceGroupName $ResourceGroupName -Subnet "container-tier" `
    -ImagePublisher "Canonical" -ImageOffer "UbuntuServer" -ImageSku "16.04.0-LTS" -VMName "lin"

  # Create Container Worker Nodes
  & ./iac-privateVMss/install.ps1 -ResourceGroupName $ResourceGroupName -Subnet "container-tier" `
    -ImagePublisher "MicrosoftWindowsServer" -ImageOffer "WindowsServer" -ImageSku "2016-Datacenter-with-Containers" -VMName "win"
}