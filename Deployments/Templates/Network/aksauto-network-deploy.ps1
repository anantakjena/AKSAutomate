param([Parameter(Mandatory=$true)] [string] $rg,
        [Parameter(Mandatory=$true)] [string] $fpath,
        [Parameter(Mandatory=$true)] [string] $aksVNetName,
        [Parameter(Mandatory=$true)] [string] $aksSubnetName,
        [Parameter(Mandatory=$true)] [string] $appgwSubnetName)

Test-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/Network/aksauto-network-deploy.json" `
-aksVNetName $aksVNetName -aksSubnetName $aksSubnetName `
-appgwSubnetName $appgwSubnetName

New-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/Network/aksauto-network-deploy.json" `
-aksVNetName $aksVNetName -aksSubnetName $aksSubnetName `
-appgwSubnetName $appgwSubnetName