<#
.SYNOPSIS
  Automates Windows updates, package updates, cache cleanup, and pushes maintenance script to GitHub.

.DESCRIPTION
  - Installs Windows Updates
  - Updates Chocolatey packages
  - Cleans temp files
  - Cleans npm and pip caches if available
  - Prunes Docker images and containers if Docker installed
  - Commits and pushes this script to GitHub repo

.NOTES
  Run as Administrator.
#>

# Config - change if your repo is somewhere else
$repoPath = "$env:USERPROFILE\maintenanceScripts"
$scriptName = "MaintenanceScript.ps1"

function Write-SectionHeader($text) {
    Write-Host "`n=== $text ===" -ForegroundColor Cyan
}

function Run-WindowsUpdate {
    Write-SectionHeader "Windows Update"
    try {
        # Start Windows Update scan & install pending updates
        Install-Module -Name PSWindowsUpdate -Force -ErrorAction SilentlyContinue
        Import-Module PSWindowsUpdate
        $updates = Get-WindowsUpdate -AcceptAll -Install -AutoReboot
        Write-Host "Windows Update complete."
    } catch {
        Write-Host "Failed to run Windows Update. Run PowerShell as Administrator." -ForegroundColor Red
    }
}

function Update-ChocolateyPackages {
    Write-SectionHeader "Chocolatey Package Updates"
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        choco upgrade all -y
        Write-Host "Chocolatey packages upgraded."
    } else {
        Write-Host "Chocolatey not installed. Skipping." -ForegroundColor Yellow
    }
}

function Clean-TempFiles {
    Write-SectionHeader "Cleaning Temporary Files"

    $tempPaths = @(
        "$env:TEMP\*",
        "$env:USERPROFILE\AppData\Local\Temp\*"
    )

    foreach ($path in $tempPaths) {
        try {
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "Cleaned: $path"
        } catch {
            Write-Host "Failed to clean: $path" -ForegroundColor Yellow
        }
    }
}

function Clean-NpmCache {
    Write-SectionHeader "Cleaning npm Cache"
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        npm cache clean --force
        Write-Host "npm cache cleaned."
    } else {
        Write-Host "npm not installed. Skipping." -ForegroundColor Yellow
    }
}

function Clean-PipCache {
    Write-SectionHeader "Cleaning pip Cache"
    if (Get-Command pip -ErrorAction SilentlyContinue) {
        pip cache purge
        Write-Host "pip cache purged."
    } else {
        Write-Host "pip not installed. Skipping." -ForegroundColor Yellow
    }
}

function Prune-Docker {
    Write-SectionHeader "Pruning Docker Images and Containers"
    if (Get-Command docker -ErrorAction SilentlyContinue) {
        try {
            docker system prune -af
            Write-Host "Docker system prune complete."
        } catch {
            Write-Host "Docker prune failed." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Docker not installed. Skipping." -ForegroundColor Yellow
    }
}

function Commit-And-Push-Script {
    Write-SectionHeader "Committing and Pushing Script to GitHub"

    if (-Not (Test-Path $repoPath)) {
        Write-Host "Repository path $repoPath not found. Cloning repo..."
        git clone git@github.com:bentpigeonnz/maintenanceScripts.git $repoPath
        if (-Not (Test-Path $repoPath)) {
            Write-Host "Failed to clone repository. Aborting git push." -ForegroundColor Red
            return
        }
    }

    $scriptFullPath = Join-Path $repoPath $scriptName

    # Save this script's content into the repo path
    $thisScriptPath = $MyInvocation.MyCommand.Path
    if (-not $thisScriptPath) {
        Write-Host "Could not determine current script path, skipping commit." -ForegroundColor Yellow
        return
    }
    Copy-Item $thisScriptPath $scriptFullPath -Force

    Push-Location $repoPath
    try {
        git add $scriptName
        $commitMsg = "Automated maintenance script update on $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
        git commit -m "$commitMsg"
        git push origin main
        Write-Host "Script committed and pushed successfully." -ForegroundColor Green
    } catch {
        Write-Host "Git commit/push failed: $_" -ForegroundColor Red
    }
    Pop-Location
}

# Main

Write-Host "Starting Maintenance Script..." -ForegroundColor Green

Run-WindowsUpdate
Update-ChocolateyPackages
Clean-TempFiles
Clean-NpmCache
Clean-PipCache
Prune-Docker
Commit-And-Push-Script

Write-Host "`nMaintenance Script completed." -ForegroundColor Green
