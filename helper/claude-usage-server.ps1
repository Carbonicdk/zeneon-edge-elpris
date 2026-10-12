# Serves Claude plan usage and "Claude is working" status to the Elpris widget on http://127.0.0.1:47821.
# Anthropic is only called when the widget asks, i.e. while Claude mode is on screen.
# Claude Code hooks POST to /hook/start and /hook/stop to mark sessions busy or idle, and to
# /hook/agent-start and /hook/agent-stop for subagents, which keep working after the main turn ends.
$ErrorActionPreference = 'Stop'
$CredPath = Join-Path $env:USERPROFILE '.claude\.credentials.json'
$UsageTtl = [TimeSpan]::FromMinutes(5)
$busy = @{}
# One cached answer shared by every widget instance; Anthropic rate-limits this endpoint.
# A 429 is cached too, until its Retry-After, so nobody keeps hitting the limit.
$usageCache = $null

function Get-Usage {
    if ($script:usageCache -and [DateTime]::UtcNow -lt $script:usageCache.expires) { return $script:usageCache.result }

    $oauth = (Get-Content -Raw $CredPath | ConvertFrom-Json).claudeAiOauth
    if ([DateTimeOffset]::FromUnixTimeMilliseconds($oauth.expiresAt) -lt [DateTimeOffset]::UtcNow) {
        return @{ status = 401; body = @{ error = 'token_expired' } }
    }
    try {
        $r = Invoke-RestMethod -Uri 'https://api.anthropic.com/api/oauth/usage' -Headers @{
            Authorization    = "Bearer $($oauth.accessToken)"
            'anthropic-beta' = 'oauth-2025-04-20'
        }
    } catch [System.Net.WebException] {
        $resp = $_.Exception.Response
        if (-not $resp -or [int]$resp.StatusCode -ne 429) { throw }
        # Anthropic sends Retry-After: 0, so wait at least one TTL before trying again.
        $seconds = 0
        [void][int]::TryParse($resp.Headers['Retry-After'], [ref]$seconds)
        $until = [DateTime]::UtcNow.AddSeconds([Math]::Max($seconds, $UsageTtl.TotalSeconds))
        $result = @{ status = 429; body = @{ error = 'rate_limited'; retryAt = $until.ToString('o') } }
        $script:usageCache = @{ result = $result; expires = $until }
        return $result
    }
    $result = @{ status = 200; body = @{
        session   = @{ percent = $r.five_hour.utilization; resetsAt = $r.five_hour.resets_at }
        weekly    = @{ percent = $r.seven_day.utilization; resetsAt = $r.seven_day.resets_at }
        fetchedAt = [DateTime]::UtcNow.ToString('o')
    } }
    $script:usageCache = @{ result = $result; expires = [DateTime]::UtcNow.Add($UsageTtl) }
    return $result
}

function Read-HookField($request, $field) {
    $reader = [System.IO.StreamReader]::new($request.InputStream, [System.Text.Encoding]::UTF8)
    $value = ($reader.ReadToEnd() | ConvertFrom-Json).$field
    if (-not $value) { throw "Hook payload has no $field" }
    return $value
}

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add('http://127.0.0.1:47821/')
$listener.Start()

while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    try {
        switch ($ctx.Request.Url.AbsolutePath) {
            '/usage'      { $result = Get-Usage }
            '/status'     { $result = @{ status = 200; body = @{ working = $busy.Count -gt 0 } } }
            '/hook/start'       { $busy['session:' + (Read-HookField $ctx.Request 'session_id')] = $true; $result = @{ status = 200; body = @{ ok = $true } } }
            '/hook/stop'        { $busy.Remove('session:' + (Read-HookField $ctx.Request 'session_id')); $result = @{ status = 200; body = @{ ok = $true } } }
            '/hook/agent-start' { $busy['agent:' + (Read-HookField $ctx.Request 'agent_id')] = $true; $result = @{ status = 200; body = @{ ok = $true } } }
            '/hook/agent-stop'  { $busy.Remove('agent:' + (Read-HookField $ctx.Request 'agent_id')); $result = @{ status = 200; body = @{ ok = $true } } }
            default       { $result = @{ status = 404; body = @{ error = 'not_found' } } }
        }
    } catch {
        $result = @{ status = 502; body = @{ error = $_.Exception.Message } }
    }
    $bytes = [System.Text.Encoding]::UTF8.GetBytes(($result.body | ConvertTo-Json -Compress))
    $res = $ctx.Response
    $res.StatusCode = $result.status
    $res.ContentType = 'application/json'
    $res.Headers['Access-Control-Allow-Origin'] = '*'
    $res.OutputStream.Write($bytes, 0, $bytes.Length)
    $res.Close()
}
