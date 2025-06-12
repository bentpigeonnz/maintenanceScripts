# maintenance.ps1
# Robust maintenance script for Windows dev machine
# Updates system & packages, cleans temp files & logs, disk cleanup, etc.
# Logs all output to a timestamped log file

$logDir = "$env:USERPROFILE\maintenance_logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
$logFile = "$logDir\maintenance_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function LogWrite {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp`t$message"
    Write-Output $entry
    Add-Content -Path $logFile -Value $entry
}

LogWrite "=== Maintenance Script Started ==="

# 1. Windows Updates (using PSWindowsUpdate module)
try {
    LogWrite "Checking for Windows Updates..."
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Install-PackageProvider -Name NuGet -Force -Scope CurrentUser | Out-Null
        Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser
    }
    Import-Module PSWindowsUpdate -Force
    $updates = Get-WindowsUpdate -AcceptAll -IgnoreReboot
    if ($updates) {
        LogWrite "Installing Windows Updates..."
        Install-WindowsUpdate -AcceptAll -IgnoreReboot -Verbose -Confirm:$false | ForEach-Object {
            LogWrite $_.Title
        }
    } else {
        LogWrite "No Windows updates available."
    }
} catch {
    LogWrite "ERROR during Windows Update: $_"
}

# 2. Chocolatey updates
try {
    LogWrite "Updating Chocolatey packages..."
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        choco upgrade all -y | ForEach-Object { LogWrite $_ }
    } else {
        LogWrite "Chocolatey not installed."
    }
} catch {
    LogWrite "ERROR during Chocolatey upgrade: $_"
}

# 3. Clean Temp folders
try {
    LogWrite "Cleaning Temp folders..."
    $tempPaths = @(
        "$env:TEMP\*",
        "$env:WINDIR\Temp\*"
    )
    foreach ($path in $tempPaths) {
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
    }
    LogWrite "Temp folders cleaned."
} catch {
    LogWrite "ERROR cleaning Temp folders: $_"
}

# 4. Empty Recycle Bin
try {
    LogWrite "Emptying Recycle Bin..."
    (New-Object -ComObject Shell.Application).NameSpace(0xA).Items() | ForEach-Object {
        $_.InvokeVerb("delete")
    }
    LogWrite "Recycle Bin emptied."
} catch {
    LogWrite "ERROR emptying Recycle Bin: $_"
}

# 5. Clear Windows Event Logs
try {
    LogWrite "Clearing Event Logs..."
    Get-WinEvent -ListLog * | Where-Object { $_.IsEnabled } | ForEach-Object {
        Clear-WinEvent -LogName $_.LogName -ErrorAction SilentlyContinue
        LogWrite "Cleared event log: $($_.LogName)"
    }
} catch {
    LogWrite "ERROR clearing event logs: $_"
}

# 6. Disk Cleanup (using cleanmgr.exe)
try {
    LogWrite "Running Disk Cleanup..."
    Start-Process -FilePath cleanmgr.exe -ArgumentList "/sagerun:1" -Wait
    LogWrite "Disk Cleanup completed."
} catch {
    LogWrite "ERROR during Disk Cleanup: $_"
}

LogWrite "=== Maintenance Script Completed ==="
