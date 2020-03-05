param([Parameter(Mandatory=$false)] [string] $resourceGroup = "aks-workshop-rg",
        [Parameter(Mandatory=$false)] [string] $spIdName = "aks-workshop-sp-id",
        [Parameter(Mandatory=$false)] [string] $spSecretName = "aks-workshop-sp-secret",
        [Parameter(Mandatory=$false)] [string] $acrName = "akswkshpacr",
        [Parameter(Mandatory=$false)] [string] $keyVaultName = "aks-workshop-kv",
        [Parameter(Mandatory=$false)] [string] $aksVNetName = "aks-workshop-vnet",
        [Parameter(Mandatory=$false)] [string] $aksSubnetName = "aks-workshop-subnet",
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

$networkNames = "-aksVNetName $aksVNetName -aksSubnetName $aksSubnetName -appgwSubnetName $appgwSubnetName"
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

$networkDeployPath = $templatesFolderPath + $networkDeployCommand
Invoke-Expression -Command $networkDeployPath

$acrDeployPath = $templatesFolderPath + $acrDeployCommand
Invoke-Expression -Command $acrDeployPath

$servicePrinciple = New-AzADServicePrincipal -SkipAssignment
if (!$servicePrinciple)
{

    Write-Host "Error creating Service Principal"
    return;

}

$secretBSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($servicePrinciple.Secret)
$secret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($secretBSTR)
Write-Host $servicePrinciple.DisplayName
Write-Host $servicePrinciple.Id
Write-Host $servicePrinciple.ApplicationId
Write-Host $secret

$spObjectId = ConvertTo-SecureString $servicePrinciple.ApplicationId `
-AsPlainText -Force

$keyVaultDeployPath = $templatesFolderPath + $keyVaultDeployCommand
Invoke-Expression -Command $keyVaultDeployPath

$certBytes = [System.IO.File]::ReadAllBytes($certPFXFilePath)
$certContents = [Convert]::ToBase64String($certBytes)
$certContentsSecure = ConvertTo-SecureString -String $certContents -AsPlainText -Force

$spObjectId = ConvertTo-SecureString -String $servicePrinciple.ApplicationId `
-AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $spIdName -SecretValue $spObjectId

Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $spSecretName `
-SecretValue $servicePrinciple.Secret

Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $certSecretName `
-SecretValue $certContentsSecure

$aksVnet = Get-AzVirtualNetwork -Name $aksVNetName -ResourceGroupName $resourceGroup
if ($aksVnet)
{

    New-AzRoleAssignment -ApplicationId $servicePrinciple.ApplicationId `
    -Scope $aksVnet.Id -RoleDefinitionName $vnetRole

}

Write-Host "Pre-Config done"

