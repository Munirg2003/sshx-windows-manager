# ===============================
# File: sshx-manager.ps1
# ===============================

# ---- Logging ----
$LogRoot = "$env:ProgramData\sshx-lab"
New-Item -ItemType Directory -Force -Path $LogRoot | Out-Null
Start-Transcript -Path "$LogRoot\session.log" -Append

# ---- Import Functions ----
Import-Module "$PSScriptRoot\sshx-functions.psm1"


if (-not (Test-Admin)) {
    Start-Process powershell `
      -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" `
      -Verb RunAs
    exit
}

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
        "5" {
	      Write-Host "Exiting SSHX Manager..." -ForegroundColor Yellow
	      Stop-Transcript
	      exit 0 
	    }
    }
} while ($true)

Stop-Transcript
