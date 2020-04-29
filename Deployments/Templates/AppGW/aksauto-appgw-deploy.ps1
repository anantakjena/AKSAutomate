param([Parameter(Mandatory=$true)] [string] $rg,
        [Parameter(Mandatory=$true)] [string] $fpath,
        [Parameter(Mandatory=$true)] [string] $deployFileName,
        [Parameter(Mandatory=$true)] [string] $appgwName,
        [Parameter(Mandatory=$true)] [string] $vnetName,
        [Parameter(Mandatory=$true)] [string] $subnetName)

Test-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/AppGW/$deployFileName.json" `
-TemplateParameterFile "$fpath/AppGW/$deployFileName.parameters.json" `
-applicationGatewayName $appgwName `
-vnetName $vnetName -subnetName $subnetName

New-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/AppGW/$deployFileName.json" `
-TemplateParameterFile "$fpath/AppGW/$deployFileName.parameters.json" `
-applicationGatewayName $appgwName `
-vnetName $vnetName -subnetName $subnetName