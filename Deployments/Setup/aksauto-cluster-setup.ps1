param([Parameter(Mandatory=$true)] [string] $mode,
        [Parameter(Mandatory=$false)] [string] $resourceGroup = "aks-workshop-rg",
        [Parameter(Mandatory=$false)] [string] $location = "eastus",
        [Parameter(Mandatory=$false)] [string] $clusterName = "aks-workshop-cluster",        
        [Parameter(Mandatory=$false)] [string] $keyVaultName = "aks-workshop-kv",
        [Parameter(Mandatory=$false)] [string] $aksVNetName = "aks-workshop-vnet",
        [Parameter(Mandatory=$false)] [string] $aksSubnetName = "aks-workshop-subnet",
        [Parameter(Mandatory=$false)] [string] $vrnSubnetName = "vrn-workshop-subnet",
        [Parameter(Mandatory=$false)] [string] $version = "1.15.10",
        [Parameter(Mandatory=$false)] [string] $addons = "monitoring",
        [Parameter(Mandatory=$false)] [string] $nodeCount = 5,
        [Parameter(Mandatory=$false)] [string] $minNodeCount = $nodeCount,
        [Parameter(Mandatory=$false)] [string] $maxNodeCount = 100,
        [Parameter(Mandatory=$false)] [string] $maxPods = 50,
        [Parameter(Mandatory=$false)] [string] $vmSetType = "VirtualMachineScaleSets",
        [Parameter(Mandatory=$false)] [string] $nodeVMSize = "Standard_D8s_v3",
        [Parameter(Mandatory=$false)] [string] $networkPlugin = "azure",
        [Parameter(Mandatory=$false)] [string] $networkPolicy = "azure",
        [Parameter(Mandatory=$false)] [string] $nodePoolName = "aksiotpool",
        [Parameter(Mandatory=$false)] [string] $nodeResourceGroup = "aks-workshop-node-rg",
        [Parameter(Mandatory=$false)] [string] $aadServerAppID = "cd6c670a-b542-4e9d-a957-9f6e941c790e",
        [Parameter(Mandatory=$false)] [string] $aadServerAppSecret = "M3?8n_sJacW8Rc0mRcUzzQ=Atg-v53om",
        [Parameter(Mandatory=$false)] [string] $aadClientAppID = "9601340e-735e-4294-84da-44bfe43c85a1",
        [Parameter(Mandatory=$false)] [string] $aadTenantID = "bbe9b0ad-f1c1-4242-87f9-f22d7621beea")

# param([Parameter(Mandatory=$true)] [string] $mode,
#         [Parameter(Mandatory=$false)] [string] $resourceGroup,
#         [Parameter(Mandatory=$false)] [string] $location,
#         [Parameter(Mandatory=$false)] [string] $clusterName,
#         [Parameter(Mandatory=$false)] [string] $keyVaultName,
#         [Parameter(Mandatory=$false)] [string] $aksVNetName,
#         [Parameter(Mandatory=$false)] [string] $aksSubnetName,
#         [Parameter(Mandatory=$false)] [string] $vrnSubnetName,
#         [Parameter(Mandatory=$false)] [string] $version,
#         [Parameter(Mandatory=$false)] [string] $addons,
#         [Parameter(Mandatory=$false)] [string] $nodeCount,
#         [Parameter(Mandatory=$false)] [string] $minNodeCount,
#         [Parameter(Mandatory=$false)] [string] $maxNodeCount,
#         [Parameter(Mandatory=$false)] [string] $maxPods,
#         [Parameter(Mandatory=$false)] [string] $vmSetType,
#         [Parameter(Mandatory=$false)] [string] $nodeVMSize,
#         [Parameter(Mandatory=$false)] [string] $networkPlugin,
#         [Parameter(Mandatory=$false)] [string] $networkPolicy,
#         [Parameter(Mandatory=$false)] [string] $nodePoolName,
#         [Parameter(Mandatory=$false)] [string] $nodePool2Name,
#         [Parameter(Mandatory=$false)] [string] $nodeVMSizeNodePool2,
#         [Parameter(Mandatory=$false)] [string] $minNodeCountNodePool2,
#         [Parameter(Mandatory=$false)] [string] $maxNodeCountNodePool2,
#         [Parameter(Mandatory=$false)] [string] $maxPodsNodePool2,
#         [Parameter(Mandatory=$false)] [string] $nodeCountNodePool2,
#         [Parameter(Mandatory=$false)] [string] $aadServerAppID,
#         [Parameter(Mandatory=$false)] [string] $aadServerAppSecret,
#         [Parameter(Mandatory=$false)] [string] $aadClientAppID,
#         [Parameter(Mandatory=$false)] [string] $aadTenantID)


$aksSPIdName = $clusterName + "-sp-id"
$aksSPSecretName = $clusterName + "-sp-secret"

$keyVault = Get-AzKeyVault -ResourceGroupName $resourceGroup -VaultName $keyVaultName
if (!$keyVault)
{

    Write-Host "Error fetching KeyVault"
    return;

}

$spAppId = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $aksSPIdName
if (!$spAppId)
{

    Write-Host "Error fetching Service Principal Id"
    return;

}

$spPassword = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $aksSPSecretName
if (!$spPassword)
{

    Write-Host "Error fetching Service Principal Password"
    return;

}

$aksVnet = Get-AzVirtualNetwork -Name $aksVNetName `
-ResourceGroupName $resourceGroup
if (!$aksVnet)
{

    Write-Host "Error fetching Vnet"
    return;

}

$aksSubnet = Get-AzVirtualNetworkSubnetConfig -Name $aksSubnetName `
-VirtualNetwork $aksVnet
if (!$aksSubnet)
{

    Write-Host "Error fetching Subnet"
    return;

}

if ($mode -eq "create")
{

    Write-Host "Creating..."

    az aks create --name $clusterName --resource-group $resourceGroup `
    --kubernetes-version $version --location $location `
    --vnet-subnet-id $aksSubnet.Id --enable-addons $addons `
    --node-vm-size $nodeVMSize `
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

    Write-Host "Updating..."
    
    az aks nodepool update --cluster-name $clusterName --resource-group $resourceGroup `
    --enable-cluster-autoscaler --min-count $minNodeCount --max-count $maxNodeCount `
    --name $nodePoolName

    # az aks nodepool add --cluster-name $clusterName --resource-group $resourceGroup `
    # --name $nodePool2Name --kubernetes-version $version --max-pods $maxPodsNodePool2 `
    # --node-count $nodeCountNodePool2 --node-vm-size $nodeVMSizeNodePool2

    # az aks nodepool update --cluster-name $clusterName --resource-group $resourceGroup `
    # --enable-cluster-autoscaler --min-count $minNodeCountNodePool2 `
    # --max-count $maxNodeCountNodePool2 --name $nodePool2Name
    
}
# elseif ($mode -eq "scale")
# {

#     az aks nodepool scale --cluster-name $clusterName --resource-group $resourceGroup `
#     --node-count $nodeCount --name $nodePoolName
    
# }
elseif ($mode -eq "delete")
{

    az aks nodepool delete --cluster-name $clusterName --resource-group $resourceGroup `
    --name $nodePool2Name
    
}

Write-Host "Cluster Setup Successfully Done!"

