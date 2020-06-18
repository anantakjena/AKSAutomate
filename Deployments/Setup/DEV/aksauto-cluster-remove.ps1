param([Parameter(Mandatory=$true)] [string] $resourceGroup,
        [Parameter(Mandatory=$true)] [string] $projectName,
        [Parameter(Mandatory=$true)] [string] $clusterName,
        [Parameter(Mandatory=$true)] [string] $acrName,
        [Parameter(Mandatory=$true)] [string] $keyVaultName,        
        [Parameter(Mandatory=$true)] [string] $aksVNetName,
        [Parameter(Mandatory=$true)] [string] $secVNetName,
        [Parameter(Mandatory=$true)] [string] $dvoVNetName,
        [Parameter(Mandatory=$true)] [string] $appgwName,
        [Parameter(Mandatory=$true)] [string] $subscriptionId)

$aksSPIdName = $clusterName + "-sp-id"
$publicIpAddressName = "$appgwName-pip"
$acrPEPName = $projectName + "-acr-pep"
$kvPEPName = $projectName + "-kv-pep"
$dvoToSecPeerName = $projectName + "-devops-security-peer"
$secToDvoPeerName = $projectName + "-security-devops-peer"
$subscriptionCommand = "az account set -s $subscriptionId"

# PS Select Subscriotion 
Select-AzSubscription -SubscriptionId $subscriptionId

# CLI Select Subscriotion 
Invoke-Expression -Command $subscriptionCommand

az aks delete --name $clusterName --resource-group $resourceGroup --yes

Remove-AzApplicationGateway -Name $appgwName `
-ResourceGroupName $resourceGroup -Force

Remove-AzPublicIpAddress -Name $publicIpAddressName `
-ResourceGroupName $resourceGroup -Force

Remove-AzVirtualNetwork -Name $aksVNetName `
-ResourceGroupName $resourceGroup -Force

Remove-AzPrivateEndpoint -ResourceGroupName $resourceGroup `
-Name $acrPEPName -Force

Remove-AzPrivateEndpoint -ResourceGroupName $resourceGroup `
-Name $kvPEPName -Force

Remove-AzContainerRegistry -Name $acrName `
-ResourceGroupName $resourceGroup

$keyVault = Get-AzKeyVault -ResourceGroupName $resourceGroup `
-VaultName $keyVaultName
if ($keyVault)
{

    $spAppId = Get-AzKeyVaultSecret -VaultName $keyVaultName `
    -Name $aksSPIdName
    if ($spAppId)
    {        
     
        Remove-AzADServicePrincipal `
        -ApplicationId $spAppId.SecretValueText -Force
        
    }

    Remove-AzKeyVault -InputObject $keyVault -Force

}

$secVnet = Get-AzVirtualNetwork -Name $secVNetName -ResourceGroupName $resourceGroup
$dvoVnet = Get-AzVirtualNetwork -Name $dvoVNetName -ResourceGroupName $resourceGroup
if ($secVnet && $dvoVnet)
{

    Remove-AzVirtualNetworkPeering -Name $dvoToSecPeerName `
    -VirtualNetworkName $dvoVNetName

    Remove-AzVirtualNetworkPeering -Name $secToDvoPeerName `
    -VirtualNetworkName $secVNetName

}

Remove-AzVirtualNetwork -Name $secVNetName `
-ResourceGroupName $resourceGroup -Force

Write-Host "Successfully Removed!"