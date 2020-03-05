$projectName = "aksworkshop"
$tokenName = "appgw"
$location = "eastus"
$resourceGroup = "workshopsgroups"
$vnetName = "$projectName-vnet"
$subnetName = "$projectName-$tokenName-subnet"
$subNetIP = "173.0.16.0/24"
$poolName = "$projectName-bkend-pool"
$bkendPoolIP = "173.0.0.70"
$secretsPath = "../Secrets"
$certName = "$projectName-cert"
$crtPath = "$secretsPath/$certName.crt"
$keyPath = "$secretsPath/$certName.key"
$secretName = "$projectName-tls-secret"
$subj = "/CN={0}/O={1}" -f "$projectName.ingress.eastus.com", "$projectName-org"
$httpSettingsName = "$projectName-http-settings"
$backendProtocol = "http"
$backendPort = 80
$bkendCKAffinity = "Disabled"
$frontendPortName = "$projectName-frontend-port"
$frontendPort = 80
$publicIPName = "$projectName-public-ip"
$publicIPAllocation = "Dynamic"

$socialpostVNet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroup
Write-Host $socialpostVNet.Id
$socialpostSubnet = Add-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $socialpostVNet -AddressPrefix $subNetIP
$socialpostSubnet = Get-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $socialpostVNet
Write-Host $socialpostSubnet.Id

$bkendPool = New-AzApplicationGatewayBackendAddressPool -Name $poolName -BackendIPAddresses $bkendPoolIP
$bkendPoolHttpSettings = New-AzApplicationGatewayBackendHttpSettings -Name $httpSettingsName -Port $backendPort -Protocol $backendProtocol -CookieBasedAffinity $bkendCKAffinity
$frendPortConfig = New-AzApplicationGatewayFrontendPort -Name $frontendPortName  -Port $frontendPort
$publicIP = New-AzPublicIpAddress -ResourceGroupName $resourceGroup -Name $publicIPName -Location $location -AllocationMethod $publicIPAllocation

openssl req -x509 -nodes -days 365 -newkey rsa:2048 -out $crtPath -keyout $keyPath -subj $subj
kubectl create secret tls $secretName --cert $crtPath --key $keyPath