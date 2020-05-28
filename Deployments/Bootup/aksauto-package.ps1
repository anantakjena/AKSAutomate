param([Parameter(Mandatory=$false)] [string] $packageFilePath)

$packageInfo = Get-Content $packageFilePath | ConvertFrom-Json
$packageVersion = $packageInfo.version
Write-Host $packageVersion

Write-Host "##vso[task.setvariable variable=pkgVersion;]$packageVersion"