param([string]$acr, [string]$vnet, [string]$keyVault, [string]$spId)

$customerName = "inmobi"
$projectName = "$customerName-workshop"
$location = "eastus"
$resourceGroup = "inmobi_workshop_rg"
$cluster = "$projectName-cluster"

az aks delete --name $cluster --resource-group $resourceGroup

$aksACR = Get-AzContainerRegistry -ResourceGroupName $resourceGroup -Name $acr
if ($aksACR)
{

    Remove-AzContainerRegistry -ResourceGroupName $resourceGroup -Name $acr

}

$aksWorkshopVnet = Get-AzVirtualNetwork -Name $vnet -ResourceGroupName $resourceGroup
if ($aksWorkshopVnet)
{

    Remove-AzVirtualNetwork -Name $vnet -ResourceGroupName $resourceGroup -Force

}

$aksKeyVault = Get-AzKeyVault -Name $keyVault -ResourceGroupName $resourceGroup
if ($aksKeyVault)
{

    Remove-AzKeyVault -VaultName $keyVault -ResourceGroupName $resourceGroup -Location $location -Force

}

Remove-AzADServicePrincipal -ObjectId $spId -Force
Write-Host "Removal done"
