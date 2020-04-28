param([Parameter(Mandatory=$false)] [string] $resourceGroup = "aks-workshop-rg",
        [Parameter(Mandatory=$false)] [string] $networkSPIdName = "network-sp-id",
        [Parameter(Mandatory=$false)] [string] $networkSPSecretName = "network-sp-secret",
        [Parameter(Mandatory=$false)] [string] $acrSPIdName = "acr-sp-id",
        [Parameter(Mandatory=$false)] [string] $acrSPSecretName = "acr-sp-secret",
        [Parameter(Mandatory=$false)] [string] $acrName = "akswkshpacr",
        [Parameter(Mandatory=$false)] [string] $keyVaultName = "aks-workshop-kv",
        [Parameter(Mandatory=$false)] [string] $aksVNetName = "aks-workshop-vnet",
        [Parameter(Mandatory=$false)] [string] $aksSubnetName = "aks-workshop-subnet",
        [Parameter(Mandatory=$false)] [string] $vrnSubnetName = "vrn-workshop-subnet",
        [Parameter(Mandatory=$false)] [string] $appgwSubnetName = "appgw-workshop-subnet",
        [Parameter(Mandatory=$false)] [string] $certSecretName = "aks-appgw-secret",
        [Parameter(Mandatory=$false)] [string] $subscriptionId = "6bdcc705-8db6-4029-953a-e749070e6db6",
        [Parameter(Mandatory=$false)] [string] $objectId = "890c52c5-d318-4185-a548-e07827190ff6",
        [Parameter(Mandatory=$false)] [string] $baseFolderPath = "/Users/monojitdattams/Development/Projects/Workshops/AKSAutomate/Deployments")

$vnetRole = "Network Contributor"
$templatesFolderPath = $baseFolderPath + "/Templates"
$certPFXFilePath = $baseFolderPath + "/Certs/aksauto.pfx"

$loginCommand = "az login"
$logoutCommand = "az logout"
$subscriptionCommand = "az account set -s $subscriptionId"

$networkNames = "-aksVNetName $aksVNetName -aksSubnetName $aksSubnetName -vrnSubnetName $vrnSubnetName -appgwSubnetName $appgwSubnetName"
$networkDeployCommand = "/Network/aksauto-network-deploy.ps1 -rg $resourceGroup -fpath $templatesFolderPath $networkNames"

$acrDeployCommand = "/ACR/aksauto-acr-deploy.ps1 -rg $resourceGroup -fpath $templatesFolderPath -acrName $acrName"
$keyVaultDeployCommand = "/KeyVault/aksauto-keyvault-deploy.ps1 -rg $resourceGroup -fpath $templatesFolderPath -keyVaultName $keyVaultName -objectId $objectId"

# PS Logout
Disconnect-AzAccount

# CLI Logout
Invoke-Expression -Command $logoutCommand

# PS Login
Connect-AzAccount

# CLI Login
Invoke-Expression -Command $loginCommand

# PS Select Subscriotion 
Select-AzSubscription -SubscriptionId $subscriptionId

# CLI Select Subscriotion 
Invoke-Expression -Command $subscriptionCommand

$networkSP = New-AzADServicePrincipal -SkipAssignment
if (!$networkSP)
{

    Write-Host "Error creating Service Principal"
    return;

}

Write-Host $networkSP.DisplayName
Write-Host $networkSP.Id
Write-Host $networkSP.ApplicationId

$acrSP = New-AzADServicePrincipal -SkipAssignment
if (!$acrSP)
{

    Write-Host "Error creating Service Principal"
    return;

}

Write-Host $acrSP.DisplayName
Write-Host $acrSP.Id
Write-Host $acrSP.ApplicationId

$networkDeployPath = $templatesFolderPath + $networkDeployCommand
Invoke-Expression -Command $networkDeployPath

$acrDeployPath = $templatesFolderPath + $acrDeployCommand
Invoke-Expression -Command $acrDeployPath

$keyVaultDeployPath = $templatesFolderPath + $keyVaultDeployCommand
Invoke-Expression -Command $keyVaultDeployPath

$certBytes = [System.IO.File]::ReadAllBytes($certPFXFilePath)
$certContents = [Convert]::ToBase64String($certBytes)
$certContentsSecure = ConvertTo-SecureString -String $certContents `
-AsPlainText -Force

$networkSPObjectId = ConvertTo-SecureString -String $networkSP.ApplicationId `
-AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $networkSPIdName `
-SecretValue $networkSPObjectId

Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $networkSPSecretName `
-SecretValue $networkSP.Secret

$acrSPObjectId = ConvertTo-SecureString -String $acrSP.ApplicationId `
-AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $acrSPIdName `
-SecretValue $acrSPObjectId

Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $acrSPSecretName `
-SecretValue $acrSP.Secret

Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $certSecretName `
-SecretValue $certContentsSecure

$aksVnet = Get-AzVirtualNetwork -Name $aksVNetName `
-ResourceGroupName $resourceGroup
if ($aksVnet)
{

    Write-Host $aksVnet.Id
    New-AzRoleAssignment -ApplicationId $networkSP.ApplicationId `
    -Scope $aksVnet.Id -RoleDefinitionName $vnetRole

}

$acrInfo = Get-AzContainerRegistry -Name $acrName `
-ResourceGroupName $resourceGroup
if ($acrInfo)
{

    Write-Host $acrInfo.Id
    New-AzRoleAssignment -ApplicationId $acrSP.ApplicationId `
    -Scope $acrInfo.Id -RoleDefinitionName acrpush

}

Write-Host "Pre-Config done"

