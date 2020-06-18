param([Parameter(Mandatory=$true)] [string] $rg,
        [Parameter(Mandatory=$true)] [string] $fpath,
        [Parameter(Mandatory=$true)] [string] $deployFileName,
        [Parameter(Mandatory=$true)] [string] $secVNetName,
        [Parameter(Mandatory=$true)] [string] $secVNetPrefix,
        [Parameter(Mandatory=$true)] [string] $acrSubnetName,
        [Parameter(Mandatory=$true)] [string] $acrSubNetPrefix,
        [Parameter(Mandatory=$true)] [string] $kvSubnetName,
        [Parameter(Mandatory=$true)] [string] $kvSubnetPrefix)

Test-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/Network/$deployFileName.json" `
-secVNetName $secVNetName -secVNetPrefix $secVNetPrefix `
-acrSubnetName $acrSubnetName -acrSubNetPrefix $acrSubNetPrefix `
-kvSubnetName $kvSubnetName -kvSubnetPrefix $kvSubnetPrefix

New-AzResourceGroupDeployment -ResourceGroupName $rg `
-TemplateFile "$fpath/Network/$deployFileName.json" `
-secVNetName $secVNetName -secVNetPrefix $secVNetPrefix `
-acrSubnetName $acrSubnetName -acrSubNetPrefix $acrSubNetPrefix `
-kvSubnetName $kvSubnetName -kvSubnetPrefix $kvSubnetPrefix