[CmdletBinding()]
param(
    [Parameter(Mandatory)][int]$ProcessId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

$deadline = (Get-Date).AddSeconds(20)
$process = $null
while ((Get-Date) -lt $deadline) {
    $process = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
    if ($null -ne $process -and $process.MainWindowHandle -ne 0) {
        break
    }
    Start-Sleep -Milliseconds 250
}

if ($null -eq $process -or $process.MainWindowHandle -eq 0) {
    throw 'The XAMPP Control Panel did not expose a window handle.'
}

$root = [System.Windows.Automation.AutomationElement]::FromHandle($process.MainWindowHandle)
$buttonCondition = New-Object System.Windows.Automation.PropertyCondition(
    [System.Windows.Automation.AutomationElement]::ControlTypeProperty,
    [System.Windows.Automation.ControlType]::Button
)
$buttons = $root.FindAll([System.Windows.Automation.TreeScope]::Descendants, $buttonCondition)
$startButtons = @()
$stopButtons = @()
foreach ($button in $buttons) {
    if ($button.Current.Name -eq 'Start') {
        $startButtons += $button
    }
    elseif ($button.Current.Name -eq 'Stop') {
        $stopButtons += $button
    }
}

if ($stopButtons.Count -ge 2) {
    Write-Output 'Apache and MySQL already appear to be running in the Control Panel.'
    exit 0
}

if ($startButtons.Count -lt 2) {
    throw "Could not find two XAMPP Start buttons. Found $($startButtons.Count) Start and $($stopButtons.Count) Stop buttons."
}

foreach ($button in @($startButtons[0], $startButtons[1])) {
    $invokePattern = $button.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
    $invokePattern.Invoke()
    Start-Sleep -Milliseconds 750
}

Write-Output 'Requested Apache and MySQL from the XAMPP Control Panel.'
