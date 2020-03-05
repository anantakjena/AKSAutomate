$projectName = "aksworkshop"
$resourceGroup = "workshopsgroups"
$location = "eastus"
$cluster = "$projectName-cluster"
$version = "1.14.6"
$addons = "monitoring"
$nodeCount = 3
$nodeVMSize = "Standard_DS2_v2"
$keyVaultName = "$projectName-key-vault"
$spIdName = "$projectName-sp-id"
$spSecretName = "$projectName-sp-secret"
$maxPodCount = 100
$vnetName = "$projectName-vnet"
$subnetName = "$projectName-subnet"
$networkPolicy = "azure" # kubenet
$networkPlugin = "azure" # calico

$spAppId = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $spIdName
$spSecret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $spSecretName

$aksWorkshopVnet = Get-AzVirtualNetwork -ResourceGroupName $resourceGroup -Name $vnetName
$aksWorkshopSubnet = Get-AzVirtualNetworkSubnetConfig -Name $subnetName `
-VirtualNetwork $aksWorkshopVnet

az aks create --name $cluster --resource-group $resourceGroup --location $location --enable-rbac `
--kubernetes-version $version --enable-addons $addons --node-count $nodeCount `
--node-vm-size $nodeVMSize --service-principal $spAppId --client-secret $spSecret `
--max-pods $maxPodCount --network-policy $networkPolicy --network-plugin $networkPlugin `
--location $location --vnet-subnet-id $aksWorkshopSubnet.Id --generate-ssh-keys `


Write-Host "Cluster done"