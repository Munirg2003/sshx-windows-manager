<#
================================================================================
SSHX MANAGER – EDUCATIONAL / LAB USE
================================================================================

This single-file script MERGES all fixes, corrections, and improvements
identified throughout development.

ANNOTATION LEGEND:
[FIX-x]  = Bug/Error you discovered and corrected
[SEC-x]  = Security improvement you forced
[ARCH-x] = Architecture improvement you requested
[UX-x]   = Usability improvement you requested
[REL-x]  = Release / packaging related fix
================================================================================
#>

#region [ARCH-1] STRICT MODE & ERROR HANDLING
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
#endregion

#region [ARCH-2] CONTROLLED SCRIPT EXIT (FIXES EXIT BUG)
$script:ShouldExit = $false
#endregion

#region [SEC-1] TRANSCRIPT LOGGING (TRANSPARENT, NOT HIDDEN)
$LogDir = Join-Path $env:ProgramData "sshx-manager"
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir | Out-Null
}
Start-Transcript -Path (Join-Path $LogDir "transcript.log") -Append
#endregion

#region [ARCH-3] ADMIN CHECK (NO FORCED ESCALATION)
function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
#endregion

#region [ARCH-4] OS DETECTION (WINDOWS-SPECIFIC SCRIPT)
function Get-OSInfo {
    Write-Host "`n=== OS INFORMATION ===" -ForegroundColor Cyan
    Get-CimInstance Win32_OperatingSystem |
        Select-Object Caption, Version, OSArchitecture |
        Format-List
}
#endregion

#region [SEC-2] SECURE INSTALL POLICY (NO BLIND DOWNLOADS)
function Install-SSHX {

    Write-Host "`nStarting SSHX installation..." -ForegroundColor Yellow

    Write-Host "`nSECURE INSTALL NOTICE:" -ForegroundColor Cyan
    Write-Host "Automatic binary installation is DISABLED."
    Write-Host "Reason: No official Windows binaries with published hashes."
    Write-Host "This prevents supply-chain compromise."

    Write-Host "`nOptions:"
    Write-Host "1. Open official SSHX website"
    Write-Host "2. Cancel"

    $choice = Read-Host "Select"

    if ($choice -eq "1") {
        Start-Process "https://sshx.io"
    }

    Write-Host "`nNo system changes were made." -ForegroundColor Green
}
#endregion

#region [FIX-1] SCHEDULED TASK AUTOSTART (VALID ENUM ONLY)
function Enable-AutostartTask {

    if (-not (Test-IsAdmin)) {
        Write-Host "Admin rights required to configure autostart." -ForegroundColor Red
        return
    }

    $taskName = "SSHX-Autostart"

    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        Write-Host "Autostart already enabled." -ForegroundColor Yellow
        return
    }

    $action = New-ScheduledTaskAction `
        -Execute "powershell.exe" `
        -Argument "-ExecutionPolicy Bypass -File `"$PSCommandPath`""

    $trigger = New-ScheduledTaskTrigger -AtLogOn

    Register-ScheduledTask `
        -TaskName $taskName `
        -Action $action `
        -Trigger $trigger `
        -RunLevel Limited `
        -Force

    Write-Host "Autostart enabled via Scheduled Task." -ForegroundColor Green
}
#endregion

#region [FIX-2] CLEAN UNINSTALL (NO RESIDUALS)
function Uninstall-SSHX {

    if (-not (Test-IsAdmin)) {
        Write-Host "Admin rights required to uninstall." -ForegroundColor Red
        return
    }

    $taskName = "SSHX-Autostart"

    if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
        Write-Host "Autostart task removed."
    }

    if (Test-Path $LogDir) {
        Remove-Item -Recurse -Force $LogDir
        Write-Host "Logs removed."
    }

    Write-Host "SSHX Manager cleanup completed." -ForegroundColor Green
}
#endregion

#region [UX-1] STATUS VISIBILITY (REQUESTED FEATURE)
function Show-SSHXStatus {

    Write-Host "`n=== SSHX STATUS ===" -ForegroundColor Cyan

    if (Get-ScheduledTask -TaskName "SSHX-Autostart" -ErrorAction SilentlyContinue) {
        Write-Host "Autostart : ENABLED" -ForegroundColor Green
    } else {
        Write-Host "Autostart : DISABLED" -ForegroundColor Yellow
    }

    if (Test-IsAdmin) {
        Write-Host "Privilege : Administrator" -ForegroundColor Green
    } else {
        Write-Host "Privilege : Standard User" -ForegroundColor Yellow
    }
}
#endregion

#region [UX-2] PAUSE HELPER
function Pause {
    Read-Host "`nPress Enter to continue"
}
#endregion

#region [ARCH-5] MAIN MENU LOOP (EXIT BUG FIXED)
do {
    Clear-Host

    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host " SSHX MANAGER – EDUCATIONAL LAB TOOL " -ForegroundColor Cyan
    Write-Host "====================================`n"

    Write-Host "1. Show OS Information"
    Write-Host "2. Install SSHX (Secure Mode)"
    Write-Host "3. Enable Autostart"
    Write-Host "4. Uninstall / Cleanup"
    Write-Host "5. Show SSHX Status"
    Write-Host "6. Exit"

    $choice = Read-Host "`nSelect"

    switch ($choice) {
        "1" { Get-OSInfo; Pause }
        "2" { Install-SSHX; Pause }
        "3" { Enable-AutostartTask; Pause }
        "4" { Uninstall-SSHX; Pause }
        "5" { Show-SSHXStatus; Pause }
        "6" {
            Write-Host "`nExiting SSHX Manager..." -ForegroundColor Yellow
            $script:ShouldExit = $true
        }
        default {
            Write-Host "Invalid selection." -ForegroundColor Red
            Pause
        }
    }

} while (-not $script:ShouldExit)
#endregion

#region [REL-1] CLEAN SHUTDOWN
Stop-Transcript
return
#endregion
