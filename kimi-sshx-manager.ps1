<#
.SYNOPSIS
    SSHX.IO Complete Management System v5.9
    Fixed AV stopping, scheduled task status display, and streamlined UI

.DESCRIPTION
    Ensures AV is properly stopped, displays scheduled task status correctly,
    and removes unnecessary pauses and duplicate status displays
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

# ============================================================================
# CONFIGURATION
# ============================================================================
$ScriptVersion = "5.9.0"

$WorkingDir = "$env:ProgramData\SSHX-Manager"
$InstallDir = Join-Path ([Environment]::GetFolderPath("ProgramFilesX64")) "SSHX"

if ([string]::IsNullOrWhiteSpace($InstallDir)) {
    $InstallDir = Join-Path ([Environment]::GetFolderPath("ProgramFiles")) "SSHX"
}

$DownloadURL = "https://sshx.s3.amazonaws.com/sshx-x86_64-pc-windows-msvc.zip"
$StateFile = "$WorkingDir\sshx-state.json"
$TaskName = "SSHX-AutoStart"

@($WorkingDir, $InstallDir) | ForEach-Object {
    if (!(Test-Path $_)) { 
        try {
            New-Item -Path $_ -ItemType Directory -Force | Out-Null
        } catch {
            Write-Error "❌ Failed to create directory $_ : $_"
            exit 1
        }
    }
}

function Write-Status {
    param([string]$Message, [string]$Type = "INFO")
    $colors = @{ "INFO" = "White"; "SUCCESS" = "Green"; "ERROR" = "Red"; "WARNING" = "Yellow" }
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [$Type] $Message" -ForegroundColor $colors[$Type]
}

# ============================================================================
# STATE MANAGEMENT
# ============================================================================
function Get-SSHXState {
    $state = @{
        IsInstalled = $false
        IsRunning = $false
        PIDs = @()
        InstallPath = ""
        Version = ""
        LastDownloadCheck = ""
        LastURL = ""
        ScheduledTaskStatus = "NotConfigured"
    }
    
    $exePath = Join-Path $InstallDir "sshx.exe"
    if (Test-Path $exePath) {
        $state.IsInstalled = $true
        $state.InstallPath = $exePath
        
        try {
            $versionInfo = (Get-Item $exePath).VersionInfo
            $state.Version = $versionInfo.ProductVersion
        } catch {
            $state.Version = "Unknown"
        }
    }
    
    $processes = Get-Process "sshx" -ErrorAction SilentlyContinue
    if ($processes) {
        $state.IsRunning = $true
        $state.PIDs = @($processes | ForEach-Object { $_.Id })
    }
    
    # FIX: Ensure scheduled task status is always checked
    try {
        $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($task) {
            $state.ScheduledTaskStatus = $task.State.ToString()
            Write-Status "Scheduled task found: $($task.State)" "INFO"
        } else {
            $state.ScheduledTaskStatus = "NotConfigured"
            Write-Status "No scheduled task found" "INFO"
        }
    } catch {
        $state.ScheduledTaskStatus = "Error"
        Write-Status "Error checking scheduled task: $_" "WARNING"
    }
    
    if (Test-Path $StateFile) {
        try {
            $savedState = Get-Content $StateFile -Raw | ConvertFrom-Json
            $state.LastDownloadCheck = $savedState.LastDownloadCheck
            $state.LastURL = $savedState.LastURL
        } catch {}
    }
    
    return $state
}

function Save-SSHXState {
    param([hashtable]$State)
    if (!(Test-Path $WorkingDir)) {
        New-Item -Path $WorkingDir -ItemType Directory -Force | Out-Null
    }
    
    try {
        $State | ConvertTo-Json | Set-Content $StateFile -Force
    } catch {
        Write-Status "Failed to save state: $_" "ERROR"
    }
}

function Show-CurrentStatus {
    $state = Get-SSHXState
    
    Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              SSHX.IO MANAGEMENT SYSTEM v$ScriptVersion              ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    
    Write-Host "`n📋 STATUS OVERVIEW:" -ForegroundColor Cyan
    Write-Host "Installation: $(if($state.IsInstalled){'✅ Installed'}else{'❌ Not Installed'})" -ForegroundColor $(if($state.IsInstalled){'Green'}else{'Red'})
    Write-Host "Running: $(if($state.IsRunning){'✅ Yes (PID: '+($state.PIDs -join ', ')+')'}else{'❌ No'})" -ForegroundColor $(if($state.IsRunning){'Green'}else{'Red'})
    
    if ($state.IsInstalled) {
        Write-Host "Path: $($state.InstallPath)" -ForegroundColor Gray
        Write-Host "Version: $($state.Version)" -ForegroundColor Gray
        
        # FIX: Display scheduled task status properly
        if ($state.ScheduledTaskStatus -eq "Ready" -or $state.ScheduledTaskStatus -eq "Running") {
            Write-Host "Scheduled Task: ✅ Enabled ($($state.ScheduledTaskStatus))" -ForegroundColor Green
        } elseif ($state.ScheduledTaskStatus -eq "NotConfigured") {
            Write-Host "Scheduled Task: ❌ Not Configured" -ForegroundColor Gray
        } else {
            Write-Host "Scheduled Task: ⚠️ $($state.ScheduledTaskStatus)" -ForegroundColor Yellow
        }
    }
    
    # Only show URL if SSHX is installed AND we have a captured URL
    if ($state.IsInstalled -and $state.LastURL) {
        Write-Host "🔗 URL: $($state.LastURL)" -ForegroundColor Yellow
    }
    
    return $state
}

# ============================================================================
# ANTIVIRUS MANAGEMENT
# ============================================================================
$AntivirusProcesses = @(
    "MsMpEng", "NisSrv", "epredline", "ekrn", "avp", "avguard"
)

function Get-AntivirusStatus {
    Write-Status "Scanning for antivirus products..." "INFO"
    $detectedAV = [System.Collections.ArrayList]@()
    
    foreach ($avProcess in $AntivirusProcesses) {
        $processes = Get-Process -Name $avProcess -ErrorAction SilentlyContinue
        if ($processes) {
            $null = $detectedAV.Add(@{
                Name = $avProcess
                DisplayName = switch($avProcess) {
                    "MsMpEng" { "Windows Defender" }
                    "NisSrv" { "Windows Defender Network" }
                    "epredline" { "ESET" }
                    "ekrn" { "ESET Service" }
                    "avp" { "Kaspersky" }
                    "avguard" { "Avira" }
                    default { $avProcess }
                }
                PIDs = @($processes | ForEach-Object { $_.Id })
                Running = $true
            })
            Write-Status "Detected: $($($detectedAV[-1]).DisplayName)" "WARNING"
        }
    }
    
    if ($detectedAV.Count -eq 0) {
        Write-Status "No antivirus detected" "INFO"
    }
    
    return $detectedAV
}

function Stop-AntivirusServices {
    param([array]$AntivirusList)
    
    if ($null -eq $AntivirusList -or $AntivirusList.Count -eq 0) {
        return $false
    }
    
    Write-Status "Stopping antivirus services..." "WARNING"
    $stoppedCount = 0
    
    # FIX: Better verification that Defender is actually stopped
    if ($AntivirusList.Name -contains "MsMpEng") {
        try {
            Write-Status "Disabling Windows Defender real-time monitoring..." "INFO"
            Set-MpPreference -DisableRealtimeMonitoring $true -ErrorAction SilentlyContinue
            
            Write-Status "Terminating MsMpEng and NisSrv processes..." "INFO"
            Get-Process -Name MsMpEng -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            Get-Process -Name NisSrv -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
            
            # Verify processes are actually stopped
            Start-Sleep -Seconds 2
            $defenderStillRunning = Get-Process -Name MsMpEng -ErrorAction SilentlyContinue
            if ($defenderStillRunning) {
                Write-Status "⚠️ Defender still running, may need manual intervention" "WARNING"
            } else {
                $stoppedCount++
                Write-Status "✅ Windows Defender stopped" "SUCCESS"
            }
        } catch {
            Write-Status "⚠️ Could not stop Defender: $_" "WARNING"
        }
    }
    
    foreach ($av in $AntivirusList) {
        if ($av.Name -ne "MsMpEng") {
            try {
                Write-Status "Stopping $($av.DisplayName)..." "INFO"
                foreach ($procId in $av.PIDs) {
                    Stop-Process -Id $procId -Force -ErrorAction SilentlyContinue
                }
                Start-Sleep -Seconds 1
                $stoppedCount++
                Write-Status "✅ $($av.DisplayName) stopped" "SUCCESS"
            } catch {
                Write-Status "⚠️ Could not stop $($av.DisplayName): $_" "WARNING"
            }
        }
    }
    
    Start-Sleep -Seconds 3
    return $stoppedCount -gt 0
}

function Add-AntivirusExclusions {
    Write-Status "Adding antivirus exclusions..." "INFO"
    
    $paths = @($InstallDir, $WorkingDir, [System.IO.Path]::GetTempPath())
    
    try {
        foreach ($path in $paths) {
            Add-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue -Force
        }
        Add-MpPreference -ExclusionProcess "sshx.exe" -ErrorAction SilentlyContinue -Force
        Write-Status "✅ Defender exclusions configured" "SUCCESS"
    } catch {
        Write-Status "⚠️ Could not add Defender exclusions: $_" "WARNING"
    }
    
    Start-Sleep -Seconds 2
}

function Remove-AntivirusExclusions {
    Write-Status "Removing antivirus exclusions..." "INFO"
    
    $paths = @($InstallDir, $WorkingDir, [System.IO.Path]::GetTempPath())
    
    try {
        foreach ($path in $paths) {
            Remove-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue
        }
        Remove-MpPreference -ExclusionProcess "sshx.exe" -ErrorAction SilentlyContinue
        Write-Status "✅ Defender exclusions removed" "SUCCESS"
    } catch {
        Write-Status "⚠️ Could not remove Defender exclusions: $_" "WARNING"
    }
}

function Restore-AntivirusServices {
    Write-Status "Restoring antivirus protection..." "INFO"
    
    try {
        Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
        Write-Status "✅ Antivirus protection restored" "SUCCESS"
        return $true
    } catch {
        Write-Status "⚠️ Could not restore antivirus: $_" "WARNING"
        return $false
    }
}

# ============================================================================
# SCHEDULED TASK MANAGEMENT
# ============================================================================
function Add-SSHXScheduledTask {
    Write-Status "Configuring scheduled task for SSHX..." "INFO"
    
    $state = Get-SSHXState
    if (!$state.IsInstalled) {
        Write-Status "❌ SSHX not installed. Install first!" "ERROR"
        return $false
    }
    
    $exePath = Join-Path $InstallDir "sshx.exe"
    if (!(Test-Path $exePath)) {
        Write-Status "❌ SSHX executable not found!" "ERROR"
        return $false
    }
    
    # Clean up any existing task first
    Remove-SSHXScheduledTask
    
    try {
        Write-Status "Creating task with executable: $exePath" "INFO"
        
        # FIX: Use proper user identification
        $currentUser = whoami
        
        # Create action with proper working directory
        $action = New-ScheduledTaskAction -Execute $exePath -WorkingDirectory $InstallDir
        
        # Create trigger for user login
        $trigger = New-ScheduledTaskTrigger -AtLogOn -User $currentUser
        
        # Create principal with highest privileges
        $principal = New-ScheduledTaskPrincipal -UserId $currentUser -LogonType Interactive -RunLevel Highest
        
        # Register task
        $task = Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Force
        
        if ($task) {
            Write-Status "✅ Scheduled task created successfully" "SUCCESS"
            Write-Status "   Task: $TaskName | User: $currentUser | RunLevel: Highest" "INFO"
            
            # Verify task was created
            $verifiedTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
            if ($verifiedTask) {
                Write-Status "✅ Task verified and ready" "SUCCESS"
                return $true
            } else {
                throw "Task creation not verified"
            }
        } else {
            throw "Task registration returned null"
        }
    } catch {
        Write-Status "❌ Failed to create scheduled task: $_" "ERROR"
        Write-Status "   Ensure you have permissions to create scheduled tasks" "WARNING"
        return $false
    }
}

function Remove-SSHXScheduledTask {
    Write-Status "Removing scheduled task..." "INFO"
    
    $task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if (!$task) {
        Write-Status "ℹ️ No scheduled task found" "INFO"
        return $true
    }
    
    try {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
        Write-Status "✅ Scheduled task removed successfully" "SUCCESS"
        return $true
    } catch {
        Write-Status "❌ Failed to remove scheduled task: $_" "ERROR"
        return $false
    }
}

# ============================================================================
# CORE OPERATIONS
# ============================================================================
function Test-InternetConnection {
    try {
        Invoke-WebRequest -Uri "https://sshx.io" -Method Head -TimeoutSec 5 -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Install-SSHX {
    Write-Status "Starting full SSHX installation pipeline..." "INFO"
    
    $state = Get-SSHXState
    if ($state.IsRunning) {
        Write-Status "SSHX is running. Stopping it first..." "INFO"
        Stop-SSHXProcess | Out-Null
        Start-Sleep -Seconds 2
    }
    
    if ($state.IsInstalled) {
        Write-Status "SSHX already installed. Reinstall? (Y/N)" "WARNING"
        $overwrite = Read-Host
        if ($overwrite -ne 'Y') {
            Write-Status "Installation cancelled" "INFO"
            return $false
        }
        
        Remove-Item "$InstallDir\sshx.exe" -Force -ErrorAction Stop
    }
    
    if (!(Test-InternetConnection)) {
        Write-Status "No internet connection" "ERROR"
        return $false
    }
    
    if (!(Test-Path $InstallDir)) {
        New-Item -Path $InstallDir -ItemType Directory -Force | Out-Null
    }
    
    $avStatus = Get-AntivirusStatus
    $avWasStopped = $false
    
    if ($avStatus.Count -gt 0) {
        Write-Status "Antivirus detected. Attempting to stop services..." "WARNING"
        $avWasStopped = Stop-AntivirusServices $avStatus
        
        if ($avWasStopped) {
            Write-Status "✅ Antivirus services stopped successfully" "SUCCESS"
        } else {
            Write-Status "⚠️ Some antivirus services could not be stopped" "WARNING"
        }
        
        Add-AntivirusExclusions
        Start-Sleep -Seconds 3
    }
    
    try {
        $tempPath = [System.IO.Path]::GetTempPath()
        $zipPath = Join-Path $tempPath "sshx-$(Get-Random).zip"
        $extractPath = Join-Path $tempPath "sshx-extract-$(Get-Random)"
        
        Write-Status "Downloading SSHX to: $zipPath" "INFO"
        
        $progress = @{ Activity = "Downloading SSHX"; Status = "Please wait..."; PercentComplete = 0 }
        Write-Progress @progress
        Invoke-WebRequest -Uri $DownloadURL -OutFile $zipPath -UseBasicParsing
        Write-Progress -Activity "Downloading SSHX" -Completed
        
        Write-Status "Successfully downloaded SSHX" "SUCCESS"
        
        Write-Status "Extracting SSHX..." "INFO"
        New-Item -Path $extractPath -ItemType Directory -Force | Out-Null
        Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
        
        $extractedExe = Get-ChildItem $extractPath -Filter "sshx.exe" -Recurse | Select-Object -First 1
        
        if ($extractedExe) {
            $sourcePath = $extractedExe.FullName
            $destinationPath = Join-Path $InstallDir "sshx.exe"
            
            Write-Status "Installing to: $destinationPath" "INFO"
            Copy-Item -Path $sourcePath -Destination $destinationPath -Force
            
            if (Test-Path $destinationPath) {
                $versionInfo = (Get-Item $destinationPath).VersionInfo
                Write-Status "✅ SSHX installed successfully" "SUCCESS"
                Write-Status "Version: $($versionInfo.ProductVersion)" "INFO"
                
                $newState = Get-SSHXState
                $newState.LastDownloadCheck = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                Save-SSHXState $newState
                
                Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
                Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
                
                $startResult = Start-SSHXProcess
                
                if ($avWasStopped) {
                    Write-Status "Restoring antivirus protection..." "INFO"
                    Restore-AntivirusServices
                }
                
                # ENSURE: Create scheduled task after successful installation and start
                if ($startResult) {
                    Write-Status "Creating scheduled task for auto-start..." "INFO"
                    $taskCreated = Add-SSHXScheduledTask
                    
                    if ($taskCreated) {
                        Write-Status "🎉 Installation completed successfully with scheduled task!" "SUCCESS"
                    } else {
                        Write-Status "⚠️ Installation completed but scheduled task failed" "WARNING"
                    }
                } else {
                    Write-Status "⚠️ SSHX started but may have issues" "WARNING"
                }
                
                return $true
            } else {
                throw "Copy verification failed"
            }
        } else {
            throw "sshx.exe not found"
        }
        
    } catch {
        Write-Status "Installation failed: $_" "ERROR"
        
        if ($avWasStopped) {
            Restore-AntivirusServices
        }
        
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
        Remove-Item $extractPath -Recurse -Force -ErrorAction SilentlyContinue
        return $false
    }
}

function Start-SSHXProcess {
    Write-Status "Starting SSHX process..." "INFO"
    $state = Get-SSHXState
    
    if (!$state.IsInstalled) {
        Write-Status "❌ SSHX not installed. Use Option 1 first" "ERROR"
        return $false
    }
    
    if ($state.IsRunning) {
        Write-Status "⚠️ SSHX already running (PID: $($state.PIDs -join ', '))" "WARNING"
        return $true
    }
    
    try {
        $sshxPath = Join-Path $InstallDir "sshx.exe"
        
        if (!(Test-Path $sshxPath)) {
            throw "SSHX.exe not found at: $sshxPath"
        }
        
        Unblock-File -Path $sshxPath -ErrorAction SilentlyContinue
        
        Write-Status "Starting SSHX console..." "INFO"
        Write-Status "=== SSHX IS STARTING ===" "INFO"
        
        $outputFile = "$WorkingDir\sshx-stdout.txt"
        $errorFile = "$WorkingDir\sshx-stderr.txt"
        
        if (!(Test-Path $WorkingDir)) {
            New-Item -Path $WorkingDir -ItemType Directory -Force | Out-Null
        }
        
        $process = Start-Process -FilePath $sshxPath -PassThru -WindowStyle Normal `
            -RedirectStandardOutput $outputFile -RedirectStandardError $errorFile
        
        Start-Sleep -Seconds 5
        
        if (Test-Path $outputFile) {
            $output = Get-Content $outputFile -Raw
            
            if ($output) {
                Write-Host $output -ForegroundColor Green
                
                if ($output -match 'https://sshx\.io/s/[a-zA-Z0-9#]+') {
                    $urls = $matches[0]
                    
                    $newState = Get-SSHXState
                    $newState.LastURL = $urls
                    Save-SSHXState $newState
                    
                    Write-Status "✅ URLs captured and saved to state" "SUCCESS"
                }
            }
        }
        
        Write-Host "`n=== SSHX IS RUNNING ===" -ForegroundColor Green
        Write-Status "Press any key to continue..." "INFO"
        [void][System.Console]::ReadKey($true)
        
        $newState = Get-SSHXState
        
        if ($newState.IsRunning) {
            Write-Status "✅ SSHX running (PID: $($newState.PIDs -join ', '))" "SUCCESS"
            return $true
        } else {
            Write-Status "⚠️ SSHX may have exited" "WARNING"
            return $false
        }
        
    } catch {
        Write-Status "❌ Failed to start SSHX: $_" "ERROR"
        return $false
    }
}

function Stop-SSHXProcess {
    Write-Status "Stopping SSHX processes..." "INFO"
    $state = Get-SSHXState
    
    if (!$state.IsRunning) {
        Write-Status "ℹ️ SSHX not running" "INFO"
        return $true
    }
    
    Write-Status "Found $($state.PIDs.Count) process(es)" "INFO"
    
    foreach ($processId in $state.PIDs) {
        try {
            Write-Status "Stopping process $processId..." "INFO"
            Get-Process -Id $processId -ErrorAction Stop | Stop-Process -Force -ErrorAction Stop
            Write-Status "✅ Process $processId stopped" "SUCCESS"
        } catch {
            Write-Status "❌ Failed to stop process ${processId}: $_" "ERROR"
        }
    }
    
    Start-Sleep -Seconds 2
    $newState = Get-SSHXState
    
    if (!$newState.IsRunning) {
        Write-Status "✅ All processes stopped" "SUCCESS"
        return $true
    } else {
        Write-Status "⚠️ Some processes may still be running" "WARNING"
        return $false
    }
}

function Get-SSHXURL {
    Write-Status "Retrieving SSHX URLs..." "INFO"
    $state = Get-SSHXState
    
    if (!$state.IsInstalled) {
        Write-Status "❌ SSHX not installed. Use Option 1 first" "ERROR"
        return $false
    }
    
    # Only show URL if we have one captured
    if ($state.LastURL) {
        Write-Status "✅ Found captured URL:" "SUCCESS"
        Write-Host $state.LastURL -ForegroundColor Cyan
        return $true
    }
    
    if ($state.IsRunning) {
        Write-Host "`nℹ️ SSHX is running" -ForegroundColor Cyan
        Write-Status "URLs only available when SSHX first starts" "INFO"
    } else {
        Write-Host "`nℹ️ SSHX is not running" -ForegroundColor Yellow
    }
    
    return $true
}

function Toggle-SSHXService {
    Write-Status "Toggling SSHX service..." "INFO"
    $state = Get-SSHXState
    
    if (!$state.IsInstalled) {
        Write-Status "❌ SSHX not installed. Use Option 1 first!" "ERROR"
        return $false
    }
    
    if ($state.IsRunning) {
        Write-Status "SSHX is running. Stopping..." "INFO"
        return Stop-SSHXProcess
    } else {
        Write-Status "SSHX is stopped. Starting..." "INFO"
        return Start-SSHXProcess
    }
}

function Uninstall-SSHX {
    Write-Status "Starting SSHX uninstallation..." "INFO"
    $state = Get-SSHXState
    
    if (!$state.IsInstalled) {
        Write-Status "ℹ️ SSHX not installed. Nothing to uninstall." "INFO"
        Write-Status "✅ System already clean" "SUCCESS"
        return $true
    }
    
    Write-Status "⚠️ Uninstalling SSHX and cleaning all components..." "WARNING"
    Start-Sleep -Seconds 2
    
    Stop-SSHXProcess | Out-Null
    Remove-SSHXScheduledTask | Out-Null
    Remove-AntivirusExclusions
    
    if (Test-Path $InstallDir) {
        try {
            Remove-Item -Path $InstallDir -Recurse -Force -ErrorAction Stop
            Write-Status "✅ Installation directory removed" "SUCCESS"
        } catch {
            Write-Status "⚠️ Could not remove install dir: $_" "WARNING"
        }
    }
    
    if (Test-Path $WorkingDir) {
        try {
            Remove-Item -Path $WorkingDir -Recurse -Force -ErrorAction SilentlyContinue
            Write-Status "✅ Working directory removed" "SUCCESS"
        } catch {
            Write-Status "⚠️ Could not remove working dir: $_" "WARNING"
        }
    }
    
    Write-Status "🎉 SSHX completely uninstalled!" "SUCCESS"
}

# ============================================================================
# MENU
# ============================================================================
function Show-MainMenu {
    Clear-Host
    Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              SSHX.IO MANAGEMENT SYSTEM v$ScriptVersion              ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    
    $state = Get-SSHXState  # Gets fresh status every time
    Write-Host "`n📋 Status: $(if($state.IsInstalled){'✅ Installed'}else{'❌ Not Installed'}) | $(if($state.IsRunning){'✅ Running (PID: '+($state.PIDs -join ', ')+')'}else{'❌ Stopped'})" -ForegroundColor White
    
    # FIX: Display scheduled task status in menu summary
    if ($state.ScheduledTaskStatus -eq "Ready" -or $state.ScheduledTaskStatus -eq "Running") {
        Write-Host "📅 Task: ✅ Enabled ($($state.ScheduledTaskStatus))" -ForegroundColor Green
    } else {
        Write-Host "📅 Task: ❌ Not Configured" -ForegroundColor Gray
    }
    
    # Only show URL if installed and captured
    if ($state.IsInstalled -and $state.LastURL) {
        Write-Host "🔗 URL: $($state.LastURL)" -ForegroundColor Yellow
    }
    
    Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║                         MAIN MENU                            ║" -ForegroundColor Yellow
    Write-Host "╠══════════════════════════════════════════════════════════════╣" -ForegroundColor Yellow
    Write-Host "║  [1] 📥 Install SSHX & Auto-Configure (Full Pipeline)       ║" -ForegroundColor Green
    Write-Host "║  [2] 📊 Check Status & Show URLs                             ║" -ForegroundColor Cyan
    Write-Host "║  [3] 🔄 Start/Stop SSHX On-Demand                            ║" -ForegroundColor Magenta
    Write-Host "║  [4] 🗑️  Uninstall SSHX (Complete Removal)                   ║" -ForegroundColor Red
    Write-Host "║  [E] ❌ Exit (Keep SSHX Running)                             ║" -ForegroundColor Gray
    Write-Host "║  [Q] ⏹️  Exit & Stop SSHX                                    ║" -ForegroundColor Red
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
    
    Write-Host "`nSelect option: " -NoNewline -ForegroundColor Yellow
    return Read-Host
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================
Write-Status "Starting SSHX Manager v$ScriptVersion..." "INFO"

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (!$isAdmin) {
    Write-Status "Administrator required. Restarting..." "WARNING"
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -Wait
    exit
}

Write-Status "✅ Running with administrator privileges" "SUCCESS"

try {
    do {
        Show-CurrentStatus  # Shows status overview once per loop
        $choice = Show-MainMenu  # Shows menu with embedded status
        
        switch ($choice.ToUpper()) {
            "1" { 
                Install-SSHX
            }
            "2" { 
                Get-SSHXURL
            }
            "3" { 
                Toggle-SSHXService
            }
            "4" { 
                Uninstall-SSHX
            }
            "E" { 
                Write-Status "Exiting without stopping SSHX. It will continue running in background." "SUCCESS"
                Write-Status "To stop SSHX later, run this script again and choose Option Q." "INFO"
                exit 0 
            }
            "Q" { 
                Write-Status "Stopping SSHX and exiting..." "INFO"
                Stop-SSHXProcess | Out-Null
                Write-Status "Goodbye!" "SUCCESS"
                exit 0 
            }
            default { 
                Write-Status "Invalid choice" "WARNING" 
                Start-Sleep -Seconds 1
            }
        }
        
        # FIX: Removed "Press any key" and duplicate status display
        # Loop will continue immediately, showing fresh status at top
        
    } while ($true)
} catch {
    Write-Status "FATAL ERROR: $_" "ERROR"
    Write-Status "Stack Trace: $($_.ScriptStackTrace)" "ERROR"
    exit 1
}