# Maintenance Script

Automated Windows maintenance and developer environment update script for personal or professional use. This PowerShell script helps keep your system clean, updated, and synchronized with your GitHub repository while sending email alerts on failure.

---

## Overview

This script performs a full maintenance routine including:

- Clearing all Windows Event Logs to help diagnose fresh issues more easily.
- Cleaning temporary file directories to free disk space and improve performance.
- Checking for and installing all pending Windows software updates.
- Updating all development tools managed by [Chocolatey](https://chocolatey.org/).
- Rotating and archiving log files older than a configurable retention period.
- Automatically committing and pushing script changes to a specified GitHub repository.
- Sending detailed email alerts if any step encounters an error.

---

## Features

| Feature                     | Description                                                                                   |
|-----------------------------|-----------------------------------------------------------------------------------------------|
| **Event Logs Cleanup**       | Uses Windows built-in `wevtutil` utility to clear all event logs.                            |
| **Temp Files Cleanup**       | Deletes files from user and system temporary folders to free disk space.                     |
| **Windows Updates**          | Searches for, downloads, and installs all available software updates automatically.         |
| **Developer Tools Update**   | Uses Chocolatey to upgrade all installed development-related software packages.              |
| **Log Rotation**             | Moves logs older than 7 days into an `archive` subfolder to keep log directory manageable.   |
| **GitHub Integration**       | Detects changes, commits with timestamped message, and pushes to the remote GitHub repo.     |
| **Email Notifications**      | Sends error reports via SMTP email if any failures occur during the maintenance run.         |

---

## Folder Structure

```plaintext
maintenanceScripts\
├── Maintenance.ps1          # Main PowerShell maintenance script
├── logs\                   # Directory holding daily logs and archived logs
│   ├── maintenance_YYYYMMDD.log  # Log file for each day the script runs
│   └── archive\            # Subfolder for log files older than retention period (default 7 days)
└── README.md               # This documentation file
