param(
    [string]$AutoHotkeyExe = "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe"
)

$ErrorActionPreference = "Stop"

$scriptPath = Join-Path $PSScriptRoot "CodexPathOpener.ahk"
if (-not (Test-Path -LiteralPath $scriptPath)) {
    throw "CodexPathOpener.ahk was not found next to this installer."
}

if (-not (Test-Path -LiteralPath $AutoHotkeyExe)) {
    throw "AutoHotkey v2 executable was not found at: $AutoHotkeyExe"
}

$startup = [Environment]::GetFolderPath("Startup")
$linkPath = Join-Path $startup "CodexPathOpener.lnk"

$wsh = New-Object -ComObject WScript.Shell
$shortcut = $wsh.CreateShortcut($linkPath)
$shortcut.TargetPath = $AutoHotkeyExe
$shortcut.Arguments = '"' + $scriptPath + '"'
$shortcut.WorkingDirectory = $PSScriptRoot
$shortcut.Description = "Open selected AI agent paths in VS Code"
$shortcut.Save()

Start-Process -FilePath $AutoHotkeyExe -ArgumentList @($scriptPath) -WindowStyle Hidden

Write-Host "Installed startup shortcut:"
Write-Host $linkPath
