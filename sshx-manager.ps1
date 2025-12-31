# ===============================
# File: sshx-manager.ps1
# ===============================

# ---- Logging ----
$LogRoot = "$env:ProgramData\sshx-lab"
New-Item -ItemType Directory -Force -Path $LogRoot | Out-Null
Start-Transcript -Path "$LogRoot\session.log" -Append

# ---- Admin Check ----
function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    Start-Process powershell `
      -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
      -Verb RunAs
    exit
}

# ---- Import Functions ----
$ModulePath = Join-Path -Path $PSScriptRoot -ChildPath "sshx-functions.psm1"

if (-not (Test-Path $ModulePath)) {
    Write-Error "Required module sshx-functions.psm1 not found at $ModulePath"
    exit 1
}

Import-Module $ModulePath -Force

# ---- Main Menu Loop ----
do {
    Clear-Host
    Write-Host "SSHX LAB MANAGER" -ForegroundColor Cyan
    Write-Host "1. Show OS Info"
    Write-Host "2. Install SSHX"
    Write-Host "3. Enable Autostart (Scheduled Task)"
    Write-Host "4. Uninstall SSHX"
    Write-Host "5. Exit"

    $choice = Read-Host "Select"

    switch ($choice) {
        "1" { Get-OSInfo; Pause }
        "2" { Install-SSHX; Pause }
        "3" { Enable-AutostartTask; Pause }
        "4" { Uninstall-SSHX; Pause }
        "5" { break }
    }
} while ($true)

Stop-Transcript
