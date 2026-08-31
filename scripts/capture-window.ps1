[CmdletBinding()]
param(
    [int]$ProcessId,
    [string]$TitleLike,
    [Parameter(Mandatory)][string]$OutputPath,
    [int]$TimeoutSeconds = 20,
    [switch]$UsePrintWindow
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ($ProcessId -eq 0 -and [string]::IsNullOrWhiteSpace($TitleLike)) {
    throw 'Provide either ProcessId or TitleLike.'
}

Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;

public static class NativeWindowCapture {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }

    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);

    [DllImport("user32.dll")]
    public static extern bool IsWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool PrintWindow(IntPtr hWnd, IntPtr hdcBlt, uint nFlags);

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int command);

    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int x, int y, int cx, int cy, uint flags);

    [DllImport("user32.dll")]
    public static extern bool SetProcessDPIAware();
}
'@

[NativeWindowCapture]::SetProcessDPIAware() | Out-Null
$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$process = $null

while ((Get-Date) -lt $deadline) {
    if ($ProcessId -ne 0) {
        $process = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
    }
    else {
        $process = Get-Process | Where-Object {
            $_.MainWindowHandle -ne 0 -and $_.MainWindowTitle -like $TitleLike
        } | Select-Object -First 1
    }

    if ($null -ne $process -and $process.MainWindowHandle -ne 0 -and [NativeWindowCapture]::IsWindow($process.MainWindowHandle)) {
        break
    }
    Start-Sleep -Milliseconds 250
}

if ($null -eq $process -or $process.MainWindowHandle -eq 0) {
    $description = if ($ProcessId -ne 0) { "process $ProcessId" } else { "window title '$TitleLike'" }
    throw "Could not find a visible window for $description."
}

$handle = $process.MainWindowHandle
[NativeWindowCapture]::SetForegroundWindow($handle) | Out-Null
Start-Sleep -Milliseconds 400

$rect = New-Object NativeWindowCapture+RECT
if (-not [NativeWindowCapture]::GetWindowRect($handle, [ref]$rect)) {
    throw 'GetWindowRect failed.'
}

$width = $rect.Right - $rect.Left
$height = $rect.Bottom - $rect.Top
if ($width -lt 300 -or $height -lt 200 -or $rect.Left -lt -1000 -or $rect.Top -lt -1000) {
    [NativeWindowCapture]::ShowWindow($handle, 9) | Out-Null
    [NativeWindowCapture]::SetWindowPos($handle, [IntPtr]::Zero, 100, 100, 1000, 650, 0x0040) | Out-Null
    Start-Sleep -Milliseconds 500
    if (-not [NativeWindowCapture]::GetWindowRect($handle, [ref]$rect)) {
        throw 'GetWindowRect failed after restoring the target window.'
    }
    $width = $rect.Right - $rect.Left
    $height = $rect.Bottom - $rect.Top
}
if ($width -le 0 -or $height -le 0) {
    throw "The target window has an invalid size after restore: ${width}x${height}."
}

$parent = Split-Path -Parent $OutputPath
if (-not [string]::IsNullOrWhiteSpace($parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
}

$bitmap = New-Object -TypeName System.Drawing.Bitmap -ArgumentList $width, $height
$rendered = $false
if ($UsePrintWindow) {
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $deviceContext = $graphics.GetHdc()
    $rendered = [NativeWindowCapture]::PrintWindow($handle, $deviceContext, 2)
    $graphics.ReleaseHdc($deviceContext)
    $graphics.Dispose()
}
if (-not $rendered) {
    if (-not $UsePrintWindow) {
        [NativeWindowCapture]::SetWindowPos($handle, [IntPtr](-1), $rect.Left, $rect.Top, $width, $height, 0x0040) | Out-Null
        [NativeWindowCapture]::SetForegroundWindow($handle) | Out-Null
        Start-Sleep -Milliseconds 250
        [NativeWindowCapture]::GetWindowRect($handle, [ref]$rect) | Out-Null
    }
    $screenGraphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $screenGraphics.CopyFromScreen($rect.Left, $rect.Top, 0, 0, $bitmap.Size)
    $screenGraphics.Dispose()
}

$bitmap.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
$bitmap.Dispose()
Write-Output "Captured $($process.MainWindowTitle) to $OutputPath"
