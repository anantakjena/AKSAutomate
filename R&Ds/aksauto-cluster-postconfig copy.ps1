$resourceGroup = "aks-workshop-rg"
$clusterName = "aks-workshop-cluster"
$acrName = "akswkshpacr"
$helmReleaseName = "external-nginx"

$baseFolderPath = "/Users/monojitdattams/Development/Projects/Workshops/AKSAutomate"
$yamlFilePath = "$baseFolderPath/YAMLs"

$kbctlContextCommand = "az aks get-credentials --resource-group $resourceGroup --name $clusterName"

# $helmRBACCommand = "kubectl apply -f $yamlFilePath/helm-rbac.yml"

# $nginxILBCommand = "helm install $helmReleaseName stable/nginx-ingress --set rbac.create=true"

$nginxILBCommand = "helm install $helmReleaseName stable/nginx-ingress --namespace ingress-basic --name internal-ingress -f $yamlFilePath/internal-ingress.yaml --set controller.replicaCount=2 --set nodeSelector.""beta.kubernetes.io/os""=linux"

$acrDetails = Get-AzContainerRegistry -ResourceGroupName $resourceGroup -Name $acrName
$acrCredentials = Get-AzContainerRegistryCredential -ResourceGroupName $resourceGroup `
                    -Name $acrName

$dockerSecretName = "aksworkshop-secret"
$dockerServer = $acrDetails.LoginServer
$dockerUserName = $acrCredentials.Username
$dockerPassword = $acrCredentials.Password
                    
$dockerSecretCommand = "kubectl create secret docker-registry $dockerSecretName --docker-server=$dockerServer --docker-username=$dockerUserName --docker-password=$dockerPassword"

# Switch Cluster context
Invoke-Expression -Command $kbctlContextCommand

# Create ACR secret
Invoke-Expression -Command $dockerSecretCommand

# Add Cluster Rolebinding for helm/tiller
# Invoke-Expression -Command $helmRBACCommand

# Install nginx as ILB using Helm
Invoke-Expression -Command $nginxILBCommand

# # Install nginx Ingress
# Invoke-Expression -Command $nginxIngressCommand

Write-Host "Post config done"
