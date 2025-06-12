# Maintenance.ps1 - Full System and Dev Tools Maintenance Script
# Includes: Event logs, temp cleanup, Windows Update, dev tool upgrades, log rotation, Git push, and email alerts

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

# Email config
$smtpServer = "smtp.gmail.com"
$smtpPort = 587
$smtpUser = "mistermurraynz@gmail.com"
$smtpPass = "arqi lfkw oqaf ylml"  # Replace with your actual app password
$emailFrom = "mistermurraynz@gmail.com"
$emailTo = "mistermurraynz@gmail.com"
$emailSubject = "⚠️ Maintenance Script Error on $(hostname) at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# Error state
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
    $cutoff = (Get-Date).AddDays(-$logRetentionDays)
    Get-ChildItem -Path $logFolder -Filter "maintenance_*.log" | Where-Object {
        $_.LastWriteTime -lt $cutoff
    } | ForEach-Object {
        Move-Item $_.FullName -Destination $archiveFolder -Force
        Write-Log "Archived log file: $($_.Name)"
    }
}

function Send-ErrorEmail {
    if (-not $global:hasErrors) { return }
    Write-Log "Sending error alert email..."
    $body = "The maintenance script encountered errors:`n`n"
    $body += ($global:errorMessages -join "`n")
    $body += "`n`nPlease check the log at: $logFile"

    try {
        $securePass = ConvertTo-SecureString $smtpPass -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential ($smtpUser, $securePass)
        Send-MailMessage -From $emailFrom -To $emailTo -Subject $emailSubject -Body $body -SmtpServer $smtpServer -Port $smtpPort -UseSsl -Credential $cred
        Write-Log "Error email sent."
    } catch {
        Write-Log ("Failed to send error email: {0}" -f $_.Exception.Message) "ERROR"
    }
}

# -------- Main --------
Write-Log "=== Starting Full Maintenance Script ==="

try {
    Rotate-Logs
} catch {
    Write-Log ("Error rotating logs: {0}" -f $_.Exception.Message) "ERROR"
}

try {
    Write-Log "Clearing event logs..."
    $logs = wevtutil el
    foreach ($log in $logs) {
        try {
            wevtutil cl $log
            Write-Log "Cleared event log: $log"
        } catch {
            Write-Log ("Could not clear event log {0}: {1}" -f $log, $_.Exception.Message) "ERROR"
        }
    }
} catch {
    Write-Log ("Error accessing event logs: {0}" -f $_.Exception.Message) "ERROR"
}

try {
    Write-Log "Clearing temp files..."
    $tempPaths = @(
        "$env:LOCALAPPDATA\Temp\*",
        "$env:TEMP\*",
        "$env:SystemRoot\Temp\*"
    )
    foreach ($path in $tempPaths) {
        try {
            Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
            Write-Log "Cleared temp: $path"
        } catch {
            Write-Log ("Failed to clear temp at {0}: {1}" -f $path, $_.Exception.Message) "ERROR"
        }
    }
} catch {
    Write-Log ("Error cleaning temp files: {0}" -f $_.Exception.Message) "ERROR"
}

try {
    Write-Log "Checking for Windows updates..."
    $session = New-Object -ComObject Microsoft.Update.Session
    $searcher = $session.CreateUpdateSearcher()
    $results = $searcher.Search("IsInstalled=0 and Type='Software'")
    if ($results.Updates.Count -gt 0) {
        Write-Log ("Installing {0} updates..." -f $results.Updates.Count)
        $updates = New-Object -ComObject Microsoft.Update.UpdateColl
        foreach ($u in $results.Updates) { $updates.Add($u) | Out-Null }
        $installer = $session.CreateUpdateInstaller()
        $installer.Updates = $updates
        $status = $installer.Install()
        Write-Log ("Windows Update result: {0}" -f $status.ResultCode)
    } else {
        Write-Log "No Windows updates found."
    }
} catch {
    Write-Log ("Windows Update error: {0}" -f $_.Exception.Message) "ERROR"
}

try {
    Write-Log "Updating developer software with Chocolatey..."
    $chocoCmd = Get-Command choco.exe -ErrorAction SilentlyContinue
    if (-not $chocoCmd) {
        Write-Log "Chocolatey not found on system path." "ERROR"
    } else {
        choco upgrade all -y | ForEach-Object { Write-Log $_ }
        Write-Log "Developer tools updated via Chocolatey."
    }
} catch {
    Write-Log ("Chocolatey update failed: {0}" -f $_.Exception.Message) "ERROR"
}

try {
    Write-Log "Synchronizing local repo with remote (git pull --rebase)..."
    Set-Location $scriptFolder

    if (Test-Path "$scriptFolder\.git") {
        # Pull latest changes with rebase
        git pull origin main --rebase | ForEach-Object { Write-Log $_ }
        
        # Add and commit changes if any
        git add -A
        $commitResult = git commit -m $commitMessage -q 2>&1
        if ($commitResult -notmatch "nothing to commit") {
            Write-Log "Committed changes."
        } else {
            Write-Log "No changes to commit."
        }
        
        # Push commits
        git push origin main | ForEach-Object { Write-Log $_ }
        Write-Log "Git pull and push completed."
    } else {
        Write-Log "Git repository not found. Cloning repo..."
        git clone $repoUrl $scriptFolder | ForEach-Object { Write-Log $_ }
        Write-Log "Repository cloned."
    }
} catch {
    Write-Log ("Git operation failed: {0}" -f $_.Exception.Message) "ERROR"
}

Send-ErrorEmail
Write-Log "=== Maintenance Script Completed ==="
