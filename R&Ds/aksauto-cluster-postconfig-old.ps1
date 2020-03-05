$customerName = "inmobi"
$projectName = "$customerName-workshop"
$location = "eastus"
$resourceGroup = "inmobi_workshop_rg"
$keyVaultName = "$projectName-kv"
$sslSecretName = "$projectName-ssl-secret"
$sslCertificateName = "$projectName-ssl-cert"
$vnetName = "$projectName-vnet"
$appgwSubnetName = "$projectName-appgw-subnet"
$appgwSubNetIP = "173.1.0.0/24"
$publicIPName = "appgw-public-ip"
$publicIPConfigName = "appgw-public-ip-config"
$publicIPSKU = "Standard"
$publicIPDNSSuffix = "cloudapp.azure.com"
$publicIPDNSLabel = $customername + "front.$location.$publicIPDNSSuffix"
$frontendIPConfigName = "appgw-frontend-ip-config"
$frontendPortName = "appgw-frontend-port"
$backendPoolName = "appgw-backend-pool"
$httpListenerName = "appgw-https-listener"
$bkendHttpSettingsName = "aappgw-http-settings"
$appgwSkuName = "appgw-sku"
$appgwTier = "Standard_v2"
$appgwCapacity = 2
$nodeCount = 2
$maxPods = 50
$totalSubnetIP = ($nodeCount * ($maxPods + 1)) + 3
$nginxILBIP = "173.0.0." + $totalSubnetIP

Set-Location -Path ".."
$helmRBACFilePath = "$PWD/YAMLs"
Set-Location -Path "./Scripts"
$kbctlContextCommand = "az aks get-credentials --resource-group $resourceGroup --name $projectName"
$helmRBACCommand = "kubectl apply -f $helmRBACFilePath/helm-rbac.yml"
$nginxILBCommand = "helm install stable/nginx-ingress --namespace ingress-basic --name internal-ingress -f internal-ingress.yaml --set controller.replicaCount=2 --set nodeSelector.""beta.kubernetes.io/os""=linux"

# Switch Cluster context
Invoke-Expression -Command $kbctlContextCommand

# Add Cluster Rolebinding for helm/tiller
Invoke-Expression -Command $helmRBACCommand

# Install nginx as ILB using Helm
Invoke-Expression -Command $nginxILBCommand

$keyVault = Get-AzKeyVault -ResourceGroupName $resourceGroup -VaultName $keyVaultName
if (!$keyVault)
{

    Write-Host "Error fetching KeyVault"
    return;

}

$sslSecret = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $sslSecretName
if (!$sslSecret)
{

    Write-Host "Error fetching SSL Certificate Id"
    return;

}

$aksWorkshopVnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroup
if (!$aksWorkshopVnet)
{

    Write-Host "Error fetching Vnet"
    return;

}

$aksWorkshopAppGWSubnet = Get-AzVirtualNetworkSubnetConfig -Name $appgwSubnetName `
-VirtualNetwork $aksWorkshopVnet
if (!$aksWorkshopAppGWSubnet)
{
    
    $aksWorkshopAppGWSubnet = Add-AzVirtualNetworkSubnetConfig -Name $appgwSubnetName `
    -VirtualNetwork $aksWorkshopVnet -AddressPrefix $appgwSubNetIP
    Set-AzVirtualNetwork -VirtualNetwork $aksWorkshopVnet

}

$appgwPublicIP = New-AzPublicIpAddress -ResourceGroupName $resourceGroup -Name $publicIPName `
-AllocationMethod Static -Sku $publicIPSKU -DomainNameLabel $publicIPDNSLabel

$appgwPublicIPConfig = New-AzApplicationGatewayIPConfiguration -Name $publicIPConfigName `
-Subnet $aksWorkshopAppGWSubnet

$frontendIpConfig = New-AzApplicationGatewayFrontendIPConfig -Name $frontendIPConfigName `
-PublicIPAddress $appgwPublicIP

$appgwBackendPool = New-AzApplicationGatewayBackendAddressPool -Name $backendPoolName `
-BackendIPAddresses $nginxILBIP

$frontendPort = New-AzApplicationGatewayFrontendPort -Name $frontendPortName -Port 443

# Create self-service TLS certificate
# openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
#     -out <cert_name>.crt \
#     -keyout <cert_key>.key \
#     -subj "/CN=<host_name>/O=<organization_name>"
# Save the Certificate in Azure KeyVault

$sslCertificate = New-AzApplicationGatewaySslCertificate -Name $sslCertificateName `
-KeyVaultSecretId $sslSecret.Id

$httpListener = New-AzApplicationGatewayHttpListener -Name $httpListenerName `
-Protocol Https -FrontendIPConfiguration $frontendIpConfig `
-FrontendPort $frontendPort -SslCertificate $sslCertificate

$httpSettings = New-AzApplicationGatewayBackendHttpSetting -Name $bkendHttpSettingsName `
-Port 80 -Protocol Http -RequestTimeout 20 -CookieBasedAffinity Disabled

New-AzApplicationGatewayRequestRoutingRule -Name "" -RuleType Basic `
-BackendHttpSettings $httpSettings -HttpListener $httpListener `
-BackendAddressPool $appgwBackendPool

$appgwSKU = New-AzApplicationGatewaySku -Name $appgwSkuName -Tier $appgwTier `
-Capacity $appgwCapacity

Write-Host "Post config done"
