param([Parameter(Mandatory=$true)] [string] $mode,
        [Parameter(Mandatory=$false)] [string] $resourceGroup,
        [Parameter(Mandatory=$false)] [string] $location,
        [Parameter(Mandatory=$false)] [string] $clusterName,        
        [Parameter(Mandatory=$false)] [string] $aksVNetName,
        [Parameter(Mandatory=$false)] [string] $aksSubnetName,        
        [Parameter(Mandatory=$false)] [string] $version,        
        [Parameter(Mandatory=$false)] [string] $nodeCount,
        [Parameter(Mandatory=$false)] [string] $minNodeCount,
        [Parameter(Mandatory=$false)] [string] $maxNodeCount,
        [Parameter(Mandatory=$false)] [string] $maxPods,
        [Parameter(Mandatory=$false)] [string] $vmSetType,
        [Parameter(Mandatory=$false)] [string] $nodeVMSize,        
        [Parameter(Mandatory=$false)] [string] $nodePoolName)

$configSuccessCommand =  "length(@)"

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
    
    Write-Host "Adding Nodepool... $nodePoolName"

    $result = az aks nodepool add --cluster-name $clusterName `
    --resource-group $resourceGroup `
    --name $nodePoolName `
    --kubernetes-version $version `
    --max-pods $maxPods `
    --node-count $nodeCount `
    --node-vm-size $nodeVMSize `
    --query $configSuccessCommand

    Write-Host "Result - $result"

    if ($result -le 0)
    {

        Write-Host "Error Creating Nodepool - $nodePoolName"
        return;
    
    }

}
elseif ($mode -eq "update")
{

    Write-Host "Updating Nodepool... $nodePoolName"
    
    $result = az aks nodepool update --cluster-name $clusterName `
    --resource-group $resourceGroup --enable-cluster-autoscaler `
    --min-count $minNodeCount --max-count $maxNodeCount `
    --name $nodePoolName --query $configSuccessCommand

    if ($result -le 0)
    {

        Write-Host "Error Updating Nodepool - $nodePoolName"
        return;
    
    }
    
}
elseif ($mode -eq "scale")
{

    Write-Host "Scaling Nodepool... $nodePoolName"

    $result = az aks nodepool scale --cluster-name $clusterName `
    --resource-group $resourceGroup --node-count $nodeCount `
    --name $nodePoolName `
    --query $configSuccessCommand

    Write-Host "Result - $result"

    if ($result -le 0)
    {

        Write-Host "Error Scaling Nodepool - $nodePoolName"
        return;
    
    }
    
}
elseif ($mode -eq "delete")
{

    Write-Host "Deleting Nodepool... $nodePoolName"

    az aks nodepool delete --cluster-name $clusterName `
    --resource-group $resourceGroup --name $nodePoolName
    
}

Write-Host "Cluster Setup Successfully Done!"

