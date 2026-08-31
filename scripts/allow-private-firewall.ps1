[CmdletBinding()]
param(
    [int]$TimeoutSeconds = 20
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type @'
using System;
using System.Runtime.InteropServices;

public static class FirewallPromptNative {
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int command);

    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int x, int y);

    [DllImport("user32.dll")]
    public static extern void mouse_event(uint flags, uint dx, uint dy, uint data, UIntPtr extraInfo);

    [DllImport("user32.dll")]
    public static extern uint GetDpiForSystem();
}
'@

function Find-FirewallPrompt {
    return Get-Process -Name PickerHost -ErrorAction SilentlyContinue |
        Where-Object { $_.MainWindowHandle -ne 0 -and $_.MainWindowTitle -eq 'Windows Security' } |
        Select-Object -First 1
}

function Click-ScreenPoint {
    param(
        [Parameter(Mandatory)][int]$X,
        [Parameter(Mandatory)][int]$Y
    )

    [FirewallPromptNative]::SetCursorPos($X, $Y) | Out-Null
    Start-Sleep -Milliseconds 100
    [FirewallPromptNative]::mouse_event(0x0002, 0, 0, 0, [UIntPtr]::Zero)
    [FirewallPromptNative]::mouse_event(0x0004, 0, 0, 0, [UIntPtr]::Zero)
}

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$handledPrompt = $false
$lastHandledAt = $null
while ((Get-Date) -lt $deadline) {
    $prompt = Find-FirewallPrompt
    if ($null -eq $prompt) {
        if ($handledPrompt -and ((Get-Date) - $lastHandledAt).TotalSeconds -ge 3) {
            Write-Output 'Windows Firewall prompts handled with Private networks enabled and Public networks disabled.'
            exit 0
        }
        Start-Sleep -Milliseconds 250
        continue
    }

    $handle = $prompt.MainWindowHandle
    [FirewallPromptNative]::ShowWindow($handle, 9) | Out-Null
    [FirewallPromptNative]::SetForegroundWindow($handle) | Out-Null
    Start-Sleep -Milliseconds 600

    # The secure XAML host reports virtualized bounds, so use calibrated
    # offsets from the centered Windows Security prompt.
    $screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $centerX = $screen.Left + [int][math]::Round($screen.Width / 2.0)
    $centerY = $screen.Top + [int][math]::Round($screen.Height / 2.0)
    $systemDpi = [FirewallPromptNative]::GetDpiForSystem()
    $scale = if ($systemDpi -gt 0) { $systemDpi / 96.0 } else { 1.0 }

    # Windows Security initially collapses the network choices behind Show more.
    Click-ScreenPoint -X ($centerX - [int][math]::Round(150 * $scale)) -Y ($centerY + [int][math]::Round(38 * $scale))
    Start-Sleep -Milliseconds 500

    # Keep Private networks enabled and explicitly clear Public networks.
    Click-ScreenPoint -X ($centerX - [int][math]::Round(180 * $scale)) -Y ($centerY + [int][math]::Round(34 * $scale))
    Start-Sleep -Milliseconds 250

    # Allow access after the public-network checkbox is cleared.
    Click-ScreenPoint -X ($centerX - [int][math]::Round(100 * $scale)) -Y ($centerY + [int][math]::Round(220 * $scale))
    Start-Sleep -Milliseconds 800

    if ($null -ne (Find-FirewallPrompt | Where-Object { $_.Id -eq $prompt.Id })) {
        throw 'The Windows Firewall prompt remained open after the private-network action sequence.'
    }
    $handledPrompt = $true
    $lastHandledAt = Get-Date
}

if ($handledPrompt) {
    throw 'A Windows Firewall prompt remained open after the private-network action sequence.'
}
Write-Output 'No Windows Firewall prompt detected.'
