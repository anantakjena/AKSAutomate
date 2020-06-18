param([Parameter(Mandatory=$true)] [string] $resourceGroup,
        [Parameter(Mandatory=$true)] [string] $projectName,
        [Parameter(Mandatory=$true)] [string] $location,
        [Parameter(Mandatory=$true)] [string] $clusterName,
        [Parameter(Mandatory=$true)] [string] $userEmail,
        [Parameter(Mandatory=$true)] [string] $acrName,
        [Parameter(Mandatory=$true)] [string] $keyVaultName,
        [Parameter(Mandatory=$true)] [string] $aksVNetName,
        [Parameter(Mandatory=$true)] [string] $aksVNetPrefix,
        [Parameter(Mandatory=$true)] [string] $secVNetName,
        [Parameter(Mandatory=$true)] [string] $secVNetPrefix,
        [Parameter(Mandatory=$true)] [string] $dvoVNetName,        
        [Parameter(Mandatory=$true)] [string] $aksSubnetName,
        [Parameter(Mandatory=$true)] [string] $aksSubNetPrefix,
        [Parameter(Mandatory=$true)] [string] $acrSubnetName,
        [Parameter(Mandatory=$true)] [string] $acrSubNetPrefix,
        [Parameter(Mandatory=$true)] [string] $kvSubnetName,
        [Parameter(Mandatory=$true)] [string] $kvSubnetPrefix,
        [Parameter(Mandatory=$true)] [string] $appgwSubnetName,
        [Parameter(Mandatory=$true)] [string] $appgwSubnetPrefix,
        [Parameter(Mandatory=$true)] [string] $vrnSubnetName,
        [Parameter(Mandatory=$true)] [string] $vrnSubnetPrefix,        
        [Parameter(Mandatory=$true)] [string] $appgwName,        
        [Parameter(Mandatory=$true)] [string] $networkTemplateFileName,
        [Parameter(Mandatory=$true)] [string] $securityNetworkTemplateFileName,        
        [Parameter(Mandatory=$true)] [string] $acrTemplateFileName,
        [Parameter(Mandatory=$true)] [string] $kvTemplateFileName,
        [Parameter(Mandatory=$true)] [string] $pepTemplateFileName,        
        [Parameter(Mandatory=$true)] [string] $subscriptionId,
        [Parameter(Mandatory=$true)] [string] $baseFolderPath)

$vnetRole = "Network Contributor"
$aksSPIdName = $clusterName + "-sp-id"
$aksSPSecretName = $clusterName + "-sp-secret"
$acrSPIdName = $acrName + "-sp-id"
$acrSPSecretName = $acrName + "-sp-secret"
$certSecretName = $appgwName + "-cert-secret"
$acrPEPName = $projectName + "-acr-pep"
$acrPEPConnectionName = $projectName + "-acr-pep-conn"
$acrPEPResourceType = "Microsoft.ContainerRegistry/registries"
$acrPEPSubResourceId = "registry"
$kvPEPName = $projectName + "-kv-pep"
$kvPEPConnectionName = $projectName + "-kv-pep-conn"
$kvPEPResourceType = "Microsoft.KeyVault/vaults"
$kvPEPSubResourceId = "vault"
$dvoToSecPeerName = $projectName + "-devops-security-peer"
$secToDvoPeerName = $projectName + "-security-devops-peer"
$templatesFolderPath = $baseFolderPath + "/Templates/DEV"
$certPFXFilePath = $baseFolderPath + "/Certs/aksauto.pfx"

# Assuming Logged In

# GET ObjectID
$loggedInUser = Get-AzADUser -UserPrincipalName $userEmail
$objectId = $loggedInUser.Id

$networkNames = "-aksVNetName $aksVNetName -aksVNetPrefix $aksVNetPrefix -aksSubnetName $aksSubnetName -aksSubNetPrefix $aksSubNetPrefix -appgwSubnetName $appgwSubnetName -appgwSubnetPrefix $appgwSubnetPrefix -vrnSubnetName $vrnSubnetName -vrnSubnetPrefix $vrnSubnetPrefix"
$networkDeployCommand = "/Network/$networkTemplateFileName.ps1 -rg $resourceGroup -fpath $templatesFolderPath -deployFileName $networkTemplateFileName $networkNames"

$securityNetworkNames = "-secVNetName $secVNetName -secVNetPrefix $secVNetPrefix -acrSubnetName $acrSubnetName -acrSubNetPrefix $acrSubNetPrefix -kvSubnetName $kvSubnetName -kvSubnetPrefix $kvSubnetPrefix"
$securityNetworkDeployCommand = "/Network/$securityNetworkTemplateFileName.ps1 -rg $resourceGroup -fpath $templatesFolderPath -deployFileName $securityNetworkTemplateFileName $securityNetworkNames"

$acrDeployCommand = "/ACR/$acrTemplateFileName.ps1 -rg $resourceGroup -fpath $templatesFolderPath -deployFileName $acrTemplateFileName -acrName $acrName -vnetName $secVNetName -subnetName $acrSubnetName"
$keyVaultDeployCommand = "/KeyVault/$kvTemplateFileName.ps1 -rg $resourceGroup -fpath $templatesFolderPath -deployFileName $kvTemplateFileName -keyVaultName $keyVaultName -vnetName $secVNetName -subnetName $kvSubnetName -objectId $objectId"

$acrPEPNames = "-privateEndpointName $acrPEPName -privateEndpointConnectionName $acrPEPConnectionName -pepResourceType $acrPEPResourceType -pepResourceName $acrName -subResourceId $acrPEPSubResourceId"
$acrPEPDeployCommand = "/Network/$pepTemplateFileName.ps1 -rg $resourceGroup -fpath $templatesFolderPath -deployFileName $pepTemplateFileName -vnetName $secVNetName -subnetName $acrSubnetName $acrPEPNames"

$kvPEPNames = "-privateEndpointName $kvPEPName -privateEndpointConnectionName $kvPEPConnectionName -pepResourceType $kvPEPResourceType -pepResourceName $keyVaultName -subResourceId $kvPEPSubResourceId"
$kvPEPDeployCommand = "/Network/$pepTemplateFileName.ps1 -rg $resourceGroup -fpath $templatesFolderPath -deployFileName $pepTemplateFileName -vnetName $secVNetName -subnetName $kvSubnetName $kvPEPNames"

# PS Select Subscriotion 
Select-AzSubscription -SubscriptionId $subscriptionId

# CLI Select Subscriotion 
$subscriptionCommand = "az account set -s $subscriptionId"
Invoke-Expression -Command $subscriptionCommand

$rgRef = Get-AzResourceGroup -Name $resourceGroup -Location $location
if (!$rgRef)
{

   $rgRef = New-AzResourceGroup -Name $resourceGroup -Location $location
   if (!$rgRef)
   {
        Write-Host "Error creating Resource Group"
        return;
   }

}

$aksSP = New-AzADServicePrincipal -SkipAssignment
if (!$aksSP)
{

    Write-Host "Error creating Service Principal for AKS"
    return;

}

Write-Host $aksSP.DisplayName
Write-Host $aksSP.Id
Write-Host $aksSP.ApplicationId

$acrSP = New-AzADServicePrincipal -SkipAssignment
if (!$acrSP)
{

    Write-Host "Error creating Service Principal for ACR"
    return;

}

Write-Host $acrSP.DisplayName
Write-Host $acrSP.Id
Write-Host $acrSP.ApplicationId

$networkDeployPath = $templatesFolderPath + $networkDeployCommand
Invoke-Expression -Command $networkDeployPath

$securityNetworkDeployPath = $templatesFolderPath + $securityNetworkDeployCommand
Invoke-Expression -Command $securityNetworkDeployPath

$secVnet = Get-AzVirtualNetwork -Name $secVNetName -ResourceGroupName $resourceGroup
$dvoVnet = Get-AzVirtualNetwork -Name $dvoVNetName -ResourceGroupName $resourceGroup
if ($secVnet && $dvoVnet)
{

    Add-AzVirtualNetworkPeering -Name $dvoToSecPeerName `
    -VirtualNetwork $dvoVnet `
    -RemoteVirtualNetworkId $secVnet.Id

    Add-AzVirtualNetworkPeering -Name $secToDvoPeerName `
    -VirtualNetwork $secVnet `
    -RemoteVirtualNetworkId $dvoVnet.Id

}

$acrDeployPath = $templatesFolderPath + $acrDeployCommand
Invoke-Expression -Command $acrDeployPath

$keyVaultDeployPath = $templatesFolderPath + $keyVaultDeployCommand
Invoke-Expression -Command $keyVaultDeployPath

$acrPEPDeployPath = $templatesFolderPath + $acrPEPDeployCommand
Invoke-Expression -Command $acrPEPDeployPath

$kvPEPDeployPath = $templatesFolderPath + $kvPEPDeployCommand
Invoke-Expression -Command $kvPEPDeployPath

Write-Host $certPFXFilePath
$certBytes = [System.IO.File]::ReadAllBytes($certPFXFilePath)
$certContents = [Convert]::ToBase64String($certBytes)
$certContentsSecure = ConvertTo-SecureString -String $certContents -AsPlainText -Force
Write-Host $certPFXFilePath

$aksSPObjectId = ConvertTo-SecureString -String $aksSP.ApplicationId `
-AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $aksSPIdName `
-SecretValue $aksSPObjectId

Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $aksSPSecretName `
-SecretValue $aksSP.Secret

$acrSPObjectId = ConvertTo-SecureString -String $acrSP.ApplicationId `
-AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $acrSPIdName `
-SecretValue $acrSPObjectId

Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $acrSPSecretName `
-SecretValue $acrSP.Secret

Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $certSecretName `
-SecretValue $certContentsSecure

$aksVnet = Get-AzVirtualNetwork -Name $aksVNetName -ResourceGroupName $resourceGroup
if ($aksVnet)
{

    New-AzRoleAssignment -ApplicationId $aksSP.ApplicationId `
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

Write-Host "Pre-Config Successfully Done!"
