param([Parameter(Mandatory=$true)] [string] $resourceGroup,
      [Parameter(Mandatory=$true)] [string] $clusterName,
      [Parameter(Mandatory=$true)] [bool]   $shouldEnable,
      [Parameter(Mandatory=$true)] [array]  $ipAddressList)

$aksUpdateCommand = "az aks update -g $resourceGroup -n $clusterName --api-server-authorized-ip-ranges "

if ($shouldEnable -eq $false)
{
    $aksUpdateCommand = $aksUpdateCommand + """"
}
else
{
    
    $ipAddressString = $ipAddressList -join ","
    $aksUpdateCommand = $aksUpdateCommand + $ipAddressString

}

Invoke-Expression -Command $aksUpdateCommand