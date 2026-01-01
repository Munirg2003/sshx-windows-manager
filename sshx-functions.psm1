# ===============================
# File: sshx-functions.psm1
# Purpose: Core logic module
# ===============================

# ---- Global Install Path ----
$Global:InstallDir = "$env:ProgramFiles\sshx"

# ---- Admin Privilege Check ----
function Test-Admin {
    $identity  = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator
    )
}

# ---- OS Information ----
function Get-OSInfo {
    Write-Host "`nOperating System Info:`n" -ForegroundColor Cyan
    Get-CimInstance Win32_OperatingSystem |
        Select-Object Caption, Version, OSArchitecture |
        Format-List
}

# ---- Hash Verification ----
function Verify-FileHash {
    param (
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [string]$ExpectedHash
    )

    Write-Host "Verifying file integrity..."

    $actualHash = (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash

    if ($actualHash -ne $ExpectedHash) {
        throw "SECURITY ERROR: Hash mismatch. Download aborted."
    }

    Write-Host "Hash verified successfully." -ForegroundColor Green
}

# ---- Install SSHX ----

function Install-SSHX {

    Write-Host "Starting SSHX installation..." -ForegroundColor Yellow

    Write-Host "`nSECURE INSTALL NOTICE:" -ForegroundColor Cyan
    Write-Host "Automatic binary installation is disabled."
    Write-Host "Reason: Official Windows binaries with published hashes are required."

    Write-Host "`nOptions:"
    Write-Host "1. Open SSHX website"
    Write-Host "2. Cancel"

    $choice = Read-Host "Select"

    if ($choice -eq "1") {
        Start-Process "https://sshx.io"
    }

    Write-Host "`nNo system changes were made." -ForegroundColor Green
}

# ---- Scheduled Task Autostart ----
function Enable-AutostartTask {

    Write-Host "Configuring Scheduled Task autostart..."

    $taskName = "SSHX-Autostart"

    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        Write-Host "Autostart task already exists." -ForegroundColor Yellow
        return
    }

    $action  = New-ScheduledTaskAction -Execute "powershell.exe" `
        -Argument "-ExecutionPolicy Bypass -File `"$PSScriptRoot\sshx-manager.ps1`""

    $trigger = New-ScheduledTaskTrigger -AtLogOn

    Register-ScheduledTask `
        -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -RunLevel Limited `
        -Force

    Write-Host "Autostart enabled via Scheduled Task." -ForegroundColor Green
}

# ---- Uninstall SSHX ----
function Uninstall-SSHX {

    Write-Host "Uninstalling SSHX..." -ForegroundColor Yellow

    if (Test-Path $InstallDir) {
        Remove-Item -Path $InstallDir -Recurse -Force
        Write-Host "SSHX removed." -ForegroundColor Green
    }
    else {
        Write-Host "SSHX is not installed." -ForegroundColor Cyan
    }
}
