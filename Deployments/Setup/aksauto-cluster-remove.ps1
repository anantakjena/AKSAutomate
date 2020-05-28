param([Parameter(Mandatory=$true)] [string] $resourceGroup,
        [Parameter(Mandatory=$true)] [string] $clusterName,
        [Parameter(Mandatory=$true)] [string] $acrName,
        [Parameter(Mandatory=$true)] [string] $keyVaultName,
        [Parameter(Mandatory=$true)] [string] $aksVNetName,
        [Parameter(Mandatory=$true)] [string] $appgwName,
        [Parameter(Mandatory=$true)] [string] $subscriptionId)

$aksSPIdName = $clusterName + "-sp-id"
$publicIpAddressName = "$appgwName-pip"
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

Write-Host "Successfully Removed!"