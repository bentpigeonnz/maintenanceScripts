# 🧰 Windows Maintenance Automation Script

This PowerShell script automates common Windows 11 system maintenance tasks including event log clearing, temporary file cleanup, Windows updates, GitHub backups, and error reporting via email. It’s designed for personal use, homelabs, or anyone who wants automated, hands-off system upkeep.

---

## ✅ Features

- 🔄 **Event Log Clearing** – Clears all event logs using `wevtutil`
- 🧹 **Temporary File Cleanup** – Deletes system and user temporary files
- 🛠️ **Windows Updates** – Automatically checks for and installs available updates
- 🗃️ **Log File Rotation** – Logs are rotated daily and archived after 7 days
- 📧 **Email Error Alerts** – Sends a summary of any script errors via Gmail SMTP
- 🔁 **GitHub Sync** – Commits and pushes changes to a private or public GitHub repository

---

## 📁 Folder Structure

maintenanceScripts/
├── maintenance.ps1 # The main automation script
├── README.md # Documentation file (this file)
├── logs/
│ ├── maintenance_YYYYMMDD.log # Daily log file
│ └── archive/ # Archived logs older than 7 days

---

## 📬 Email Alerts

If the script encounters errors (e.g., failed cleanup, update issues, Git push failures), it sends a summary to your configured Gmail account.

### 🔐 Gmail App Password Setup

> Google requires you to use an "App Password" instead of your normal password.

1. Go to [https://myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords)
2. Sign in and select:
   - **App**: "Other (Custom name)"
   - **Name**: `MaintenanceScript`
3. Copy the 16-character password it generates
4. In `maintenance.ps1`, replace:

```powershell
$smtpPass = "your-app-password-here"
