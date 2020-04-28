param([Parameter(Mandatory=$true)] [string] $rg,
        [Parameter(Mandatory=$true)] [string] $fpath,
        [Parameter(Mandatory=$true)] [string] $appgwName,
        [Parameter(Mandatory=$true)] [string] $vnetName,
        [Parameter(Mandatory=$true)] [string] $appgwSubnetName)

Test-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/AppGW/aksauto-appgw-deploy.json" `
-TemplateParameterFile "$fpath/AppGW/aksauto-appgw-deploy.parameters.json" `
-applicationGatewayName $appgwName `
-vnetName $vnetName -subnetName $appgwSubnetName

New-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/AppGW/aksauto-appgw-deploy.json" `
-TemplateParameterFile "$fpath/AppGW/aksauto-appgw-deploy.parameters.json" `
-applicationGatewayName $appgwName `
-vnetName $vnetName -subnetName $appgwSubnetName