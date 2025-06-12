# Maintenance.ps1
# Automated Windows 11 maintenance script
# Clears event logs, cleans temp files, runs Windows updates, pushes script updates to GitHub,
# rotates logs, and sends error email alerts.

# -------- Config --------
$scriptFolder = "C:\Users\miste\maintenanceScripts"
$repoUrl = "git@github.com:bentpigeonnz/maintenanceScripts.git"
$commitMessage = "Automated maintenance script update on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

$logFolder = Join-Path $scriptFolder "logs"
if (-not (Test-Path $logFolder)) { New-Item -Path $logFolder -ItemType Directory | Out-Null }
$logFile = Join-Path $logFolder "maintenance_$(Get-Date -Format 'yyyyMMdd').log"

$logRetentionDays = 7
$archiveFolder = Join-Path $logFolder "archive"
if (-not (Test-Path $archiveFolder)) { New-Item -Path $archiveFolder -ItemType Directory | Out-Null }

# Email config — replace <YOUR_APP_PASSWORD> with your Gmail app password
$smtpServer = "smtp.gmail.com"
$smtpPort = 587
$smtpUser = "mistermurraynz@gmail.com"
$smtpPass = "kdee tyam kery ijzb"
$emailFrom = "mistermurraynz@gmail.com"
$emailTo = "mistermurraynz@gmail.com"
$emailSubject = "Maintenance Script ERROR Alert on $(hostname) at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# Internal vars
$global:hasErrors = $false
$errorMessages = @()

function Write-Log {
    param([string]$message, [string]$level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$timestamp [$level] - $message"
    Write-Host $line
    Add-Content -Path $logFile -Value $line
    if ($level -eq "ERROR") {
        $global:hasErrors = $true
        $global:errorMessages += $message
    }
}

function Rotate-Logs {
    Write-Log "Rotating logs older than $logRetentionDays days..."
    $cutoffDate = (Get-Date).AddDays(-$logRetentionDays)
    Get-ChildItem -Path $logFolder -Filter "maintenance_*.log" | Where-Object {
        $_.LastWriteTime -lt $cutoffDate
    } | ForEach-Object {
        $dest = Join-Path $archiveFolder $_.Name
        Move-Item -Path $_.FullName -Destination $dest -Force
        Write-Log "Archived log file $($_.Name) to archive."
    }
}

function Send-ErrorEmail {
    if (-not $global:hasErrors) { return }
    Write-Log "Sending error alert email..."

    $body = "The maintenance script encountered errors:`n`n"
    $body += ($global:errorMessages -join "`n")
    $body += "`n`nPlease check the script and logs at $logFile"

    try {
        $securePass = ConvertTo-SecureString $smtpPass -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential ($smtpUser, $securePass)
        Send-MailMessage -From $emailFrom -To $emailTo -Subject $emailSubject -Body $body -SmtpServer $smtpServer -Port $smtpPort -UseSsl -Credential $cred
        Write-Log "Error alert email sent successfully."
    } catch {
        Write-Log "Failed to send error alert email: $($_.Exception.Message)" "ERROR"
    }
}

# ----- Main Script -----

Write-Log "=== Starting Maintenance Script ==="

try {
    Rotate-Logs
} catch {
    Write-Log "Error rotating logs: $($_.Exception.Message)" "ERROR"
}

try {
    Write-Log "Clearing event logs..."
    $logs = wevtutil el
    foreach ($log in $logs) {
        try {
            wevtutil cl $log
            Write-Log "Cleared event log: $log"
        } catch {
            Write-Log "Warning: Failed to clear event log $log - $($_.Exception.Message)"
        }
    }
} catch {
    Write-Log "Error retrieving event logs: $($_.Exception.Message)" "ERROR"
}

try {
    Write-Log "Cleaning temporary files..."
    $tempPaths = @(
        "$env:LOCALAPPDATA\Temp\*",
        "$env:TEMP\*",
        "$env:SystemRoot\Temp\*"
    )
    foreach ($path in $tempPaths) {
        try {
            Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
            Write-Log "Cleared temp files in $path"
        } catch {
            Write-Log "Warning: Could not clear temp files at $path - $($_.Exception.Message)"
        }
    }
} catch {
    Write-Log "Error cleaning temp files: $($_.Exception.Message)" "ERROR"
}

try {
    Write-Log "Checking and installing Windows updates..."
    $updateSession = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()
    $searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Software'")
    if ($searchResult.Updates.Count -gt 0) {
        Write-Log "Found $($searchResult.Updates.Count) updates. Installing..."
        $updatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl
        foreach ($update in $searchResult.Updates) {
            $updatesToInstall.Add($update) | Out-Null
        }
        $installer = $updateSession.CreateUpdateInstaller()
        $installer.Updates = $updatesToInstall
        $result = $installer.Install()
        Write-Log "Installation result: $($result.ResultCode)"
    } else {
        Write-Log "No pending updates found."
    }
} catch {
    Write-Log "Error during Windows Update: $($_.Exception.Message)" "ERROR"
}

try {
    Write-Log "Committing and pushing maintenance script to GitHub..."
    Set-Location $scriptFolder
    if (Test-Path "$scriptFolder\.git") {
        git add -A
        git commit -m $commitMessage -q
        git push origin main -q
        Write-Log "Pushed changes to GitHub repo."
    } else {
        Write-Log "Git repository not found in $scriptFolder. Attempting to clone..."
        git clone $repoUrl $scriptFolder
        Write-Log "Repository cloned."
    }
} catch {
    Write-Log "Git operation failed: $($_.Exception.Message)" "ERROR"
}

Send-ErrorEmail

Write-Log "=== Maintenance Script Completed ==="
