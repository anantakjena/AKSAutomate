param([Parameter(Mandatory=$false)] [string] $secretName,        
        [Parameter(Mandatory=$false)] [string] $namespaceName)

$deleteSecretCommand = "kubectl delete secrets/$secretName -n $namespaceName"
Invoke-Expression -Command $deleteSecretCommand