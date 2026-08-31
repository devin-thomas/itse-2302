[CmdletBinding()]
param(
    [string]$XamppRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$version = '8.2.12'
$archiveName = "xampp-windows-x64-$version-0-VS16.zip"
$downloadUri = "https://downloads.sourceforge.net/project/xampp/XAMPP%20Windows/$version/$archiveName"
$runtimeRoot = Join-Path $repoRoot '.runtime'
$downloadRoot = Join-Path $runtimeRoot 'downloads'
$archivePath = Join-Path $downloadRoot $archiveName
$statePath = Join-Path $runtimeRoot 'xampp-root.txt'
$evidenceRoot = Join-Path $repoRoot 'output\playwright\windows-lab-1'

function Test-XamppInstall {
    param([Parameter(Mandatory)][string]$Root)

    return (
        (Test-Path -LiteralPath (Join-Path $Root 'xampp-control.exe')) -and
        (Test-Path -LiteralPath (Join-Path $Root 'apache\bin\httpd.exe')) -and
        (Test-Path -LiteralPath (Join-Path $Root 'php\php.exe'))
    )
}

function Ensure-ControlPanelConfig {
    param([Parameter(Mandatory)][string]$Root)

    $iniPath = Join-Path $Root 'xampp-control.ini'
    $templatePath = Join-Path $Root 'src\xampp-nsi-installer\scripts\xampp-control.ini'

    if (-not (Test-Path -LiteralPath $iniPath)) {
        if (Test-Path -LiteralPath $templatePath) {
            Copy-Item -LiteralPath $templatePath -Destination $iniPath -Force
        }
        else {
            Set-Content -LiteralPath $iniPath -Value '[LogSettings]' -Encoding ascii
        }
    }

    $content = Get-Content -LiteralPath $iniPath -Raw
    if ($content -notmatch '(?im)^\[Common\]\s*$') {
        $content = @"
[Common]
Editor=notepad.exe
Browser=
Debug=0
Debuglevel=0
Language=en
TomcatVisible=1
Minimized=0

$content
"@
    }
    elseif ($content -match '(?im)^Language\s*=\s*$') {
        $content = $content -replace '(?im)^Language\s*=\s*$', 'Language=en'
    }
    elseif ($content -notmatch '(?im)^Language\s*=') {
        $content = [regex]::Replace($content, '(?im)^\[Common\]\s*$', "[Common]`r`nLanguage=en", 1)
    }

    $content = $content -replace '(?im)^Left\s*=\s*-1\s*$', 'Left=100'
    $content = $content -replace '(?im)^Top\s*=\s*-1\s*$', 'Top=100'
    Set-Content -LiteralPath $iniPath -Value $content -Encoding ascii
}

function Test-ZipArchive {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return $false
    }
    $file = Get-Item -LiteralPath $Path
    if ($file.Length -lt 10MB) {
        return $false
    }

    $stream = [IO.File]::OpenRead($Path)
    try {
        $signature = New-Object byte[] 4
        $read = $stream.Read($signature, 0, 4)
        return ($read -eq 4 -and $signature[0] -eq 0x50 -and $signature[1] -eq 0x4B)
    }
    finally {
        $stream.Dispose()
    }
}

function Select-XamppRoot {
    param(
        [string]$RequestedRoot,
        [Parameter(Mandatory)][bool]$WasExplicit
    )

    if ($WasExplicit) {
        if ([string]::IsNullOrWhiteSpace($RequestedRoot)) {
            throw 'The explicit XAMPP root cannot be empty.'
        }
        return [IO.Path]::GetFullPath($RequestedRoot)
    }

    $preferredRoot = 'C:\xampp'
    if (Test-XamppInstall -Root $preferredRoot) {
        return $preferredRoot
    }

    if (Test-Path -LiteralPath $preferredRoot) {
        Write-Warning "C:\xampp exists but is not a complete XAMPP installation; using the repository runtime instead."
        return (Join-Path $runtimeRoot 'xampp')
    }

    $createdRoot = $false
    $probePath = Join-Path $preferredRoot '.codex-write-probe'
    try {
        New-Item -ItemType Directory -Path $preferredRoot -Force | Out-Null
        $createdRoot = $true
        [IO.File]::WriteAllText($probePath, 'write check')
        Remove-Item -LiteralPath $probePath -Force
        return $preferredRoot
    }
    catch [UnauthorizedAccessException] {
        if ($createdRoot -and (Test-Path -LiteralPath $probePath)) {
            Remove-Item -LiteralPath $probePath -Force -ErrorAction SilentlyContinue
        }
        Write-Warning "The current account cannot write to C:\xampp; using a repository-local XAMPP runtime instead."
        return (Join-Path $runtimeRoot 'xampp')
    }
}

$explicitRoot = $PSBoundParameters.ContainsKey('XamppRoot')
$selectedRoot = Select-XamppRoot -RequestedRoot $XamppRoot -WasExplicit:$explicitRoot
$archiveHash = $null

if (-not (Test-XamppInstall -Root $selectedRoot)) {
    New-Item -ItemType Directory -Path $downloadRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $runtimeRoot -Force | Out-Null

    if (-not (Test-ZipArchive -Path $archivePath)) {
        if (Test-Path -LiteralPath $archivePath) {
            Write-Warning 'The cached XAMPP archive was not a valid ZIP; replacing only that generated cache file.'
            Remove-Item -LiteralPath $archivePath -Force
        }
        Write-Output "Downloading XAMPP $version from the official Apache Friends download link..."
        $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
        if ($null -ne $curl) {
            & $curl.Source --location --fail --silent --show-error --retry 2 --retry-all-errors --output $archivePath $downloadUri
            if ($LASTEXITCODE -ne 0) {
                throw "curl exited with code $LASTEXITCODE while downloading XAMPP."
            }
        }
        else {
            Invoke-WebRequest -Uri $downloadUri -OutFile $archivePath -UseBasicParsing
        }
    }

    if (-not (Test-ZipArchive -Path $archivePath)) {
        throw "The downloaded XAMPP archive is not a valid ZIP: $archivePath"
    }

    $archiveHash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
    $extractRoot = Join-Path $runtimeRoot "extract-$version"
    $sourceRoot = Join-Path $extractRoot 'xampp'

    if (-not (Test-XamppInstall -Root $sourceRoot)) {
        Write-Output "Extracting XAMPP $version..."
        New-Item -ItemType Directory -Path $extractRoot -Force | Out-Null
        Expand-Archive -LiteralPath $archivePath -DestinationPath $extractRoot -Force
    }

    if (-not (Test-XamppInstall -Root $sourceRoot)) {
        throw 'The XAMPP archive did not contain the expected Apache, PHP, and Control Panel files.'
    }

    if (Test-Path -LiteralPath $selectedRoot) {
        $existingItems = @(Get-ChildItem -LiteralPath $selectedRoot -Force)
        if ($existingItems.Count -gt 0 -and $selectedRoot -notlike "$runtimeRoot*") {
            throw "Refusing to populate the non-empty explicit XAMPP root $selectedRoot."
        }
    }
    New-Item -ItemType Directory -Path $selectedRoot -Force | Out-Null
    Copy-Item -Path (Join-Path $sourceRoot '*') -Destination $selectedRoot -Recurse -Force
}

if (-not (Test-XamppInstall -Root $selectedRoot)) {
    throw "XAMPP is not complete at $selectedRoot after setup."
}

$setupBatch = Join-Path $selectedRoot 'setup_xampp.bat'
if (Test-Path -LiteralPath $setupBatch) {
    Push-Location $selectedRoot
    try {
        & cmd.exe /d /c ('"' + $setupBatch + '"')
        if ($LASTEXITCODE -ne 0) {
            throw "setup_xampp.bat exited with code $LASTEXITCODE."
        }
    }
    finally {
        Pop-Location
    }
}

Ensure-ControlPanelConfig -Root $selectedRoot

$projectRoot = Join-Path $selectedRoot 'htdocs\project'
New-Item -ItemType Directory -Path $projectRoot -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $repoRoot 'lab-1\index.php') -Destination (Join-Path $projectRoot 'index.php') -Force
Copy-Item -LiteralPath (Join-Path $repoRoot 'lab-1\status.php') -Destination (Join-Path $projectRoot 'status.php') -Force

New-Item -ItemType Directory -Path $runtimeRoot -Force | Out-Null
Set-Content -LiteralPath $statePath -Value $selectedRoot -Encoding utf8
New-Item -ItemType Directory -Path $evidenceRoot -Force | Out-Null
$installRecord = [ordered]@{
    version = $version
    archive = $archiveName
    source = $downloadUri
    sha256 = $archiveHash
    xamppRoot = $selectedRoot
    projectRoot = $projectRoot
    preparedAt = (Get-Date).ToUniversalTime().ToString('o')
}
$installRecord | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $evidenceRoot 'xampp-install.json') -Encoding utf8

Write-Output "XAMPP_ROOT=$selectedRoot"
Write-Output "PROJECT_ROOT=$projectRoot"
