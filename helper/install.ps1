# Registers the Claude usage helper to start hidden at logon, and starts it now.
$ErrorActionPreference = 'Stop'
$TaskName = 'ElprisWidgetClaudeUsage'
$script = Join-Path $PSScriptRoot 'claude-usage-server.ps1'

# conhost --headless gives the helper no window at all; with Windows Terminal as default terminal,
# powershell -WindowStyle Hidden opens a visible terminal tab, and closing it kills the helper.
$action   = New-ScheduledTaskAction -Execute 'conhost.exe' -Argument "--headless powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$script`""
$trigger  = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit ([TimeSpan]::Zero) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Force | Out-Null
Start-ScheduledTask -TaskName $TaskName
Write-Output "Registered and started scheduled task '$TaskName'."
