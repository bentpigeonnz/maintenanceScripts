# Maintenance.ps1
# Automated Windows 11 maintenance script
# Clears event logs, cleans temp files, runs Windows updates, and pushes script updates to GitHub.

# Config - update these variables as needed
$scriptFolder = "C:\Users\miste\maintenanceScripts"
$repoUrl = "git@github.com:bentpigeonnz/maintenanceScripts.git"
$commitMessage = "Automated maintenance script update on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$logFile = "$scriptFolder\maintenance_log.txt"

function Write-Log {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "$timestamp - $message"
    Write-Host $line
    Add-Content -Path $logFile -Value $line
}

Write-Log "=== Starting Maintenance Script ==="

# 1. Clear Event Logs using wevtutil
Write-Log "Clearing event logs..."
try {
    $logs = wevtutil el
    foreach ($log in $logs) {
        try {
            wevtutil cl $log
            Write-Log "Cleared event log: $log"
        } catch {
            Write-Log "Warning: Failed to clear event log $log - $_"
        }
    }
} catch {
    Write-Log "Error retrieving event logs: $_"
}

# 2. Disk Cleanup - delete temp files
Write-Log "Cleaning temporary files..."
try {
    $tempPaths = @(
        "$env:LOCALAPPDATA\Temp\*",
        "$env:TEMP\*",
        "$env:SystemRoot\Temp\*"
    )
    foreach ($path in $tempPaths) {
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "Cleared temp files in $path"
    }
} catch {
    Write-Log "Error cleaning temp files: $_"
}

# 3. Windows Updates
Write-Log "Checking and installing Windows updates..."
try {
    # Create update session and searcher
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
    Write-Log "Error during Windows Update: $_"
}

# 4. Git push of script folder (commit & push latest changes)
Write-Log "Committing and pushing maintenance script to GitHub..."

try {
    Set-Location $scriptFolder

    # Check if git repo exists
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
    Write-Log "Git operation failed: $_"
}

Write-Log "=== Maintenance Script Completed ==="
