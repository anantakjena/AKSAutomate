param([Parameter(Mandatory=$true)] [string] $mode,
        [Parameter(Mandatory=$false)] [string] $resourceGroup,
        [Parameter(Mandatory=$false)] [string] $location,
        [Parameter(Mandatory=$false)] [string] $clusterName,
        [Parameter(Mandatory=$false)] [string] $keyVaultName,
        [Parameter(Mandatory=$false)] [string] $aksVNetName,
        [Parameter(Mandatory=$false)] [string] $aksSubnetName,
        [Parameter(Mandatory=$false)] [string] $vrnSubnetName,
        [Parameter(Mandatory=$false)] [string] $version,
        [Parameter(Mandatory=$false)] [string] $addons,
        [Parameter(Mandatory=$false)] [string] $nodeCount,
        [Parameter(Mandatory=$false)] [string] $minNodeCount,
        [Parameter(Mandatory=$false)] [string] $maxNodeCount,
        [Parameter(Mandatory=$false)] [string] $maxPods,
        [Parameter(Mandatory=$false)] [string] $vmSetType,
        [Parameter(Mandatory=$false)] [string] $nodeVMSize,
        [Parameter(Mandatory=$false)] [string] $networkPlugin,
        [Parameter(Mandatory=$false)] [string] $networkPolicy,
        [Parameter(Mandatory=$false)] [string] $nodePoolName,        
        [Parameter(Mandatory=$false)] [string] $aadServerAppID,
        [Parameter(Mandatory=$false)] [string] $aadServerAppSecret,
        [Parameter(Mandatory=$false)] [string] $aadClientAppID,
        [Parameter(Mandatory=$false)] [string] $aadTenantID)


$aksSPIdName = $clusterName + "-sp-id"
$aksSPSecretName = $clusterName + "-sp-secret"
$createSuccessCommand =  "@length(agentPoolProfiles)"
$updateSuccessCommand =  "length(@)"

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

    Write-Host "Creating Cluster... $clusterName"

    $result = az aks create --name $clusterName --resource-group $resourceGroup `
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
    --aad-tenant-id $aadTenantID `
    --query $createSuccessCommand

    if ($result -le 0)
    {

        Write-Host "Error Creating AKS Cluster - $clusterName"
        return;
    
    }
    
}
elseif ($mode -eq "update")
{

    Write-Host "Updating Cluster... $clusterName"
    
    $result = az aks nodepool update --cluster-name $clusterName `
    --resource-group $resourceGroup --enable-cluster-autoscaler `
    --min-count $minNodeCount --max-count $maxNodeCount `
    --name $nodePoolName --query $updateSuccessCommand

    if ($result -le 0)
    {

        Write-Host "Error Updating AKS Cluster - $clusterName"
        return;
    
    }
    
}
elseif ($mode -eq "scale")
{

    Write-Host "Scaling Cluster... $clusterName"

    $result = az aks nodepool scale --cluster-name $clusterName `
    --resource-group $resourceGroup `
    --node-count $nodeCount --name $nodePoolName `
    --query $updateSuccessCommand

    if ($result -le 0)
    {

        Write-Host "Error Scaling AKS Cluster - $clusterName"
        return;
    
    }
    
}

Write-Host "Cluster Setup Successfully Done!"

