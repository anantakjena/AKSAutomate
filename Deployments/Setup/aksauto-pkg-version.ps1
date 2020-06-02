param([Parameter(Mandatory=$false)] [string] $inVersionToken,
        [Parameter(Mandatory=$false)] [string] $outVersionToken,
        [Parameter(Mandatory=$false)] [string] $packageFilePath)

$settingsInfo = Get-Content -Path $packageFilePath -Raw | ConvertFrom-Json
$versionInfo = $settingsInfo.$inVersionToken
Write-Host $settingsInfo
Write-Host $versionInfo
Write-Host "##vso[task.setvariable variable=$outVersionToken]$versionInfo"