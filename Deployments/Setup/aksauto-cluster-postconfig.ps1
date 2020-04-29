param([Parameter(Mandatory=$false)] [string] $resourceGroup,
        [Parameter(Mandatory=$false)] [string] $clusterName,
        [Parameter(Mandatory=$false)] [string] $acrName,        
        [Parameter(Mandatory=$false)] [string] $keyVaultName,
        [Parameter(Mandatory=$false)] [string] $appgwName,
        [Parameter(Mandatory=$false)] [string] $apimName,
        [Parameter(Mandatory=$false)] [string] $aksVNetName,
        [Parameter(Mandatory=$false)] [string] $appgwSubnetName, 
        [Parameter(Mandatory=$false)] [string] $dockerSecretName,
        [Parameter(Mandatory=$false)] [string] $ingControllerName,
        [Parameter(Mandatory=$false)] [string] $ingControllerNSName,
        [Parameter(Mandatory=$false)] [string] $ingControllerFileName,
        [Parameter(Mandatory=$false)] [string] $ingControllerIPAddress,
        [Parameter(Mandatory=$false)] [string] $appgwTemplateFileName,
        [Parameter(Mandatory=$false)] [string] $baseFolderPath)

$acrSPIdName = $acrName + "-sp-id"
$acrSPSecretName = $acrName + "-sp-secret"
$templatesFolderPath = $baseFolderPath + "/Templates"
$yamlFilePath = "$baseFolderPath/YAMLs"

$acrInfo = Get-AzContainerRegistry -ResourceGroupName $resourceGroup -Name $acrName
if (!$acrInfo)
{

    Write-Host "Error creating Service Principal"
    return;

}

Write-Host $acrInfo.Id

$acrUserName = Get-AzKeyVaultSecret -VaultName $keyVaultName `
-Name $acrSPIdName
if (!$acrUserName)
{

    Write-Host "Error fetching Service Principal Id"
    return;

}

$acrPassword = Get-AzKeyVaultSecret -VaultName $keyVaultName `
-Name $acrSPSecretName
if (!$acrPassword)
{

    Write-Host "Error fetching Service Principal Password"
    return;

}

$dockerServer = $acrInfo.LoginServer
$dockerUserName = $acrUserName.SecretValueText
$dockerPassword = $acrPassword.SecretValueText

# Switch Cluster context
$kbctlContextCommand = "az aks get-credentials --resource-group $resourceGroup --name $clusterName --overwrite-existing --admin"
Invoke-Expression -Command $kbctlContextCommand

# Create ACR secret
$dockerSecretCommand = "kubectl create secret docker-registry $dockerSecretName --docker-server=$dockerServer --docker-username=$dockerUserName --docker-password=$dockerPassword"
Invoke-Expression -Command $dockerSecretCommand

# Docker Login command
$dockerLoginCommand = "sudo docker login $dockerServer --username $dockerUserName --password $dockerPassword"
Invoke-Expression -Command $dockerLoginCommand

# Configure ILB file
$ipReplaceCommand = "sed -e 's|<ILB_IP>|$ingControllerIPAddress|' $yamlFilePath/Common/$ingControllerFileName.yaml > $yamlFilePath/Common/tmp.$ingControllerFileName.yaml"
Invoke-Expression -Command $ipReplaceCommand
# Remove temp ILB file
$removeTempFileCommand = "mv $yamlFilePath/Common/tmp.$ingControllerFileName.yaml $yamlFilePath/Common/$ingControllerFileName.yaml"
Invoke-Expression -Command $removeTempFileCommand

# Create namespace for nginx
$nginxNSCommand = "kubectl create namespace $ingControllerNSName"
Invoke-Expression -Command $nginxNSCommand

# Install nginx as ILB using Helm
$nginxILBCommand = "helm install $ingControllerName nginx-stable/nginx-ingress --namespace $ingControllerNSName -f $yamlFilePath/Common/$ingControllerFileName.yaml --set controller.replicaCount=2 --set nodeSelector.""beta.kubernetes.io/os""=linux"
Invoke-Expression -Command $nginxILBCommand

# Install AppGW
$networkNames = "-appgwName $appgwName -vnetName $aksVNetName -subnetName $appgwSubnetName"
$appgwDeployCommand = "/AppGW/$appgwTemplateFileName.ps1 -rg $resourceGroup -fpath $templatesFolderPath -deployFileName $appgwTemplateFileName $networkNames"
$appgwDeployPath = $templatesFolderPath + $appgwDeployCommand
Invoke-Expression -Command $appgwDeployPath

Write-Host "Post-Config Successfully Done!"
