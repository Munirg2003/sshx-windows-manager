# File: manage.ps1
# Purpose: Windows-friendly Universal Entry Point for SSHX-Manager
# This script detects if it's on Windows or another OS (if running PWSH Core) and delegates.

if ($IsWindows -or $env:OS -match "Windows") {
    Write-Host "[INFO] Detected Platform: Windows" -ForegroundColor Cyan
    # Directly run the main windows script
    & "$PSScriptRoot\sshx-manager.ps1"
}
elseif ($IsLinux) {
    # Check for Termux
    if (Test-Path "/data/data/com.termux") {
        Write-Host "[INFO] Detected Platform: Android (Termux)" -ForegroundColor Cyan
        bash "$PSScriptRoot/android/sshx-manager-termux.sh"
    }
    else {
        Write-Host "[INFO] Detected Platform: Linux" -ForegroundColor Cyan
        sudo bash "$PSScriptRoot/linux/sshx-manager.sh"
    }
}
elseif ($IsMacOS) {
    Write-Host "[INFO] Detected Platform: macOS" -ForegroundColor Cyan
    sudo zsh "$PSScriptRoot/macos/sshx-manager.zsh"
}
else {
    Write-Error "Unsupported platform detected."
    exit 1
}
