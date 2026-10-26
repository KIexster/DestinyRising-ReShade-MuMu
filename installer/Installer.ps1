# ReShade 6.8.0 + "Vivid" / "Vivid Deep" preset installer for MuMuPlayer (made for Destiny Rising).
# https://github.com/KIexster/DestinyRising-ReShade-MuMu
#
# How ReShade works on MuMuPlayer 5.x (VM "MuMuVMMVbox"):
#   - The Android screen is rendered by MuMuVMMHeadless.exe (Hypervisor folder), not by the MuMu window.
#   - DirectX: ReShade is loaded as dxgi.dll next to MuMuVMMHeadless.exe.
#   - Vulkan:  MuMu disables every Vulkan layer (VK_LOADER_LAYERS_DISABLE=~implicit~) except those whose name contains
#              "renderdoc" (VK_LOADER_LAYERS_ALLOW=*renderdoc*), so the layer is registered as VK_LAYER_reshade_renderdoc.
#   - Both can't coexist: ReShade aborts if another copy is already loaded in the process.
#
# No third-party files are bundled. ReShade and the shaders are downloaded from their official sources, pinned to
# exact versions and verified with SHA-256.
#
# Usage: double-click "Install ReShade MuMu.bat". Headless (testing / automation):
#   Installer.ps1 -Mode DirectX|Vulkan|Uninstall [-Preset VividDeep|Vivid] [-DryRun] [-Launch]
#   Installer.ps1 -FetchOnly      (only download and verify the dependencies)
param(
    [ValidateSet('', 'DirectX', 'Vulkan', 'Uninstall')] [string]$Mode = '',
    [ValidateSet('VividDeep', 'Vivid')] [string]$Preset = 'VividDeep',
    [switch]$DryRun,
    [switch]$Launch,
    [switch]$FetchOnly
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName System.Windows.Forms, System.Drawing, System.IO.Compression

$Version    = '1.1.0'
$dataDir    = Join-Path $PSScriptRoot 'data'
$layerKey   = 'HKCU:\SOFTWARE\Khronos\Vulkan\ImplicitLayers'
$layerName  = 'VK_LAYER_reshade_renderdoc'
$appDir     = Join-Path $env:LOCALAPPDATA 'ReShade\MuMu'
$cacheDir   = Join-Path $appDir 'downloads'
$script:log = $null

# Presets shipped in data\ (both are installed; the selected one becomes active)
$Presets = [ordered]@{
    VividDeep = @{ File = 'VividDeep.ini'; Label = 'Vivid Deep (recommended)'; Info = 'Deeper blacks, anti-aliasing and smooth skies' }
    Vivid     = @{ File = 'Vivid.ini';     Label = 'Vivid (classic)';          Info = 'The original v1.0 look' }
}

# Pinned dependencies (same files the presets were tuned with)
$ReShadeSetup = @{ Name = 'ReShade_Setup_6.8.0.exe'; Url = 'https://reshade.me/downloads/ReShade_Setup_6.8.0.exe'; Sha256 = '207AEA16205FBF952BC8FE1879966672454CF04002E7AD34237C7990A5B3C0B4' }
$ReShadeDllSha256 = 'B2945C29E7095491A901746B400E58DB9B1592AB092BACF2A888CE37F02D08DA'
$Shaders = @(
    @{ Name = 'ReShade.fxh';        Dest = 'Shaders\ReShade.fxh';                Sha256 = '6DABFBBAF968C3871905D2EA17F96572FF7B1CEC01310B5D0E5252B66B30174F'
       Url  = 'https://raw.githubusercontent.com/crosire/reshade-shaders/fd0022170615ce0d8162d219bff07232fa6dd84f/Shaders/ReShade.fxh' }
    @{ Name = 'CAS.fx';             Dest = 'Shaders\SweetFX\CAS.fx';             Sha256 = '5CBF1468B75D0D221067BDC7BCA658F531816C3B24E0EEF8654D9D2A7D1A1C46'
       Url  = 'https://raw.githubusercontent.com/CeeJayDK/SweetFX/93ddf39b357f5da534ed6d34ba4ec8cc7dcfa361/Shaders/SweetFX/CAS.fx' }
    @{ Name = 'qUINT_lightroom.fx'; Dest = 'Shaders\qUINT\qUINT_lightroom.fx';   Sha256 = '99A0D6FFADCA4AB8AF74415580A1810DC9D28031DDAC942936137EA2C114C53C'
       Url  = 'https://raw.githubusercontent.com/martymcmodding/qUINT/98fed77b26669202027f575a6d8f590426c21ebd/Shaders/qUINT_lightroom.fx' }
    @{ Name = 'qUINT_common.fxh';   Dest = 'Shaders\qUINT\qUINT_common.fxh';     Sha256 = '30CF03A1869E33E9B92F09F79AC9217C001472D014AB91EF3E87E0D41E3F55EC'
       Url  = 'https://raw.githubusercontent.com/martymcmodding/qUINT/98fed77b26669202027f575a6d8f590426c21ebd/Shaders/qUINT_common.fxh' }
    @{ Name = 'Clarity.fx';         Dest = 'Shaders\AstrayFX\Clarity.fx';        Sha256 = '4A7903D5EE47C744DFC0124D25BA89D050C65F92F681CC90D5E2248DE7A11623'
       Url  = 'https://raw.githubusercontent.com/BlueSkyDefender/AstrayFX/59bae8b33e34f37a8e521e666864085ccbf08535/Shaders/Clarity.fx' }
    @{ Name = 'ReShadeUI.fxh';      Dest = 'Shaders\ReShadeUI.fxh';              Sha256 = '78ADF672DF47460297EB9FE6DD238D2AAFA24510B52B84FEB1A745DFF70EB901'
       Url  = 'https://raw.githubusercontent.com/crosire/reshade-shaders/fd0022170615ce0d8162d219bff07232fa6dd84f/Shaders/ReShadeUI.fxh' }
    @{ Name = 'Deband.fx';          Dest = 'Shaders\Deband.fx';                  Sha256 = '8959CA995090BC89762CC0BF4BA3BB1FFCFFDF143E9E0DDAF84F0E004B53DD29'
       Url  = 'https://raw.githubusercontent.com/crosire/reshade-shaders/fd0022170615ce0d8162d219bff07232fa6dd84f/Shaders/Deband.fx' }
    @{ Name = 'HQAALite.fx';        Dest = 'Shaders\HQAA\HQAALite.fx';           Sha256 = '9E9831E24B7572D257858A74D0EDD4EDAEF6C0E949321CEE8D803B9A2E065658'
       Url  = 'https://raw.githubusercontent.com/lordbean-git/HQAA/d12e74843399f5b85b4c28f8cd858022dfbcd165/HQAALite.fx' }
    @{ Name = 'AreaTex.png';        Dest = 'Textures\AreaTex.png';               Sha256 = '0044E6B420A8D98A9DC6A60BEDBD43F75CD15AC6052FDEDFB2F2F55D3077BEED'
       Url  = 'https://raw.githubusercontent.com/lordbean-git/HQAA/d12e74843399f5b85b4c28f8cd858022dfbcd165/AreaTex.png' }
    @{ Name = 'SearchTex.png';      Dest = 'Textures\SearchTex.png';             Sha256 = '55A97853AB64174245701ACCF315AB63D41776C9CB2AA14C675E653684FD96F3'
       Url  = 'https://raw.githubusercontent.com/lordbean-git/HQAA/d12e74843399f5b85b4c28f8cd858022dfbcd165/SearchTex.png' }
)

function Log([string]$msg) {
    if ($script:log) { $script:log.AppendText($msg + "`r`n"); [System.Windows.Forms.Application]::DoEvents() }
    else { Write-Host $msg }
}

# Runs a change, or only describes it in dry-run mode
function Step([string]$desc, [scriptblock]$action) {
    if ($DryRun) { Log "  [dry run] $desc" } else { Log "  $desc"; & $action }
}

# ---------- Dependencies ----------
function Get-VerifiedFile($dep) {
    $path = Join-Path $cacheDir $dep.Name
    if ((Test-Path $path) -and ((Get-FileHash $path -Algorithm SHA256).Hash -eq $dep.Sha256)) { return $path }
    New-Item -ItemType Directory -Force $cacheDir | Out-Null
    Log "  Downloading $($dep.Name)..."
    Invoke-WebRequest -Uri $dep.Url -OutFile $path -UseBasicParsing
    if ((Get-FileHash $path -Algorithm SHA256).Hash -ne $dep.Sha256) {
        Remove-Item $path -Force
        throw "Checksum mismatch for $($dep.Name). The download may be corrupted or the source changed."
    }
    return $path
}

# The official ReShade setup is a .NET app with a zip appended (followed by its signature); ReShade64.dll is inside
function Get-ReShadeDll {
    $dll = Join-Path $cacheDir 'ReShade64.dll'
    if ((Test-Path $dll) -and ((Get-FileHash $dll -Algorithm SHA256).Hash -eq $ReShadeDllSha256)) { return $dll }
    $setup = Get-VerifiedFile $ReShadeSetup
    Log '  Extracting ReShade64.dll from the official setup...'
    $b = [IO.File]::ReadAllBytes($setup)
    $eocd = -1
    for ($i = $b.Length - 22; $i -ge 0; $i--) {
        if ($b[$i] -eq 0x50 -and $b[$i + 1] -eq 0x4B -and $b[$i + 2] -eq 5 -and $b[$i + 3] -eq 6) { $eocd = $i; break }
    }
    if ($eocd -lt 0) { throw 'Could not find the archive inside the ReShade setup.' }
    $cdSize = [BitConverter]::ToUInt32($b, $eocd + 12)
    $cdOffset = [BitConverter]::ToUInt32($b, $eocd + 16)
    $comment = [BitConverter]::ToUInt16($b, $eocd + 20)
    $start = [int]($eocd - $cdSize - $cdOffset)
    $length = [int]($eocd + 22 + $comment - $start)
    $ms = New-Object IO.MemoryStream -ArgumentList $b, $start, $length
    $zip = New-Object IO.Compression.ZipArchive($ms, [IO.Compression.ZipArchiveMode]::Read)
    try {
        $entry = $zip.GetEntry('ReShade64.dll')
        if (-not $entry) { throw 'ReShade64.dll not found inside the ReShade setup.' }
        $in = $entry.Open(); $out = [IO.File]::Create($dll)
        try { $in.CopyTo($out) } finally { $out.Close(); $in.Close() }
    } finally { $zip.Dispose() }
    if ((Get-FileHash $dll -Algorithm SHA256).Hash -ne $ReShadeDllSha256) { Remove-Item $dll -Force; throw 'Checksum mismatch for ReShade64.dll.' }
    return $dll
}

function Get-Dependencies {
    Log 'Checking ReShade and shaders (downloaded once, then reused)...'
    $result = @{ Dll = Get-ReShadeDll; Shaders = @() }
    foreach ($s in $Shaders) { $result.Shaders += @{ Path = (Get-VerifiedFile $s); Dest = $s.Dest } }
    Log '  All files verified (SHA-256).'
    $result
}

# ---------- Detection ----------
function Find-MuMuRoot {
    $keys = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    $candidates = @()
    foreach ($e in (Get-ItemProperty $keys -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -match 'MuMu' })) {
        if ($e.InstallLocation) { $candidates += $e.InstallLocation }
        if ($e.UninstallString -match '^"?([^"]+?\.exe)') { $candidates += (Split-Path $Matches[1]) }
    }
    $p = Get-Process MuMuNxMain -ErrorAction SilentlyContinue | Where-Object Path | Select-Object -First 1
    if ($p) { $candidates += (Split-Path (Split-Path $p.Path)) }
    $candidates += 'C:\Program Files\Netease\MuMuPlayer', 'C:\Program Files\Netease\MuMuPlayerGlobal', 'D:\MuMuPlayer', 'C:\MuMuPlayer'
    foreach ($c in $candidates) { if ($c -and (Test-Path (Join-Path $c 'nx_main\MuMuManager.exe'))) { return $c } }
    return $null
}

function Find-Hypervisor {
    $p = Get-Process MuMuVMMHeadless, MuMuVMMSVC -ErrorAction SilentlyContinue | Where-Object Path | Select-Object -First 1
    if ($p) { return (Split-Path $p.Path) }
    foreach ($c in "$env:ProgramFiles\MuMuVMMVbox\Hypervisor", "${env:ProgramFiles(x86)}\MuMuVMMVbox\Hypervisor") {
        if (Test-Path (Join-Path $c 'MuMuVMMHeadless.exe')) { return $c }
    }
    return $null
}

function Test-ReShadeDll([string]$path) {
    (Test-Path $path) -and ((Get-Item $path).VersionInfo.ProductName -eq 'ReShade')
}

function Test-Writable([string]$dir) {
    try { $f = Join-Path $dir ('.reshade-test-' + [guid]::NewGuid()); [IO.File]::WriteAllText($f, ''); Remove-Item $f; $true } catch { $false }
}

function Get-VmIndexes([string]$root) {
    $idx = @(Get-ChildItem (Join-Path $root 'vms') -Directory -ErrorAction SilentlyContinue |
        ForEach-Object { if ($_.Name -match '-(\d+)$') { $Matches[1] } })
    if ($idx.Count -eq 0) { $idx = @('0') }
    $idx
}

# ---------- Changes ----------
function Stop-MuMu([string]$root) {
    if (-not (Get-Process MuMuVMMHeadless, MuMuNxDevice -ErrorAction SilentlyContinue)) { return $true }
    if ($DryRun) { Log '  [dry run] Close MuMu'; return $true }
    Log 'Closing MuMu (this can take up to 2 minutes)...'
    $mgr = Join-Path $root 'nx_main\MuMuManager.exe'
    foreach ($i in (Get-VmIndexes $root)) { & $mgr control -v $i shutdown | Out-Null }
    for ($t = 0; $t -lt 60; $t++) {
        if (-not (Get-Process MuMuVMMHeadless, MuMuNxDevice -ErrorAction SilentlyContinue)) { return $true }
        Start-Sleep -Seconds 2; [System.Windows.Forms.Application]::DoEvents()
    }
    return $false
}

function Set-RenderMode([string]$root, [string]$mode) {
    $from, $to = if ($mode -eq 'Vulkan') { 'render.mode.stable', 'render.mode.highperformance' } else { 'render.mode.highperformance', 'render.mode.stable' }
    $configs = @(Get-ChildItem (Join-Path $root 'vms') -Filter customer_config.json -Recurse -ErrorAction SilentlyContinue)
    $done = 0
    foreach ($c in $configs) {
        $text = [IO.File]::ReadAllText($c.FullName)
        if ($text -match [regex]::Escape("""choose"": ""$to""")) { $done++; continue }
        if ($text -match [regex]::Escape("""choose"": ""$from""")) {
            Step "Set MuMu render mode to $mode ($($c.Directory.Parent.Name))" {
                [IO.File]::WriteAllText($c.FullName, $text.Replace("""choose"": ""$from""", """choose"": ""$to"""), (New-Object Text.UTF8Encoding($false)))
            }
            $done++
        }
    }
    if ($done -eq 0) { Log "  WARNING: could not change the render mode. Set it manually in MuMu: Settings > Display > $mode." }
}

function Remove-ReShadeLayers {
    if (-not (Test-Path $layerKey)) { return }
    foreach ($name in @((Get-Item $layerKey).Property)) {
        $exists = Test-Path -LiteralPath $name
        $ours = if ($exists) { (Get-Content -LiteralPath $name -Raw) -match $layerName } else { $name -match 'ReShade64_MuMu' }
        if (-not $ours) { continue }
        Step "Unregister Vulkan layer: $name" { Remove-ItemProperty -Path $layerKey -Name $name }
        # Manifests from earlier manual installs, outside this installer's folder
        if ($exists -and -not $name.StartsWith($appDir, [StringComparison]::OrdinalIgnoreCase)) {
            Step "Delete old manifest: $name" { Remove-Item -LiteralPath $name -Force }
        }
    }
}

function Remove-ReShadeDxgi([string]$hyp) {
    foreach ($n in 'dxgi.dll', 'dxgi.dll.off') {
        $f = Join-Path $hyp $n
        if (Test-ReShadeDll $f) { Step "Remove $n (ReShade for DirectX)" { Remove-Item $f -Force } }
    }
}

function Install-Common([string]$hyp, $deps, [string]$presetKey) {
    Step 'Copy shaders (HQAA, Clarity, qUINT Lightroom, CAS, Deband)' {
        foreach ($s in $deps.Shaders) {
            $dest = Join-Path (Join-Path $hyp 'reshade-shaders') $s.Dest
            New-Item -ItemType Directory -Force (Split-Path $dest) | Out-Null
            Copy-Item $s.Path $dest -Force
        }
    }
    foreach ($p in $Presets.Values) {
        $target = Join-Path $hyp $p.File
        $source = Join-Path $dataDir $p.File
        if ((Test-Path $target) -and ((Get-FileHash $target).Hash -ne (Get-FileHash $source).Hash)) {
            Step "Back up the previous $($p.File) as $($p.File).bak" { Copy-Item $target "$target.bak" -Force }
        }
        Step "Copy the $($p.Label) preset" { Copy-Item $source $target -Force }
    }
    $active = $Presets[$presetKey]
    $ini = @(
        '[GENERAL]'
        'EffectSearchPaths=.\reshade-shaders\Shaders\**'
        "PresetPath=.\$($active.File)"
        'PreprocessorDefinitions=RESHADE_DEPTH_LINEARIZATION_FAR_PLANE=1000.0,RESHADE_DEPTH_INPUT_IS_UPSIDE_DOWN=0,RESHADE_DEPTH_INPUT_IS_REVERSED=0,RESHADE_DEPTH_INPUT_IS_LOGARITHMIC=0'
        'TextureSearchPaths=.\reshade-shaders\Textures\**'
        ''
        '[INPUT]'
        'GamepadNavigation=0'
        'KeyOverlay=36,0,0,0'
        ''
        '[OVERLAY]'
        'TutorialProgress=4'
        ''
        '[SCREENSHOT]'
        'SaveBeforeShot=1'
    ) -join "`r`n"
    Step "Write ReShade.ini (active preset: $($active.Label); Before/After screenshots with PrtSc)" {
        [IO.File]::WriteAllText((Join-Path $hyp 'ReShade.ini'), $ini + "`r`n", (New-Object Text.UTF8Encoding($true)))
    }
}

function Install-DirectX([string]$root, [string]$hyp, $deps, [string]$presetKey) {
    Log 'Installing ReShade for DirectX...'
    Install-Common $hyp $deps $presetKey
    Remove-ReShadeLayers
    $dxgi = Join-Path $hyp 'dxgi.dll'
    if ((Test-Path $dxgi) -and -not (Test-ReShadeDll $dxgi)) {
        Step 'Found a dxgi.dll that is not ReShade: renaming it to dxgi.dll.original' { Rename-Item $dxgi 'dxgi.dll.original' }
    }
    Step 'Install ReShade as dxgi.dll' { Copy-Item $deps.Dll $dxgi -Force }
    $off = Join-Path $hyp 'dxgi.dll.off'
    if (Test-ReShadeDll $off) { Step 'Remove dxgi.dll.off' { Remove-Item $off -Force } }
    Set-RenderMode $root 'DirectX'
}

function Install-Vulkan([string]$root, [string]$hyp, $deps, [string]$presetKey) {
    Log 'Installing ReShade for Vulkan...'
    Install-Common $hyp $deps $presetKey
    Remove-ReShadeDxgi $hyp
    Remove-ReShadeLayers
    $dll = Join-Path $appDir 'ReShade64.dll'
    $manifest = Join-Path $appDir 'ReShade64_MuMu_Vulkan.json'
    Step "Copy ReShade64.dll to $appDir" {
        New-Item -ItemType Directory -Force $appDir | Out-Null
        Copy-Item $deps.Dll $dll -Force
    }
    $json = @"
{
	"file_format_version": "1.0.0",
	"layer": {
		"name": "$layerName",
		"type": "GLOBAL",
		"library_path": "$($dll.Replace('\', '\\'))",
		"api_version": "1.3.268",
		"implementation_version": "1",
		"description": "ReShade for MuMuPlayer (the name contains 'renderdoc' to pass MuMu's VK_LOADER_LAYERS_ALLOW filter)",
		"device_extensions": [
			{
				"name": "VK_EXT_tooling_info",
				"spec_version": "1",
				"entrypoints": [ "vkGetPhysicalDeviceToolPropertiesEXT" ]
			}
		],
		"disable_environment": {
			"DISABLE_VK_LAYER_reshade_mumu_1": "1"
		}
	}
}
"@
    Step 'Create and register the Vulkan layer VK_LAYER_reshade_renderdoc (current user only)' {
        [IO.File]::WriteAllText($manifest, $json, (New-Object Text.UTF8Encoding($false)))
        if (-not (Test-Path $layerKey)) { New-Item -Path $layerKey -Force | Out-Null }
        New-ItemProperty -Path $layerKey -Name $manifest -Value 0 -PropertyType DWord -Force | Out-Null
    }
    Set-RenderMode $root 'Vulkan'
}

function Uninstall-ReShade([string]$hyp) {
    Log 'Uninstalling ReShade...'
    Remove-ReShadeDxgi $hyp
    Remove-ReShadeLayers
    foreach ($n in 'ReShade.ini', 'ReShade2.ini', 'ReShade.log', 'ReShade2.log', 'Vivid.ini', 'Vivid.ini.bak', 'VividDeep.ini', 'VividDeep.ini.bak', 'ReShadePreset.ini') {
        $f = Join-Path $hyp $n
        if (Test-Path $f) { Step "Remove $n" { Remove-Item $f -Force } }
    }
    $sh = Join-Path $hyp 'reshade-shaders'
    if (Test-Path $sh) { Step 'Remove the reshade-shaders folder' { Remove-Item $sh -Recurse -Force } }
    if (Test-Path $appDir) { Step "Remove $appDir" { Remove-Item $appDir -Recurse -Force } }
    Log '  Screenshots (.png) in the Hypervisor folder are kept.'
}

function Get-CurrentState([string]$hyp) {
    $vk = $false
    if (Test-Path $layerKey) {
        foreach ($name in (Get-Item $layerKey).Property) {
            if ((Test-Path -LiteralPath $name) -and ((Get-Content -LiteralPath $name -Raw) -match $layerName)) { $vk = $true }
        }
    }
    $dx = $hyp -and (Test-ReShadeDll (Join-Path $hyp 'dxgi.dll'))
    $presetName = ''
    $ini = if ($hyp) { Join-Path $hyp 'ReShade.ini' } else { $null }
    if ($ini -and (Test-Path $ini) -and ((Get-Content $ini -Raw) -match 'PresetPath=\.\\([^\r\n]+)')) {
        $file = $Matches[1]
        $match = @($Presets.Values | Where-Object { $_.File -eq $file })
        $presetName = ', preset: ' + $(if ($match) { $match[0].Label } else { $file })
    }
    if ($dx -and $vk) { 'DirectX and Vulkan at the same time (conflict: reinstall one of them)' }
    elseif ($dx) { "Installed for DirectX$presetName" }
    elseif ($vk) { "Installed for Vulkan$presetName" }
    else { 'Not installed' }
}

function Invoke-Action([string]$action, [string]$root, [string]$hyp, [bool]$open, [string]$presetKey) {
    if (-not $root -or -not (Test-Path (Join-Path $root 'nx_main\MuMuManager.exe'))) { Log 'ERROR: MuMuPlayer folder not found.'; return $false }
    if (-not $hyp -or -not (Test-Path (Join-Path $hyp 'MuMuVMMHeadless.exe'))) { Log 'ERROR: Hypervisor folder (MuMuVMMHeadless.exe) not found.'; return $false }
    try {
        # Download first, so MuMu is only closed once everything is ready
        $deps = if ($action -ne 'Uninstall') { Get-Dependencies } else { $null }
        if (-not (Stop-MuMu $root)) { Log 'ERROR: MuMu did not close. Close it manually and try again.'; return $false }
        switch ($action) {
            'DirectX'   { Install-DirectX $root $hyp $deps $presetKey | Out-Null }
            'Vulkan'    { Install-Vulkan $root $hyp $deps $presetKey | Out-Null }
            'Uninstall' { Uninstall-ReShade $hyp | Out-Null }
        }
    } catch { Log "ERROR: $($_.Exception.Message)"; return $false }
    Log ('Done.' + $(if ($DryRun) { ' (dry run: nothing was changed)' } else { '' }))
    if ($open -and $action -ne 'Uninstall' -and -not $DryRun) {
        & (Join-Path $root 'nx_main\MuMuManager.exe') control -v 0 launch | Out-Null
        Log 'Starting MuMu...'
    }
    return $true
}

$root = Find-MuMuRoot
$hyp  = Find-Hypervisor

if ($FetchOnly) {
    try { $d = Get-Dependencies; Log "ReShade64.dll: $($d.Dll)"; exit 0 } catch { Log "ERROR: $($_.Exception.Message)"; exit 1 }
}

# Headless mode (testing / automation)
if ($Mode) {
    Log "MuMu: $root"; Log "Hypervisor: $hyp"; Log "State: $(Get-CurrentState $hyp)"
    $ok = Invoke-Action $Mode $root $hyp $Launch.IsPresent $Preset
    exit $(if ($ok) { 0 } else { 1 })
}

# If the Hypervisor folder is not writable, reopen with administrator rights
if ($hyp -and -not (Test-Writable $hyp)) {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        $r = [System.Windows.Forms.MessageBox]::Show("The folder`n$hyp`nneeds administrator rights.`n`nRestart the installer as administrator?", 'ReShade for MuMu', 'YesNo', 'Question')
        if ($r -eq 'Yes') {
            Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File `"$PSCommandPath`""
        }
        exit
    }
}

# ---------- Window ----------
[System.Windows.Forms.Application]::EnableVisualStyles()
$form = New-Object System.Windows.Forms.Form
$form.Text = "ReShade for MuMuPlayer - Vivid presets v$Version" + $(if ($DryRun) { '  [DRY RUN]' } else { '' })
$form.ClientSize = New-Object System.Drawing.Size 620, 630
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'; $form.MaximizeBox = $false
$form.Font = New-Object System.Drawing.Font 'Segoe UI', 9.5
$form.BackColor = [System.Drawing.Color]::FromArgb(250, 250, 252)

function New-Label($text, $x, $y, $w, $h, $size = 9.5, $bold = $false, $color = $null) {
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $text; $l.Location = New-Object System.Drawing.Point $x, $y; $l.Size = New-Object System.Drawing.Size $w, $h
    $style = if ($bold) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }
    $l.Font = New-Object System.Drawing.Font 'Segoe UI', $size, $style
    if ($color) { $l.ForeColor = $color }
    $form.Controls.Add($l); $l
}

New-Label 'ReShade for MuMuPlayer' 20 14 580 30 15 $true | Out-Null
New-Label 'Installs ReShade 6.8.0 with the Vivid presets into the MuMu virtual machine. Pick a preset, then the render mode you want MuMu to use.' 20 48 580 40 9.5 $false ([System.Drawing.Color]::FromArgb(80, 80, 90)) | Out-Null

$grp = New-Object System.Windows.Forms.GroupBox
$grp.Text = 'Detected folders'; $grp.Location = New-Object System.Drawing.Point 20, 92; $grp.Size = New-Object System.Drawing.Size 580, 112
$form.Controls.Add($grp)
function New-PathRow($title, $value, $y, $isMuMu) {
    $t = New-Object System.Windows.Forms.Label; $t.Text = $title; $t.Location = New-Object System.Drawing.Point 12, $y; $t.Size = New-Object System.Drawing.Size 90, 22
    $v = New-Object System.Windows.Forms.Label; $v.Location = New-Object System.Drawing.Point 102, $y; $v.Size = New-Object System.Drawing.Size 370, 22
    $v.Text = if ($value) { $value } else { '(not found)' }; $v.AutoEllipsis = $true
    $b = New-Object System.Windows.Forms.Button; $b.Text = 'Change...'; $b.Location = New-Object System.Drawing.Point 480, ($y - 3); $b.Size = New-Object System.Drawing.Size 88, 26
    $b.Tag = @{ Label = $v; MuMu = $isMuMu }
    $b.Add_Click({
        $d = New-Object System.Windows.Forms.FolderBrowserDialog
        $d.Description = if ($this.Tag.MuMu) { 'MuMuPlayer folder (the one that contains nx_main)' } else { 'Hypervisor folder (the one that contains MuMuVMMHeadless.exe)' }
        if ($d.ShowDialog() -eq 'OK') {
            $this.Tag.Label.Text = $d.SelectedPath
            if ($this.Tag.MuMu) { $script:root = $d.SelectedPath } else { $script:hyp = $d.SelectedPath; $state.Text = 'Current state: ' + (Get-CurrentState $script:hyp) }
        }
    })
    $grp.Controls.AddRange(@($t, $v, $b))
}
New-PathRow 'MuMuPlayer:' $root 26 $true
New-PathRow 'Hypervisor:' $hyp 56 $false
$state = New-Object System.Windows.Forms.Label
$state.Location = New-Object System.Drawing.Point 12, 84; $state.Size = New-Object System.Drawing.Size 556, 22
$state.Font = New-Object System.Drawing.Font 'Segoe UI', 9.5, ([System.Drawing.FontStyle]::Bold)
$state.Text = 'Current state: ' + (Get-CurrentState $hyp)
$grp.Controls.Add($state)

$grpPreset = New-Object System.Windows.Forms.GroupBox
$grpPreset.Text = 'Preset'; $grpPreset.Location = New-Object System.Drawing.Point 20, 212; $grpPreset.Size = New-Object System.Drawing.Size 580, 70
$form.Controls.Add($grpPreset)
$presetRadios = [ordered]@{}
$y = 20
foreach ($key in $Presets.Keys) {
    $rb = New-Object System.Windows.Forms.RadioButton
    $rb.Text = "$($Presets[$key].Label)  -  $($Presets[$key].Info)"
    $rb.Location = New-Object System.Drawing.Point 14, $y; $rb.Size = New-Object System.Drawing.Size 552, 22
    $grpPreset.Controls.Add($rb); $presetRadios[$key] = $rb; $y += 24
}
# Preselect the preset that is currently installed, otherwise the default one
$installedPreset = $Preset
$iniPath = if ($hyp) { Join-Path $hyp 'ReShade.ini' } else { $null }
if ($iniPath -and (Test-Path $iniPath) -and ((Get-Content $iniPath -Raw) -match 'PresetPath=\.\\([^\r\n]+)')) {
    $file = $Matches[1]
    foreach ($key in $Presets.Keys) { if ($Presets[$key].File -eq $file) { $installedPreset = $key } }
}
$presetRadios[$installedPreset].Checked = $true

function New-ModeButton($title, $sub, $x, $color) {
    $b = New-Object System.Windows.Forms.Button
    $b.Location = New-Object System.Drawing.Point $x, 292; $b.Size = New-Object System.Drawing.Size 284, 74
    $b.Text = "$title`r`n$sub"; $b.FlatStyle = 'Flat'; $b.BackColor = $color; $b.ForeColor = [System.Drawing.Color]::White
    $b.Font = New-Object System.Drawing.Font 'Segoe UI', 11, ([System.Drawing.FontStyle]::Bold)
    $b.FlatAppearance.BorderSize = 0; $b.Cursor = [System.Windows.Forms.Cursors]::Hand
    $form.Controls.Add($b); $b
}
$btnDX = New-ModeButton 'Install for DirectX' '(MuMu "stable" mode)' 20 ([System.Drawing.Color]::FromArgb(37, 99, 235))
$btnVK = New-ModeButton 'Install for Vulkan' '(MuMu "high performance" mode)' 316 ([System.Drawing.Color]::FromArgb(124, 58, 237))

$chk = New-Object System.Windows.Forms.CheckBox
$chk.Text = 'Start MuMu when finished'; $chk.Checked = $true
$chk.Location = New-Object System.Drawing.Point 22, 376; $chk.Size = New-Object System.Drawing.Size 260, 24
$form.Controls.Add($chk)

$btnUn = New-Object System.Windows.Forms.Button
$btnUn.Text = 'Uninstall'; $btnUn.Location = New-Object System.Drawing.Point 490, 374; $btnUn.Size = New-Object System.Drawing.Size 110, 28
$form.Controls.Add($btnUn)

$script:log = New-Object System.Windows.Forms.TextBox
$script:log.Multiline = $true; $script:log.ReadOnly = $true; $script:log.ScrollBars = 'Vertical'
$script:log.Location = New-Object System.Drawing.Point 20, 412; $script:log.Size = New-Object System.Drawing.Size 580, 172
$script:log.Font = New-Object System.Drawing.Font 'Consolas', 9
$script:log.BackColor = [System.Drawing.Color]::White
$form.Controls.Add($script:log)

New-Label 'The ReShade menu (Home key) does not work in MuMu. PrtSc saves Before/After screenshots in the Hypervisor folder. To switch modes or presets, run this installer again.' 20 590 580 36 8.5 $false ([System.Drawing.Color]::FromArgb(110, 110, 120)) | Out-Null

function Invoke-FromWindow($action) {
    foreach ($b in $btnDX, $btnVK, $btnUn) { $b.Enabled = $false }
    $script:log.Clear()
    $selected = @($presetRadios.Keys | Where-Object { $presetRadios[$_].Checked })[0]
    $ok = Invoke-Action $action $script:root $script:hyp $chk.Checked $selected
    $state.Text = 'Current state: ' + (Get-CurrentState $script:hyp)
    foreach ($b in $btnDX, $btnVK, $btnUn) { $b.Enabled = $true }
    if ($ok -and -not $DryRun) { [System.Windows.Forms.MessageBox]::Show("Done: $action.", 'ReShade for MuMu', 'OK', 'Information') | Out-Null }
}
$btnDX.Add_Click({ Invoke-FromWindow 'DirectX' })
$btnVK.Add_Click({ Invoke-FromWindow 'Vulkan' })
$btnUn.Add_Click({
    $r = [System.Windows.Forms.MessageBox]::Show('Remove ReShade, the preset and the shaders from MuMu?', 'Uninstall', 'YesNo', 'Warning')
    if ($r -eq 'Yes') { Invoke-FromWindow 'Uninstall' }
})

Log "MuMu: $(if ($root) { $root } else { 'not found' })"
Log "Hypervisor: $(if ($hyp) { $hyp } else { 'not found' })"
if (-not $root -or -not $hyp) { Log 'Use "Change..." to point to the missing folder.' }
Log 'An internet connection is needed the first time (ReShade and shaders are downloaded from their official sources).'
[void]$form.ShowDialog()
