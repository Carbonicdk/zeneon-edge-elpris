# Registers the Claude usage helper to start hidden at logon, and starts it now.
$ErrorActionPreference = 'Stop'
$TaskName = 'ElprisWidgetClaudeUsage'
$script = Join-Path $PSScriptRoot 'claude-usage-server.ps1'

$action   = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$script`""
$trigger  = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit ([TimeSpan]::Zero) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Force | Out-Null
Start-ScheduledTask -TaskName $TaskName
Write-Output "Registered and started scheduled task '$TaskName'."
