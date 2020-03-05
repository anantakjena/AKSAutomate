param([Parameter(Mandatory=$true)] [string] $mode,
        [Parameter(Mandatory=$false)] [string] $resourceGroup = "aks-workshop-rg",
        [Parameter(Mandatory=$false)] [string] $location = "eastus",
        [Parameter(Mandatory=$false)] [string] $clusterName = "aks-workshop-cluster",
        [Parameter(Mandatory=$false)] [string] $spIdName = "aks-workshop-sp-id",
        [Parameter(Mandatory=$false)] [string] $spSecretName = "aks-workshop-sp-secret",
        [Parameter(Mandatory=$false)] [string] $acrName = "akswkshpacr",
        [Parameter(Mandatory=$false)] [string] $keyVaultName = "aks-workshop-kv",
        [Parameter(Mandatory=$false)] [string] $aksVNetName = "aks-workshop-vnet",
        [Parameter(Mandatory=$false)] [string] $aksSubnetName = "aks-workshop-subnet",
        [Parameter(Mandatory=$false)] [string] $version = "1.14.8",
        [Parameter(Mandatory=$false)] [string] $addons = "monitoring",
        [Parameter(Mandatory=$false)] [string] $nodeCount = 3,
        [Parameter(Mandatory=$false)] [string] $minNodeCount = 1,
        [Parameter(Mandatory=$false)] [string] $maxNodeCount = 60,
        [Parameter(Mandatory=$false)] [string] $maxPods = 50,
        [Parameter(Mandatory=$false)] [string] $vmSetType = "VirtualMachineScaleSets",
        [Parameter(Mandatory=$false)] [string] $nodeVMSize = "Standard_DS2_v2",
        [Parameter(Mandatory=$false)] [string] $networkPlugin = "azure",
        [Parameter(Mandatory=$false)] [string] $networkPolicy = "azure",
        [Parameter(Mandatory=$false)] [string] $nodePoolName = "akswkpool",
        [Parameter(Mandatory=$false)] [string] $nodeResourceGroup = "aks-workshop-node-rg",
        [Parameter(Mandatory=$false)] [string] $aadServerAppID = "cd6c670a-b542-4e9d-a957-9f6e941c790e",
        [Parameter(Mandatory=$false)] [string] $aadServerAppSecret = "M3?8n_sJacW8Rc0mRcUzzQ=Atg-v53om",
        [Parameter(Mandatory=$false)] [string] $aadClientAppID = "9601340e-735e-4294-84da-44bfe43c85a1",
        [Parameter(Mandatory=$false)] [string] $aadTenantID = "bbe9b0ad-f1c1-4242-87f9-f22d7621beea")

$keyVault = Get-AzKeyVault -ResourceGroupName $resourceGroup -VaultName $keyVaultName
if (!$keyVault)
{

    Write-Host "Error fetching KeyVault"
    return;

}

$spAppId = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $spIdName
if (!$spAppId)
{

    Write-Host "Error fetching Service Principal Id"
    return;

}

$spPassword = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $spSecretName
if (!$spPassword)
{

    Write-Host "Error fetching Service Principal Password"
    return;

}

$aksWorkshopVnet = Get-AzVirtualNetwork -Name $aksVNetName -ResourceGroupName $resourceGroup
if (!$aksWorkshopVnet)
{

    Write-Host "Error fetching Vnet"
    return;

}

$aksWorkshopSubnet = Get-AzVirtualNetworkSubnetConfig -Name $aksSubnetName `
-VirtualNetwork $aksWorkshopVnet
if (!$aksWorkshopSubnet)
{

    Write-Host "Error fetching Subnet"
    return;

}

if ($mode -eq "create")
{

    az aks create --name $clusterName --resource-group $resourceGroup `
    --node-resource-group $nodeResourceGroup `
    --kubernetes-version $version --enable-addons $addons --location $location `
    --vnet-subnet-id $aksWorkshopSubnet.Id --node-vm-size $nodeVMSize `
    --node-count $nodeCount --max-pods $maxPods `
    --service-principal $spAppId.SecretValueText `
    --client-secret $spPassword.SecretValueText `
    --network-plugin $networkPlugin --network-policy $networkPolicy `
    --nodepool-name $nodePoolName --vm-set-type $vmSetType `
    --generate-ssh-keys `
    --aad-client-app-id $aadClientAppID `
    --aad-server-app-id $aadServerAppID `
    --aad-server-app-secret $aadServerAppSecret `
    --aad-tenant-id $aadTenantID
    
}
elseif ($mode -eq "update")
{

    az aks update --name $clusterName --resource-group $resourceGroup `
    --attach-acr $acrName


    # az aks nodepool update --cluster-name $clusterName --resource-group $resourceGroup `
    # --enable-cluster-autoscaler --min-count $minNodeCount --max-count $maxNodeCount `
    # --name $nodePoolName


    # az aks update-credentials --name $clusterName --resource-group $resourceGroup `
    # --reset-aad `
    # --aad-client-app-id $aadClientAppID `
    # --aad-server-app-id $aadServerAppID `
    # --aad-server-app-secret $aadServerAppSecret `
    # --aad-tenant-id $aadTenantID

    
}
# elseif ($mode -eq "scale")
# {

#     az aks nodepool scale --cluster-name $clusterName --resource-group $resourceGroup `
#     --node-count $nodeCount --name $nodePoolName
    
# }

Write-Host "Cluster done"

