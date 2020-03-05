# CUSTOM VALUES - START - PLEASE CHANGE ACCORDINGLY

$customerName = "aksauto"
$projectName = "$customerName-workshop"
$location = "eastus"
$resourceGroup = "$projectName-rg"
$acrName = $customerName + "acr"
$acrSKU = "Standard"
$keyVaultName = "$projectName-kv"
$keyVaultDestination = "Software"
$spIdName = "$projectName-sp-id"
$spSecretName = "$projectName-sp-secret"
$vnetName = "$projectName-vnet"
$vnetIP = "173.0.0.0/16"
$subnetName = "$projectName-subnet"
$subNetIP = "173.0.0.0/22"
$apimSubnetName = "$projectName-apim-subnet"
$apimSubNetIP = "173.0.4.0/24"
$appgwSubnetName = "$projectName-appgw-subnet"
$appgwSubNetIP = "173.0.5.0/24"
$certPEMFile = "../Certs/aksauto.pem"
# $virtualNodeSubNetName = "$projectName-virtual-subnet"
# $virtualNodeSubNetIP = "173.0.4.0/20"

# CUSTOM VALUES - END - PLEASE CHANGE ACCORDINGLY

# DO NOT CHANGE  - START

$vnetRole = "Network Contributor"
$certKeyVaultKey = "sslCertKey"
$loginCommand = "az login --username $userName"

# DO NOT CHANGE  - END

# Execute following commands to initiate
# az extension add --name aks-preview
# az extension update --name aks-preview
# az feature register --name MultiAgentpoolPreview --namespace Microsoft.ContainerService
# az provider register --namespace Microsoft.ContainerService

# CLI Login
Invoke-Expression -Command $loginCommand

$servicePrinciple = New-AzADServicePrincipal -SkipAssignment
if (!$servicePrinciple)
{

    Write-Host "Error creating Service Principal"
    return;

}

$secretBSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($servicePrinciple.Secret)
$secret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($secretBSTR)
Write-Host $servicePrinciple.DisplayName
Write-Host $servicePrinciple.Id
Write-Host $servicePrinciple.ApplicationId
Write-Host $secret

$keyVault = Get-AzKeyVault -ResourceGroupName $resourceGroup -VaultName $keyVaultName
if (!$keyVault)
{

    $keyVault = New-AzKeyVault -ResourceGroupName $resourceGroup -Name $keyVaultName `
    -Location $location
    if (!$keyVault)
    {

        Write-Host "Error creating KeyVault"       
        $removeCommand = $removeScriptCommand + $servicePrinciple.Id
        Invoke-Expression -Command $removeCommand
        return;

    }
}

Add-AzKeyVaultKey -VaultName $keyVaultName -Name $spIdName -Destination $keyVaultDestination
$spObjectId = ConvertTo-SecureString -String $servicePrinciple.ApplicationId `
-AsPlainText -Force
Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $spIdName -SecretValue $spObjectId

Add-AzKeyVaultKey -VaultName $keyVaultName -Name $spSecretName -Destination $keyVaultDestination
Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $spSecretName `
-SecretValue $servicePrinciple.Secret

$aksACR = Get-AzContainerRegistry -ResourceGroupName $resourceGroup -Name $acrName
if (!$aksACR)
{

    $aksACR = New-AzContainerRegistry -ResourceGroupName $resourceGroup -Name $acrName `
    -Sku $acrSKU
    if (!$aksACR)
    {
        
        Write-Host "Error creating ACR"
        $removeCommand = $removeScriptCommand + $servicePrinciple.Id
        Invoke-Expression -Command $removeCommand
        return;

    }

} 

$aksAutoVnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroup
if ($aksAutoVnet)
{

    $aksAutoSubnet = Get-AzVirtualNetworkSubnetConfig -Name $subnetName `
    -VirtualNetwork $aksAutoVnet
    if (!$aksAutoSubnet)
    {
        
        $aksAutoSubnet = Add-AzVirtualNetworkSubnetConfig -Name $subnetName `
        -VirtualNetwork $aksAutoVnet -AddressPrefix $subNetIP
        Set-AzVirtualNetwork -VirtualNetwork $aksAutoVnet

    }
}
else
{
    $aksAutoSubnet = New-AzVirtualNetworkSubnetConfig -Name $apimSubnetName `
    -AddressPrefix $subNetIP
    $aksAutoVnet = New-AzVirtualNetwork -Name $vnetName -ResourceGroupName $resourceGroup `
    -Location $location -AddressPrefix $vnetIP -Subnet $aksAutoSubnet
    Write-Host $aksAutoVnet.Id

}

$aksAutoAPIMSubnet = Get-AzVirtualNetworkSubnetConfig -Name $apimSubnetName `
-VirtualNetwork $aksAutoVnet
if (!$aksAutoAPIMSubnet)
{
    
    $aksAutoAPIMSubnet = Add-AzVirtualNetworkSubnetConfig -Name $apimSubnetName `
    -VirtualNetwork $aksAutoVnet -AddressPrefix $apimSubNetIP
    Set-AzVirtualNetwork -VirtualNetwork $aksAutoVnet

}

$aksAppGWSubnet = Get-AzVirtualNetworkSubnetConfig -Name $appgwSubnetName `
-VirtualNetwork $aksAutoVnet
if (!$aksAppGWSubnet)
{
    
    $aksAppGWSubnet = Add-AzVirtualNetworkSubnetConfig -Name $appgwSubnetName `
    -VirtualNetwork $aksAutoVnet -AddressPrefix $appgwSubNetIP
    Set-AzVirtualNetwork -VirtualNetwork $aksAutoVnet

}

# $aksAutoVirtualNodeSubnet = Add-AzVirtualNetworkSubnetConfig -Name $virtualNodeSubNetName `
# -VirtualNetwork $aksAutoVnet -AddressPrefix $virtualNodeSubNetIP
# Write-Host $aksAutoVirtualNodeSubnet.Id
# Set-AzVirtualNetwork -VirtualNetwork $aksAutoVnet

New-AzRoleAssignment -ApplicationId $servicePrinciple.ApplicationId `
-Scope $aksAutoVnet.Id -RoleDefinitionName $vnetRole

$certCommand = "base64 $certPEMFile"
$certData = Invoke-Expression -Command $certCommand
$certDataSecure = ConvertTo-SecureString -String $certData -AsPlainText -Force

$keyVault = Get-AzKeyVault -ResourceGroupName $resourceGroup -VaultName $keyVaultName
if (!$keyVault)
{
    Write-Host "Error retrieving KeyVault"
    return;

}

Add-AzKeyVaultKey -VaultName $keyVaultName -Name $certKeyVaultKey `
-Destination $keyVaultDestination
Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $certKeyVaultKey `
-SecretValue $certDataSecure

Write-Host "Pre-Config done"




# $secretBSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($certDataSecure)
# $secret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($secretBSTR)
# Write-Host $secret

# Test-AzResourceGroupDeployment -ResourceGroupName "workshopsgroups" `
# -TemplateFile "../ARMs/KeyVault/aksauto-keyvault-deploy.json" `
# -TemplateParameterFile "../ARMs/KeyVault/aksauto-keyvault-deploy.parameters.json" `
# -secretName "TestSeret" `
# -secretValue $certDataSecure
