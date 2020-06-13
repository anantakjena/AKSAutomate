param([Parameter(Mandatory=$false)] [string] $rg,
        [Parameter(Mandatory=$false)] [string] $fpath,
        [Parameter(Mandatory=$false)] [string] $deployFileName,
        [Parameter(Mandatory=$false)] [string] $aksVNetName,
        [Parameter(Mandatory=$false)] [string] $aksVNetPrefix,
        [Parameter(Mandatory=$false)] [string] $aksSubnetName,
        [Parameter(Mandatory=$false)] [string] $aksSubNetPrefix,
        [Parameter(Mandatory=$false)] [string] $appgwSubnetName,
        [Parameter(Mandatory=$false)] [string] $appgwSubnetPrefix,
        [Parameter(Mandatory=$false)] [string] $vrnSubnetName,
        [Parameter(Mandatory=$false)] [string] $vrnSubnetPrefix)

Test-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/Network/$deployFileName.json" `
-aksVNetName $aksVNetName -aksVNetPrefix $aksVNetPrefix `
-aksSubnetName $aksSubnetName -aksSubNetPrefix $aksSubNetPrefix `
-appgwSubnetName $appgwSubnetName -appgwSubnetPrefix $appgwSubnetPrefix `
-vrnSubnetName $vrnSubnetName -vrnSubnetPrefix $vrnSubnetPrefix

New-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/Network/$deployFileName.json" `
-aksVNetName $aksVNetName -aksVNetPrefix $aksVNetPrefix `
-aksSubnetName $aksSubnetName -aksSubNetPrefix $aksSubNetPrefix `
-appgwSubnetName $appgwSubnetName -appgwSubnetPrefix $appgwSubnetPrefix `
-vrnSubnetName $vrnSubnetName -vrnSubnetPrefix $vrnSubnetPrefix