[CmdletBinding()]
param(
    [string]$XamppRoot,
    [switch]$KeepServices
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$setupScript = Join-Path $repoRoot 'scripts\setup-xampp.ps1'
$panelStartScript = Join-Path $repoRoot 'scripts\start-xampp-from-control-panel.ps1'
$firewallScript = Join-Path $repoRoot 'scripts\allow-private-firewall.ps1'
$evidenceRoot = Join-Path $repoRoot 'output\playwright\windows-lab-1'
$statePath = Join-Path $repoRoot '.runtime\xampp-root.txt'
$controlPanel = $null
$selectedRoot = $null

function Test-HttpReady {
    param([Parameter(Mandatory)][string]$Url)

    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 3
        return ($response.StatusCode -eq 200 -and $response.Content -match 'Welcome to XAMPP for Windows')
    }
    catch [System.Net.WebException] {
        return $false
    }
}

function Test-TcpReady {
    param([Parameter(Mandatory)][int]$Port)

    try {
        return [bool](Test-NetConnection -ComputerName '127.0.0.1' -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue)
    }
    catch [System.Net.NetworkInformation.NetworkInformationException] {
        return $false
    }
}

function Get-ListeningProcessIds {
    param([Parameter(Mandatory)][int]$Port)

    return @(
        Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty OwningProcess -Unique
    )
}

function Test-XamppOwnsPort {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][int]$Port
    )

    foreach ($ownerId in (Get-ListeningProcessIds -Port $Port)) {
        $service = Get-CimInstance Win32_Service -Filter "ProcessId = $ownerId" -ErrorAction SilentlyContinue
        if ($null -ne $service -and $service.PathName -like "$Root*") {
            return $true
        }

        $process = Get-CimInstance Win32_Process -Filter "ProcessId = $ownerId" -ErrorAction SilentlyContinue
        if ($null -ne $process -and (
                $process.ExecutablePath -like "$Root*" -or
                $process.CommandLine -like "*$Root*"
            )) {
            return $true
        }
    }
    return $false
}

function Resolve-MySqlPort {
    param([Parameter(Mandatory)][string]$Root)

    if (@(Get-ListeningProcessIds -Port 3306).Count -eq 0 -or (Test-XamppOwnsPort -Root $Root -Port 3306)) {
        return 3306
    }

    foreach ($port in 3307..3315) {
        if (@(Get-ListeningProcessIds -Port $port).Count -eq 0) {
            Write-Warning "Port 3306 is already in use by another process; using XAMPP MySQL port $port."
            return $port
        }
    }
    throw 'No free MySQL port was found in the range 3306-3315.'
}

function Configure-MySqlPort {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][int]$Port
    )

    $mysqlIni = Join-Path $Root 'mysql\bin\my.ini'
    $controlIni = Join-Path $Root 'xampp-control.ini'
    if (-not (Test-Path -LiteralPath $mysqlIni)) {
        throw "XAMPP MySQL configuration was not found at $mysqlIni"
    }
    if (-not (Test-Path -LiteralPath $controlIni)) {
        throw "XAMPP Control Panel configuration was not found at $controlIni"
    }

    $mysqlContent = Get-Content -LiteralPath $mysqlIni -Raw
    $mysqlPattern = '(?im)^(\s*port\s*=\s*)\d+\s*$'
    if (-not [regex]::IsMatch($mysqlContent, $mysqlPattern)) {
        throw "No MySQL port setting was found in $mysqlIni"
    }
    $mysqlUpdated = $mysqlContent -replace $mysqlPattern, ('${1}' + $Port)
    Set-Content -LiteralPath $mysqlIni -Value $mysqlUpdated -Encoding ascii

    $controlContent = Get-Content -LiteralPath $controlIni -Raw
    $controlPattern = '(?im)^(\s*MySQL\s*=\s*)\d+\s*$'
    if (-not [regex]::IsMatch($controlContent, $controlPattern)) {
        throw "No MySQL service port setting was found in $controlIni"
    }
    $controlUpdated = $controlContent -replace $controlPattern, ('${1}' + $Port)
    Set-Content -LiteralPath $controlIni -Value $controlUpdated -Encoding ascii
}

function Start-DirectServices {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][int]$MySqlPort
    )

    $apacheBat = Join-Path $Root 'apache_start.bat'
    $mysqlBat = Join-Path $Root 'mysql_start.bat'

    if (-not (Test-HttpReady -Url 'http://localhost/dashboard/')) {
        Start-Process -FilePath $env:ComSpec -ArgumentList @('/d', '/c', ('"' + $apacheBat + '"')) -WorkingDirectory $Root -WindowStyle Hidden | Out-Null
    }
    if (-not (Test-TcpReady -Port $MySqlPort)) {
        Start-Process -FilePath $env:ComSpec -ArgumentList @('/d', '/c', ('"' + $mysqlBat + '"')) -WorkingDirectory $Root -WindowStyle Hidden | Out-Null
    }
}

function Wait-ForServices {
    param(
        [Parameter(Mandatory)][int]$TimeoutSeconds,
        [Parameter(Mandatory)][int]$MySqlPort
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        $apacheReady = Test-HttpReady -Url 'http://localhost/dashboard/'
        $mysqlReady = Test-TcpReady -Port $MySqlPort
        if ($apacheReady -and $mysqlReady) {
            return
        }
        Start-Sleep -Seconds 1
    }
    throw 'Apache and MySQL did not both become ready before the timeout.'
}

function Stop-LocalXampp {
    param([Parameter(Mandatory)][string]$Root)

    $stopExe = Join-Path $Root 'xampp_stop.exe'
    if (Test-Path -LiteralPath $stopExe) {
        Start-Process -FilePath $stopExe -WorkingDirectory $Root -WindowStyle Hidden | Out-Null
        Start-Sleep -Seconds 2
        return
    }

    $httpd = Get-Process -Name 'httpd' -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "$Root*" }
    foreach ($process in $httpd) {
        Stop-Process -Id $process.Id -Force
    }
    $mysqld = Get-Process -Name 'mysqld' -ErrorAction SilentlyContinue | Where-Object { $_.Path -like "$Root*" }
    foreach ($process in $mysqld) {
        Stop-Process -Id $process.Id -Force
    }
}

try {
    if ($PSBoundParameters.ContainsKey('XamppRoot')) {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $setupScript -XamppRoot $XamppRoot
    }
    else {
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $setupScript
    }
    if ($LASTEXITCODE -ne 0) {
        throw "XAMPP setup exited with code $LASTEXITCODE."
    }

    if (-not (Test-Path -LiteralPath $statePath)) {
        throw "XAMPP setup did not write its state file: $statePath"
    }
    $selectedRoot = (Get-Content -LiteralPath $statePath -Raw).Trim()
    if ([string]::IsNullOrWhiteSpace($selectedRoot)) {
        throw 'The selected XAMPP root was empty.'
    }

    $mysqlPort = Resolve-MySqlPort -Root $selectedRoot
    Configure-MySqlPort -Root $selectedRoot -Port $mysqlPort
    Write-Output "XAMPP_MYSQL_PORT=$mysqlPort"

    $controlPanelPath = Join-Path $selectedRoot 'xampp-control.exe'
    if (-not (Test-Path -LiteralPath $controlPanelPath)) {
        throw "The XAMPP Control Panel was not found at $controlPanelPath"
    }

    $controlPanel = Start-Process -FilePath $controlPanelPath -WorkingDirectory $selectedRoot -PassThru
    Start-Sleep -Seconds 2
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $panelStartScript -ProcessId $controlPanel.Id
    $panelExitCode = $LASTEXITCODE
    if ($panelExitCode -ne 0) {
        Write-Warning "Control Panel UI automation returned code $panelExitCode; using the direct process fallback."
    }

    try {
        Wait-ForServices -TimeoutSeconds 20 -MySqlPort $mysqlPort
    }
    catch {
        Write-Warning 'The Control Panel did not bring both services online; trying the XAMPP binaries directly.'
        Start-DirectServices -Root $selectedRoot -MySqlPort $mysqlPort
        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $firewallScript -TimeoutSeconds 20
        if ($LASTEXITCODE -ne 0) {
            throw "Private-network firewall handling exited with code $LASTEXITCODE."
        }
        Wait-ForServices -TimeoutSeconds 45 -MySqlPort $mysqlPort
    }

    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot 'node_modules\playwright'))) {
        Write-Output 'Installing the pinned Playwright dependency...'
        & npm.cmd install --no-audit --no-fund
        if ($LASTEXITCODE -ne 0) {
            throw "npm install exited with code $LASTEXITCODE."
        }
    }

    $browserPath = Join-Path $repoRoot 'node_modules\playwright\cli.js'
    if (-not (Test-Path -LiteralPath $browserPath)) {
        throw 'The Playwright package is not available after npm install.'
    }
    & npx.cmd --no-install playwright install chromium
    if ($LASTEXITCODE -ne 0) {
        throw "Playwright Chromium installation exited with code $LASTEXITCODE."
    }

    $env:XAMPP_ROOT = $selectedRoot
    $env:XAMPP_MYSQL_PORT = [string]$mysqlPort
    $env:EVIDENCE_DIR = $evidenceRoot
    $env:CONTROL_PANEL_PROCESS_ID = [string]$controlPanel.Id
    & node.exe (Join-Path $repoRoot 'scripts\capture-evidence.mjs')
    if ($LASTEXITCODE -ne 0) {
        throw "Browser evidence capture exited with code $LASTEXITCODE."
    }

    & node.exe (Join-Path $repoRoot 'scripts\validate-evidence.mjs')
    if ($LASTEXITCODE -ne 0) {
        throw "Evidence validation exited with code $LASTEXITCODE."
    }

    Write-Output "Evidence is ready at $evidenceRoot"
}
finally {
    Remove-Item Env:XAMPP_ROOT -ErrorAction SilentlyContinue
    Remove-Item Env:EVIDENCE_DIR -ErrorAction SilentlyContinue
    Remove-Item Env:CONTROL_PANEL_PROCESS_ID -ErrorAction SilentlyContinue
    if ($null -ne $controlPanel) {
        $panelProcess = Get-Process -Id $controlPanel.Id -ErrorAction SilentlyContinue
        if ($null -ne $panelProcess) {
            Stop-Process -Id $controlPanel.Id -Force
        }
    }
    if (-not $KeepServices -and $null -ne $selectedRoot -and (Test-Path -LiteralPath $selectedRoot)) {
        Stop-LocalXampp -Root $selectedRoot
    }
}
