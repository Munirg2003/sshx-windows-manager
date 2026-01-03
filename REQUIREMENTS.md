# SSHX-Manager PowerShell Script — System Requirements

## Minimum System Requirements

### Operating System
- **Windows 10** (Version 1809 or later) or **Windows 11**
- **Windows Server 2019** or later (for server deployments)
- 64-bit architecture (32-bit fallback supported for installation path)

### PowerShell
- **PowerShell 5.0** (built-in Windows 10/11) or later
- **PowerShell 7.x** (cross-platform version) also compatible
- Execution Policy: Must allow script execution (see [Execution Policy Setup](#execution-policy-setup) below)

### User Privileges
- **Administrator privileges required** — must run as Administrator for:
  - Installing SSHX to Program Files
  - Creating/managing scheduled tasks
  - Managing Windows Defender exclusions
  - Modifying antivirus settings
  - Unblocking files (removing Zone.Identifier)

### Network & Connectivity
- **HTTPS internet connectivity** required to:
  - Download the SSHX binary from GitHub releases
  - Verify checksums and signatures (if enabled)
- **Firewall rules**: Outbound HTTPS (port 443) must be allowed
- **No proxy restrictions** on raw.githubusercontent.com and GitHub release URLs (or proxy must be configured)

### Disk Space
- **Minimum 100 MB** free space in:
  - C:\Program Files\ (or custom install directory)
  - C:\ProgramData\SSHX-Manager\ (for logs and state files)
  - Temporary directory for downloads and extraction

### Antivirus & Security Software
- **No blocking of PowerShell execution** (if AV is enabled, whitelist powershell.exe)
- **Windows Defender** (if enabled) — script will request consent to:
  - Temporarily disable real-time monitoring during installation
  - Add file/folder exclusions (reversible)
  - Restore settings after installation
- **Third-party antivirus** (ESET, Kaspersky, Avira, etc.) — may block operations; coordinate with security team

## Pre-Installation Checklist

### 1. Verify Administrator Access
```powershell
# Open PowerShell and run:
$admin = [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")
if ($admin) { Write-Host "[OK] Administrator" } else { Write-Host "[X] Not Administrator" }
```
If not administrator, right-click PowerShell → "Run as administrator"

### 2. Check PowerShell Version
```powershell
$PSVersionTable.PSVersion
```
Should return **5.0 or higher**. If lower, upgrade PowerShell.

### 3. Set PowerShell Execution Policy
The script requires an execution policy that allows script execution. Choose one:

**Option A: RemoteSigned (Recommended)**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```
Allows local scripts to run; remote scripts must be signed.

**Option B: Unrestricted (Less Secure)**
```powershell
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force
```
Allows all scripts (not recommended for production).

**Option C: One-Time Bypass**
```powershell
powershell -ExecutionPolicy Bypass -File "C:\path\to\sshx-manager.ps1"
```
Runs script once without changing policy.

### 4. Verify Internet Connectivity
```powershell
# Test connection to GitHub
Test-Connection -ComputerName raw.githubusercontent.com -Count 1
Test-Connection -ComputerName github.com -Count 1
```
Both should succeed (Reply count = 1).

### 5. Verify Disk Space
```powershell
# Check free space in Program Files
Get-Volume -DriveLetter C | Select-Object SizeRemaining

# Check free space in ProgramData
Get-Item 'C:\ProgramData' -ErrorAction SilentlyContinue
```
Ensure **at least 100 MB free space**.

### 6. Disable or Whitelist Antivirus (Optional)
If antivirus is blocking PowerShell or downloads:
- Add `powershell.exe` to antivirus whitelist
- Add installation directory to antivirus exclusions
- Temporarily disable real-time scanning (coordinator with security team for production)
- Script will prompt for consent before modifying Defender settings

### 7. Configure Firewall (if needed)
Ensure outbound HTTPS (port 443) is allowed:
```powershell
# Check Windows Firewall
Get-NetFirewallRule | Where-Object { $_.Enabled -eq $true } | Select-Object DisplayName, Direction, Action
```
If restrictive, allow HTTPS outbound traffic.

## Optional but Recommended

### 1. GPG/Signature Verification (For Security)
If the script is signed:
- Have GPG installed: https://www.gnupg.org/download/
- Obtain the public signing key from the repository
- Verify script signature before execution:
  ```powershell
  gpg --verify sshx-manager.ps1.sig sshx-manager.ps1
  ```

### 2. SHA256 Checksum Verification
The script supports optional SHA256 checksum verification:
- Obtain checksum from GitHub Release notes
- Script will prompt to verify before installation

### 3. Logging and Audit Trail
Ensure the script can write to:
- `C:\ProgramData\SSHX-Manager\` (logs and state)
- Local user AppData (optional cached downloads)

### 4. Scheduled Task Support
For auto-start features:
- Windows Task Scheduler must be enabled (default)
- Verify with: `tasklist | findstr /i "svchost"`

## Post-Installation Verification

### 1. Check Installation Success
```powershell
# Verify SSHX is installed
Get-ChildItem -Path "$env:ProgramFiles\*sshx*" -ErrorAction SilentlyContinue
```

### 2. Review Logs
```powershell
# Check manager logs
Get-ChildItem -Path "C:\ProgramData\SSHX-Manager\logs" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
```

### 3. Verify Process is Running (if auto-start enabled)
```powershell
Get-Process | Where-Object { $_.Name -match "sshx" }
```

### 4. Check Scheduled Task (if enabled)
```powershell
Get-ScheduledTask -TaskName "SSHX-AutoStart" -ErrorAction SilentlyContinue
```

## Troubleshooting Prerequisites

### Issue: "Execution Policy" Error
**Solution:** Set execution policy (see [Set PowerShell Execution Policy](#3-set-powershell-execution-policy))

### Issue: "Access Denied" / Not Administrator
**Solution:** Right-click PowerShell → "Run as administrator"

### Issue: "Network Error" / Cannot Download
**Solutions:**
- Verify internet connection: `Test-Connection github.com`
- Check firewall: Ensure HTTPS (port 443) is allowed
- Check proxy: If behind corporate proxy, configure proxy settings
- Try alternate URL: Check GitHub releases page manually

### Issue: Antivirus Blocks Script
**Solutions:**
- Whitelist `powershell.exe` in antivirus
- Temporarily disable real-time scanning
- Run with `-SkipAVCheck` flag (if available) to bypass AV prompts

### Issue: "Insufficient Disk Space"
**Solution:** Free up disk space (at least 100 MB) and retry

### Issue: Scheduled Task Creation Fails
**Solutions:**
- Verify administrator privileges
- Ensure Task Scheduler service is running: `Get-Service | Where-Object { $_.Name -eq "Schedule" }`
- Restart Task Scheduler: `Restart-Service -Name "Schedule"`

## Summary Checklist

Before running the script, confirm:

- [ ] Windows 10/11 or Windows Server 2019+
- [ ] PowerShell 5.0+ installed and working
- [ ] Running as Administrator
- [ ] PowerShell Execution Policy allows script execution
- [ ] Internet connectivity verified (HTTPS port 443 open)
- [ ] At least 100 MB free disk space
- [ ] Antivirus whitelisted PowerShell (or ready to consent during install)
- [ ] Firewall allows outbound HTTPS traffic
- [ ] (Optional) GPG installed for signature verification
- [ ] (Optional) Checksum obtained from GitHub Release

## Installation Command

Once all requirements are met, run the script:

**Local Execution:**
```powershell
cd C:\path\to\SSHX-manager-MultiOS-v2
.\sshx-manager.ps1
```

**Remote One-Line Install:**
```powershell
powershell -ExecutionPolicy Bypass -Command "iex (irm https://raw.githubusercontent.com/Munirg2003/SSHX-manager-MultiOS-v2/main/sshx-manager.ps1)"
```

**With Execution Policy Override:**
```powershell
powershell -ExecutionPolicy Bypass -File "C:\path\to\sshx-manager.ps1"
```

## Support & Questions

If requirements are not met, see [Troubleshooting Prerequisites](#troubleshooting-prerequisites) above, or open an issue in the GitHub repository with:
- Windows version (output of `[System.Environment]::OSVersion`)
- PowerShell version (output of `$PSVersionTable.PSVersion`)
- Error message (full output)
- Antivirus/firewall software running
