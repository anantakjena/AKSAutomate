param([Parameter(Mandatory=$false)] [string] $resourceGroup = "aks-workshop-rg",
        [Parameter(Mandatory=$false)] [string] $clusterName = "aks-workshop-cluster",
        [Parameter(Mandatory=$false)] [string] $acrSPIdName = "acr-sp-id",
        [Parameter(Mandatory=$false)] [string] $acrSPSecretName = "acr-sp-secret",
        [Parameter(Mandatory=$false)] [string] $acrName = "akswkshpacr",
        [Parameter(Mandatory=$false)] [string] $applicationGatewayName = "aks-workshop-appgw",
        [Parameter(Mandatory=$false)] [string] $aksVNetName = "aks-workshop-vnet",
        [Parameter(Mandatory=$false)] [string] $keyVaultName = "aks-workshop-kv",
        [Parameter(Mandatory=$false)] [string] $certPwdName = "aks-appgw-password",
        [Parameter(Mandatory=$false)] [string] $appgwSubnetName = "appgw-workshop-subnet",
        [Parameter(Mandatory=$false)] [string] $dockerSecretName = "aksworkshop-secret",
        [Parameter(Mandatory=$false)] [string] $helmReleaseName = "internal-nginx",
        [Parameter(Mandatory=$false)] [string] $ingressNSName = "internal-nginx-ns",
        [Parameter(Mandatory=$false)] [string] $baseFolderPath = "/Users/monojitdattams/Development/Projects/Workshops/AKSAutomate/Deployments")

$templatesFolderPath = $baseFolderPath + "/Templates"
$yamlFilePath = "$baseFolderPath/YAMLs"

$networkNames = "-applicationGatewayName $applicationGatewayName -vnetName $aksVNetName -appgwSubnetName $appgwSubnetName"
$appgwDeployCommand = "/AppGW/aksauto-appgw-deploy.ps1 -rg $resourceGroup -fpath $templatesFolderPath $networkNames"

$kbctlContextCommand = "az aks get-credentials --resource-group $resourceGroup --name $clusterName --admin"

$nginxNSCommand = "kubectl create namespace $ingressNSName"
$nginxILBCommand = "helm install $helmReleaseName stable/nginx-ingress --namespace $ingressNSName -f $yamlFilePath/Common/internal-ingress.yaml --set controller.replicaCount=2 --set nodeSelector.""beta.kubernetes.io/os""=linux"

$acrInfo = Get-AzContainerRegistry -ResourceGroupName $resourceGroup -Name $acrName
if (!$acrInfo)
{

    Write-Host "Error creating Service Principal"
    return;

}

Write-Host $acrInfo.Id

$acrUserName = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $acrSPIdName
if (!$acrUserName)
{

    Write-Host "Error fetching Service Principal Id"
    return;

}

$acrPassword = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $acrSPSecretName
if (!$acrPassword)
{

    Write-Host "Error fetching Service Principal Password"
    return;

}

$dockerServer = $acrInfo.LoginServer
$dockerUserName = $acrUserName.SecretValueText
$dockerPassword = $acrPassword.SecretValueText
                    
$dockerSecretCommand = "kubectl create secret docker-registry $dockerSecretName --docker-server=$dockerServer --docker-username=$dockerUserName --docker-password=$dockerPassword"
$dockerLoginCommand = "docker login $dockerServer --username $dockerUserName --password $dockerPassword"

$securePassword = Read-Host "SSL Cert Password " -AsSecureString
Set-AzKeyVaultSecret -VaultName $keyVaultName -Name $certPwdName `
-SecretValue $securePassword

# Switch Cluster context
Invoke-Expression -Command $kbctlContextCommand

# Create ACR secret
Invoke-Expression -Command $dockerSecretCommand

# Create namespace for nginx
Invoke-Expression -Command $nginxNSCommand

# Install nginx as ILB using Helm
Invoke-Expression -Command $nginxILBCommand

# Docker Login command
Invoke-Expression -Command $dockerLoginCommand

# Install AppGW
$appgwDeployPath = $templatesFolderPath + $appgwDeployCommand
Invoke-Expression -Command $appgwDeployPath

Write-Host "Post config done"


