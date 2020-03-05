param([Parameter(Mandatory=$true)] [string] $rg,
        [Parameter(Mandatory=$true)] [string] $fpath,
        [Parameter(Mandatory=$true)] [string] $applicationGatewayName,
        [Parameter(Mandatory=$true)] [string] $vnetName,
        [Parameter(Mandatory=$true)] [string] $subnetName)

Test-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/AppGW/aksauto-appgw-deploy.json" `
-TemplateParameterFile "$fpath/AppGW/aksauto-appgw-deploy.parameters.json" `
-applicationGatewayName $applicationGatewayName `
-vnetName $vnetName -subnetName $subnetName

New-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/AppGW/aksauto-appgw-deploy.json" `
-TemplateParameterFile "$fpath/AppGW/aksauto-appgw-deploy.parameters.json" `
-applicationGatewayName $applicationGatewayName `
-vnetName $vnetName -subnetName $subnetName