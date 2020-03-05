param([Parameter(Mandatory=$false)] [string] $resourceGroup = "aks-workshop-rg",
        [Parameter(Mandatory=$false)] [string] $clusterName = "aks-workshop-cluster",
        [Parameter(Mandatory=$false)] [string] $spIdName = "aks-workshop-sp-id",
        [Parameter(Mandatory=$false)] [string] $acrName = "akswkshpacr",
        [Parameter(Mandatory=$false)] [string] $keyVaultName = "aks-workshop-kv",
        [Parameter(Mandatory=$false)] [string] $aksVNetName = "aks-workshop-vnet",
        [Parameter(Mandatory=$false)] [string] $applicationGatewayName = "aks-workshop-appgw",        
        [Parameter(Mandatory=$false)] [string] $subscriptionId = "6bdcc705-8db6-4029-953a-e749070e6db6")        

$publicIpAddressName = "$applicationGatewayName-pip"

$loginCommand = "az login"
$logoutCommand = "az logout"
$subscriptionCommand = "az account set -s $subscriptionId"

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

az aks delete --name $clusterName --resource-group $resourceGroup

Remove-AzApplicationGateway -Name $applicationGatewayName `
-ResourceGroupName $resourceGroup -Force

Remove-AzPublicIpAddress -Name $publicIpAddressName `
-ResourceGroupName $resourceGroup

Remove-AzVirtualNetwork -Name $aksVNetName -ResourceGroupName $resourceGroup -Force

Remove-AzContainerRegistry -Name $acrName -ResourceGroupName $resourceGroup

$keyVault = Get-AzKeyVault -ResourceGroupName $resourceGroup -VaultName $keyVaultName
if ($keyVault)
{

    $spAppId = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $spIdName
    if ($spAppId)
    {

        Remove-AzADServicePrincipal -ApplicationId $spAppId.SecretValueText -Force
        
    }

    Remove-AzKeyVault -InputObject $keyVault -Force

}

Disconnect-AzAccount
Invoke-Expression -Command $logoutCommand


