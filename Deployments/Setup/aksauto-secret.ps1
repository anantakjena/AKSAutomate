param([Parameter(Mandatory=$false)] [string] $dockerSecretName,
        [Parameter(Mandatory=$false)] [string] $dockerServer,
        [Parameter(Mandatory=$false)] [string] $dockerUsername,
        [Parameter(Mandatory=$false)] [string] $dockerPassword,
        [Parameter(Mandatory=$false)] [string] $mongoSecretName,
        [Parameter(Mandatory=$false)] [string] $mongohost,
        [Parameter(Mandatory=$false)] [string] $mongouser,
        [Parameter(Mandatory=$false)] [string] $mongopassword,
        [Parameter(Mandatory=$false)] [string] $namespaceName)

$dockerSecretCommand = "kubectl create secret docker-registry $dockerSecretName --docker-server=$dockerServer --docker-username=$dockerUsername --docker-password=$dockerPassword -n $namespaceName"
Invoke-Expression -Command $dockerSecretCommand

$mongoSecretCommand = "kubectl create secret generic $mongoSecretName --from-literal=mongohost=$mongohost --from-literal=mongouser=$mongouser --from-literal=mongopassword=$mongopassword -n $namespaceName"
Invoke-Expression -Command $mongoSecretCommand