# Builds the release archive: dist\DestinyRising-ReShade-MuMu-v<version>.zip
# Contains only the installer, the preset and the docs; ReShade and the shaders are downloaded at install time.
param([string]$Version = '1.0.0')

$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot
$name = 'DestinyRising-ReShade-MuMu'
$dist = Join-Path $repo 'dist'
$stage = Join-Path $dist $name
$zip = Join-Path $dist "$name-v$Version.zip"

if (Test-Path $stage) { Remove-Item $stage -Recurse -Force }
New-Item -ItemType Directory -Force (Join-Path $stage 'data') | Out-Null
Copy-Item (Join-Path $repo 'installer\Install ReShade MuMu.bat') $stage
Copy-Item (Join-Path $repo 'installer\Installer.ps1') $stage
Copy-Item (Join-Path $repo 'installer\data\Vivid.ini') (Join-Path $stage 'data')
Copy-Item (Join-Path $repo 'README.md'), (Join-Path $repo 'LICENSE'), (Join-Path $repo 'THIRD_PARTY_NOTICES.md') $stage

if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path $stage -DestinationPath $zip -CompressionLevel Optimal
Remove-Item $stage -Recurse -Force
Write-Host "Built $zip ($([math]::Round((Get-Item $zip).Length / 1KB)) KB)"
Write-Host "SHA-256: $((Get-FileHash $zip -Algorithm SHA256).Hash)"
