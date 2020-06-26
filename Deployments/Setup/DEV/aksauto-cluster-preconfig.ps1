param([Parameter(Mandatory=$false)] [string] $resourceGroup = "aks-workshop-rg",
        [Parameter(Mandatory=$false)] [string] $dvoResourceGroup = "devops-workshop-rg",
        [Parameter(Mandatory=$false)] [string] $projectName = "aks-workshop",
        [Parameter(Mandatory=$false)] [string] $location = "eastus",
        [Parameter(Mandatory=$false)] [string] $clusterName = "aks-workshop-cluster",
        [Parameter(Mandatory=$false)] [string] $acrName = "akswkshpacr",
        [Parameter(Mandatory=$false)] [string] $keyVaultName = "aks-workshop-kv",
        [Parameter(Mandatory=$false)] [string] $aksVNetName = "aks-workshop-vnet",
        [Parameter(Mandatory=$false)] [string] $aksVNetPrefix = "173.0.0.0/16",
        [Parameter(Mandatory=$false)] [string] $dvoVNetName = "devops-workshop-vnet",
        [Parameter(Mandatory=$false)] [string] $dvoSubetName = "devops-workshop-subnet",
        [Parameter(Mandatory=$false)] [string] $aksSubnetName = "aks-workshop-subnet",
        [Parameter(Mandatory=$false)] [string] $aksSubNetPrefix = "173.0.0.0/22",
        [Parameter(Mandatory=$false)] [string] $appgwSubnetName = "aks-workshop-appgw-subnet",
        [Parameter(Mandatory=$false)] [string] $appgwSubnetPrefix = "173.0.4.0/27",
        [Parameter(Mandatory=$false)] [string] $vrnSubnetName = "vrn-workshop-subnet",
        [Parameter(Mandatory=$false)] [string] $vrnSubnetPrefix = "173.0.5.0/24",
        [Parameter(Mandatory=$false)] [string] $appgwName = "aks-workshop-appgw",
        [Parameter(Mandatory=$false)] [string] $networkTemplateFileName = "aksauto-network-deploy",
        [Parameter(Mandatory=$false)] [string] $acrTemplateFileName = "aksauto-acr-deploy",
        [Parameter(Mandatory=$false)] [string] $kvTemplateFileName = "aksauto-keyvault-deploy",
        [Parameter(Mandatory=$false)] [string] $pepConfigFileName = "aksauto-pep-config",
        [Parameter(Mandatory=$false)] [string] $pepTemplateFileName = "aksauto-pep-deploy",
        [Parameter(Mandatory=$false)] [string] $acrPvtLinkFileName = "aksauto-acr-plink-config",
        [Parameter(Mandatory=$false)] [string] $kvPvtLinkFileName = "aksauto-kv-plink-config",
        [Parameter(Mandatory=$false)] [string] $subscriptionId = "6bdcc705-8db6-4029-953a-e749070e6db6",
        [Parameter(Mandatory=$false)] [string] $objectId = "890c52c5-d318-4185-a548-e07827190ff6",
        [Parameter(Mandatory=$false)] [string] $baseFolderPath = "/home/devops-vm-ubuntu1804/Deployments") # on devops machine

$vnetRole = "Network Contributor"
$aksSPIdName = $clusterName + "-sp-id"
$aksSPSecretName = $clusterName + "-sp-secret"
$acrSPIdName = $acrName + "-sp-id"
$acrSPSecretName = $acrName + "-sp-secret"
$certSecretName = $appgwName + "-cert-secret"

$acrAKSPepName = $projectName + "acr-aks-pep"
$acrAKSPepConnectionName = $acrAKSPepName + "-conn"
$acrDevOpsPepName = $projectName + "acr-devops-pep"
$acrDevOpsPepConnectionName = $acrDevOpsPepName + "-conn"
$acrPepResourceType = "Microsoft.ContainerRegistry/registries"
$acrPepSubResourceId = "registry"
$kvDevOpsPepName = $projectName + "kv-devops-pep"
$kvDevOpsPepConnectionName = $kvDevOpsPepName + "-conn"
$kvPepResourceType = "Microsoft.KeyVault/vaults"
$kvPepSubResourceId = "vault"
$acrAKSVnetLinkName = $acrAKSPepName + "-link"
$acrDevOpsVnetLinkName = $acrDevOpsPepName + "-link"
$kvDevOpsVnetLinkName = $kvDevOpsPepName + "-link"

$templatesFolderPath = $baseFolderPath + "/Templates/DEV"
$setupFolderPath = $baseFolderPath + "/Setup/DEV"
$certPFXFilePath = $baseFolderPath + "/Certs/aksauto.pfx"

# Assuming Logged In

$networkNames = "-aksVNetName $aksVNetName -aksVNetPrefix $aksVNetPrefix -aksSubnetName $aksSubnetName -aksSubNetPrefix $aksSubNetPrefix -appgwSubnetName $appgwSubnetName -appgwSubnetPrefix $appgwSubnetPrefix -vrnSubnetName $vrnSubnetName -vrnSubnetPrefix $vrnSubnetPrefix"
$networkDeployCommand = "/Network/$networkTemplateFileName.ps1 -rg $resourceGroup -fpath $templatesFolderPath -deployFileName $networkTemplateFileName $networkNames"

$acrDeployCommand = "/ACR/$acrTemplateFileName.ps1 -rg $resourceGroup -fpath $templatesFolderPath -deployFileName $acrTemplateFileName -acrName $acrName"
$keyVaultDeployCommand = "/KeyVault/$kvTemplateFileName.ps1 -rg $resourceGroup -fpath $templatesFolderPath -deployFileName $kvTemplateFileName -keyVaultName $keyVaultName -objectId $objectId"

$acrAKSPepNames = "-pepName $acrAKSPepName -pepConnectionName $acrAKSPepConnectionName -pepResourceType $acrPepResourceType -pepResourceName $acrName -pepTemplateFileName $pepTemplateFileName -pepSubResourceId $acrPepSubResourceId"
$acrAKSPepDeployCommand = "/Security/$pepConfigFileName.ps1 -resourceGroup $resourceGroup -vnetResourceGroup $resourceGroup -vnetName $aksVNetName -subnetName $aksSubnetName -baseFolderPath $baseFolderPath $acrAKSPepNames"

$acrAKSPvtLinkNames = "-pepName $acrAKSPepName -pepResourceName $acrName -vnetLinkName $acrAKSVnetLinkName"
$acrAKSPvtLinkDeployCommand = "/Security/$acrPvtLinkFileName.ps1 -resourceGroup $resourceGroup -vnetResourceGroup $resourceGroup -location $location -vnetName $aksVNetName $acrAKSPvtLinkNames"

$acrDevOpsPepNames = "-pepName $acrDevOpsPepName -pepConnectionName $acrDevOpsPepConnectionName -pepResourceType $acrPepResourceType -pepResourceName $acrName -pepTemplateFileName $pepTemplateFileName -pepSubResourceId $acrPepSubResourceId"
$acrDevOpsPepDeployCommand = "/Security/$pepConfigFileName.ps1 -resourceGroup $resourceGroup -vnetResourceGroup $dvoResourceGroup -vnetName $dvoVNetName -subnetName $dvoSubetName -baseFolderPath $baseFolderPath $acrDevOpsPepNames"

$acrDevOpsPvtLinkNames = "-pepName $acrDevOpsPepName -pepResourceName $acrName -vnetLinkName $acrDevOpsVnetLinkName"
$acrDevOpsPvtLinkDeployCommand = "/Security/$acrPvtLinkFileName.ps1 -resourceGroup $resourceGroup -vnetResourceGroup $dvoResourceGroup -location $location -vnetName $dvoVNetName $acrDevOpsPvtLinkNames"

$kvDevOpsPepNames = "-pepName $kvDevOpsPepName -pepConnectionName $kvDevOpsPepConnectionName -pepResourceType $kvPepResourceType -pepResourceName $keyVaultName -pepTemplateFileName $pepTemplateFileName -pepSubResourceId $kvPepSubResourceId"
$kvDevOpsPepDeployCommand = "/Security/$pepConfigFileName.ps1 -resourceGroup $resourceGroup -vnetResourceGroup $dvoResourceGroup -vnetName $dvoVNetName -subnetName $dvoSubetName -baseFolderPath $baseFolderPath $kvDevOpsPepNames"

$kvDevOpsPvtLinkNames = "-pepName $kvDevOpsPepName -pepResourceName $keyVaultName -vnetLinkName $kvDevOpsVnetLinkName"
$kvDevOpsPvtLinkDeployCommand = "/Security/$kvPvtLinkFileName.ps1 -resourceGroup $resourceGroup -vnetResourceGroup $dvoResourceGroup -location $location -vnetName $dvoVNetName $kvDevOpsPvtLinkNames"

$acrUpdateNwRulesCommand = "az acr update --public-network-enabled false --name $acrName --resource-group $resourceGroup"
$kvUpdateNwRulesCommand = "Update-AzKeyVaultNetworkRuleSet -DefaultAction Deny -ResourceGroupName $resourceGroup -VaultName $keyVaultName"

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

$acrDeployPath = $templatesFolderPath + $acrDeployCommand
Invoke-Expression -Command $acrDeployPath

$keyVaultDeployPath = $templatesFolderPath + $keyVaultDeployCommand
Invoke-Expression -Command $keyVaultDeployPath

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

Invoke-Expression -Command $acrUpdateNwRulesCommand
$acrAKSPepDeployPath = $setupFolderPath + $acrAKSPepDeployCommand
Invoke-Expression -Command $acrAKSPepDeployPath

$acrAKSPvtLinkDeployPath = $setupFolderPath + $acrAKSPvtLinkDeployCommand
Invoke-Expression -Command $acrAKSPvtLinkDeployPath

$acrDevOpsPepDeployPath = $setupFolderPath + $acrDevOpsPepDeployCommand
Invoke-Expression -Command $acrDevOpsPepDeployPath

$acrDevOpsPvtLinkDeployPath = $setupFolderPath + $acrDevOpsPvtLinkDeployCommand
Invoke-Expression -Command $acrDevOpsPvtLinkDeployPath

Invoke-Expression -Command $kvUpdateNwRulesCommand
$kvDevOpsPepDeployPath = $setupFolderPath + $kvDevOpsPepDeployCommand
Invoke-Expression -Command $kvDevOpsPepDeployPath

$kvDevOpsPvtLinkDeployPath = $setupFolderPath + $kvDevOpsPvtLinkDeployCommand
Invoke-Expression -Command $kvDevOpsPvtLinkDeployPath

Write-Host "------Pre-Config------"
