param(
    [switch]$SkipInteractive = $false,
    [switch]$InstallPowerShell7 = $false,
    [switch]$InstallGPG = $false,
    [switch]$ConfigureFirewall = $false
)

# ============================================================================
# SELF-ELEVATION
# ============================================================================
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $argList = @("-NoProfile", "-ExecutionPolicy Bypass", "-NoExit", "-File", "`"$PSCommandPath`"")
    Start-Process powershell -ArgumentList $argList -Verb RunAs
    exit
}

# ============================================================================
# COLOR AND LOGGING FUNCTIONS
# ============================================================================

function Write-Header {
    param([string]$Message)
    Write-Host "`n" -NoNewline
    Write-Host "+-----------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "| $Message$((' ' * (58 - $Message.Length)))|" -ForegroundColor Cyan
    Write-Host "+-----------------------------------------------------------+" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "(!) $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[X] $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "(i) $Message" -ForegroundColor Cyan
}

# ============================================================================
# 1. EXECUTION POLICY SETUP
# ============================================================================

Write-Header "STEP 1: PowerShell Execution Policy"

try {
    $currentPolicy = Get-ExecutionPolicy -Scope Process
    Write-Info "Current Process execution policy: $currentPolicy"
    
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force -ErrorAction Stop
    Write-Success "Execution Policy set to Bypass (Process scope)"
}
catch {
    Write-Error "Failed to set execution policy: $_"
    exit 1
}

# ============================================================================
# 2. ADMINISTRATOR PRIVILEGES CHECK
# ============================================================================

Write-Header "STEP 2: Administrator Privileges Verification"
Write-Success "Running with elevated privileges."

# ============================================================================
# 3. WINDOWS VERSION CHECK
# ============================================================================

Write-Header "STEP 3: Windows Version Verification"

$osVersion = [System.Environment]::OSVersion.Version
$osName = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption

Write-Info "OS: $osName"
Write-Info "Version: $osVersion"

if ($osVersion.Major -lt 10) {
    Write-Error "Windows 10 or later is required"
    exit 1
}

if ($osVersion.Build -lt 1809 -and $osVersion.Major -eq 10) {
    Write-Warning "Windows 10 version 1809 or later recommended (current: $($osVersion.Build))"
}
else {
    Write-Success "Windows version is compatible"
}

# ============================================================================
# 4. POWERSHELL VERSION CHECK
# ============================================================================

Write-Header "STEP 4: PowerShell Version Check"

$psVersion = $PSVersionTable.PSVersion
Write-Info "PowerShell version: $psVersion"

if ($psVersion.Major -lt 5) {
    Write-Error "PowerShell 5.0 or later is required (current: $psVersion)"
    Write-Warning "Please upgrade PowerShell from: https://www.microsoft.com/en-us/download/details.aspx?id=54616"
    exit 1
}
else {
    Write-Success "PowerShell version is compatible"
}

# ============================================================================
# 5. POWERSHELL 7+ INSTALLATION (OPTIONAL)
# ============================================================================

if ($InstallPowerShell7 -or (!$SkipInteractive -and (Read-Host "Install PowerShell 7+ for better compatibility? (Y/n)" -DefaultValue "n") -eq "Y")) {
    Write-Header "STEP 5A: Installing PowerShell 7+"
    
    try {
        # Check if PowerShell 7 is already installed
        $ps7Installed = $null -ne (Get-Command pwsh -ErrorAction SilentlyContinue)
        
        if ($ps7Installed) {
            Write-Success "PowerShell 7 is already installed"
        }
        else {
            Write-Info "Downloading PowerShell 7..."
            
            # Download and install PowerShell 7
            $msiUrl = "https://github.com/PowerShell/PowerShell/releases/download/v7.4.1/PowerShell-7.4.1-win-x64.msi"
            $msiPath = "$env:TEMP\PowerShell-7.4.1-win-x64.msi"
            
            # Download
            Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath -ErrorAction Stop
            Write-Success "Downloaded PowerShell 7 installer"
            
            # Install
            Write-Info "Installing PowerShell 7 (this may take a minute)..."
            Start-Process -FilePath "msiexec.exe" -ArgumentList "/i", $msiPath, "/quiet", "/norestart" -Wait -ErrorAction Stop
            Write-Success "PowerShell 7 installed successfully"
            
            # Cleanup
            Remove-Item -Path $msiPath -Force -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Error "Failed to install PowerShell 7: $_"
    }
}

# ============================================================================
# 6. NETWORK CONNECTIVITY CHECK
# ============================================================================

Write-Header "STEP 6: Network Connectivity Verification"

$networkTests = @(
    @{ Host = "github.com"; Label = "GitHub" },
    @{ Host = "raw.githubusercontent.com"; Label = "GitHub Raw Content" }
)

$allNetworkOk = $true

foreach ($test in $networkTests) {
    try {
        $result = Test-Connection -ComputerName $test.Host -Count 1 -ErrorAction Stop
        Write-Success "$($test.Label) is reachable"
    }
    catch {
        Write-Error "$($test.Label) is not reachable: $_"
        $allNetworkOk = $false
    }
}

if (-not $allNetworkOk) {
    Write-Warning "Some network connectivity issues detected. Check your firewall and internet connection."
}

# ============================================================================
# 7. DISK SPACE CHECK
# ============================================================================

Write-Header "STEP 7: Disk Space Verification"

$diskInfo = Get-Volume -DriveLetter C
$freeSpaceGB = [math]::Round($diskInfo.SizeRemaining / 1GB, 2)
$requiredGB = 0.1

Write-Info "Free space on C: drive: $freeSpaceGB GB"

if ($diskInfo.SizeRemaining -lt ($requiredGB * 1GB)) {
    Write-Error "Insufficient disk space. Required: ${requiredGB}GB, Available: $freeSpaceGB GB"
}
else {
    Write-Success "Sufficient disk space available"
}

# ============================================================================
# 8. ProgramData DIRECTORY CHECK
# ============================================================================

Write-Header "STEP 8: ProgramData Directory Setup"

$programDataPath = "C:\ProgramData\SSHX-Manager"

if (Test-Path -Path $programDataPath) {
    Write-Success "SSHX-Manager directory already exists: $programDataPath"
}
else {
    try {
        New-Item -ItemType Directory -Path $programDataPath -Force -ErrorAction Stop | Out-Null
        Write-Success "Created SSHX-Manager directory: $programDataPath"
    }
    catch {
        Write-Error "Failed to create SSHX-Manager directory: $_"
    }
}

# Create logs subdirectory
$logsPath = Join-Path -Path $programDataPath -ChildPath "logs"
if (-not (Test-Path -Path $logsPath)) {
    try {
        New-Item -ItemType Directory -Path $logsPath -Force -ErrorAction Stop | Out-Null
        Write-Success "Created logs directory: $logsPath"
    }
    catch {
        Write-Error "Failed to create logs directory: $_"
    }
}

# ============================================================================
# 9. FIREWALL RULES (OPTIONAL)
# ============================================================================

if ($ConfigureFirewall -or (!$SkipInteractive -and (Read-Host "Configure Windows Firewall rules for HTTPS? (Y/n)" -DefaultValue "n") -eq "Y")) {
    Write-Header "STEP 9: Windows Firewall Configuration"
    
    try {
        Write-Info "Checking firewall rules for HTTPS outbound traffic..."
        
        $httpsRule = Get-NetFirewallRule -DisplayName "SSHX-Manager HTTPS" -ErrorAction SilentlyContinue
        
        if ($null -eq $httpsRule) {
            Write-Info "Creating firewall rule for HTTPS outbound traffic..."
            New-NetFirewallRule -DisplayName "SSHX-Manager HTTPS" `
                -Direction Outbound `
                -Action Allow `
                -Protocol TCP `
                -RemotePort 443 `
                -ErrorAction Stop | Out-Null
            Write-Success "Firewall rule created"
        }
        else {
            Write-Success "Firewall rule already exists"
        }
    }
    catch {
        Write-Error "Failed to configure firewall: $_"
    }
}

# ============================================================================
# 10. GPG INSTALLATION (OPTIONAL)
# ============================================================================

if ($InstallGPG -or (!$SkipInteractive -and (Read-Host "Install GPG for signature verification? (Y/n)" -DefaultValue "n") -eq "Y")) {
    Write-Header "STEP 10: GPG Installation (Optional)"
    
    try {
        # Check if GPG is already installed
        $gpgInstalled = $null -ne (Get-Command gpg -ErrorAction SilentlyContinue)
        
        if ($gpgInstalled) {
            $gpgVersion = gpg --version | Select-Object -First 1
            Write-Success "GPG is already installed: $gpgVersion"
        }
        else {
            Write-Info "GPG not found. Installing via Chocolatey..."
            
            # Check if Chocolatey is installed
            $chocoInstalled = $null -ne (Get-Command choco -ErrorAction SilentlyContinue)
            
            if (-not $chocoInstalled) {
                Write-Info "Installing Chocolatey (required for GPG)..."
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')) -ErrorAction Stop
                Write-Success "Chocolatey installed"
            }
            
            # Install GPG
            Write-Info "Installing GPG via Chocolatey..."
            choco install gnupg -y -ErrorAction Stop
            Write-Success "GPG installed successfully"
        }
    }
    catch {
        Write-Error "Failed to install GPG: $_"
        Write-Warning "GPG is optional; signature verification can be skipped"
    }
}

# ============================================================================
# 11. WINDOWS DEFENDER STATUS CHECK
# ============================================================================

Write-Header "STEP 11: Windows Defender Status Check"

try {
    $defenderStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
    
    if ($null -ne $defenderStatus) {
        $realtimeEnabled = $defenderStatus.RealTimeProtectionEnabled
        Write-Info "Windows Defender Real-time Protection: $(if ($realtimeEnabled) { 'Enabled' } else { 'Disabled' })"
        
        if ($realtimeEnabled) {
            Write-Warning "Windows Defender is enabled. The script will request consent to add exclusions during installation."
        }
    }
    else {
        Write-Info "Windows Defender status not available"
    }
}
catch {
    Write-Warning "Could not check Windows Defender status: $_"
}

# ============================================================================
# 12. TASK SCHEDULER VERIFICATION
# ============================================================================

Write-Header "STEP 12: Task Scheduler Verification"

try {
    $schedulerService = Get-Service -Name Schedule -ErrorAction Stop
    
    if ($schedulerService.Status -eq "Running") {
        Write-Success "Task Scheduler is running"
    }
    else {
        Write-Warning "Task Scheduler is not running. Attempting to start..."
        Start-Service -Name Schedule -ErrorAction Stop
        Write-Success "Task Scheduler started"
    }
}
catch {
    Write-Error "Failed to verify Task Scheduler: $_"
}

# ============================================================================
# SUMMARY AND FINAL CHECKLIST
# ============================================================================

Write-Header "SETUP SUMMARY"

$checklist = @{
    "Execution Policy Set"          = $true
    "Administrator Privileges"      = $true
    "Windows 10/11 or Server 2019+" = $osVersion.Major -ge 10
    "PowerShell 5.0+"               = $psVersion.Major -ge 5
    "Network Connectivity"          = $allNetworkOk
    "Disk Space (>100MB)"           = $diskInfo.SizeRemaining -gt (0.1 * 1GB)
    "ProgramData Directory Created" = (Test-Path -Path $programDataPath)
    "Task Scheduler Running"        = (Get-Service -Name Schedule -ErrorAction SilentlyContinue).Status -eq "Running"
}

Write-Host ""
foreach ($item in $checklist.GetEnumerator()) {
    if ($item.Value) {
        Write-Success $item.Key
    }
    else {
        Write-Error $item.Key
    }
}

# ============================================================================
# FINAL INSTRUCTIONS
# ============================================================================

Write-Header "NEXT STEPS"

Write-Info "All prerequisites have been configured!"
Write-Info ""
Write-Info "You can now run the SSHX-Manager script:"
Write-Info ""
Write-Host "  Option 1 - Local execution:" -ForegroundColor Cyan
Write-Host "  .\sshx-manager.ps1" -ForegroundColor White
Write-Host ""
Write-Host "  Option 2 - One-line web install:" -ForegroundColor Cyan
Write-Host "  powershell -Command ""iex (irm https://raw.githubusercontent.com/Munirg2003/SSHX-manager-MultiOS-v2/main/sshx-manager.ps1)""" -ForegroundColor White
Write-Host ""
Write-Host "  Option 3 - With execution policy override:" -ForegroundColor Cyan
Write-Host "  powershell -ExecutionPolicy Bypass -File sshx-manager.ps1" -ForegroundColor White
Write-Host ""

Write-Info "For more information, see REQUIREMENTS.md in the repository"
Write-Info ""

# ============================================================================
# SCRIPT COMPLETE
# ============================================================================

Write-Success "Setup complete!"
Write-Host ""
Read-Host "Press Enter to exit"
