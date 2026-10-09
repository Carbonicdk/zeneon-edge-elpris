# Serves Claude plan usage to the Elpris widget on http://127.0.0.1:47821/usage.
# Anthropic is only called when the widget asks, i.e. while Claude mode is on screen.
$ErrorActionPreference = 'Stop'
$CredPath = Join-Path $env:USERPROFILE '.claude\.credentials.json'

function Get-Usage {
    $oauth = (Get-Content -Raw $CredPath | ConvertFrom-Json).claudeAiOauth
    if ([DateTimeOffset]::FromUnixTimeMilliseconds($oauth.expiresAt) -lt [DateTimeOffset]::UtcNow) {
        return @{ status = 401; body = @{ error = 'token_expired' } }
    }
    $r = Invoke-RestMethod -Uri 'https://api.anthropic.com/api/oauth/usage' -Headers @{
        Authorization    = "Bearer $($oauth.accessToken)"
        'anthropic-beta' = 'oauth-2025-04-20'
    }
    return @{ status = 200; body = @{
        session = @{ percent = $r.five_hour.utilization; resetsAt = $r.five_hour.resets_at }
        weekly  = @{ percent = $r.seven_day.utilization; resetsAt = $r.seven_day.resets_at }
    } }
}

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add('http://127.0.0.1:47821/')
$listener.Start()

while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    if ($ctx.Request.Url.AbsolutePath -ne '/usage') {
        $result = @{ status = 404; body = @{ error = 'not_found' } }
    } else {
        try { $result = Get-Usage } catch { $result = @{ status = 502; body = @{ error = $_.Exception.Message } } }
    }
    $bytes = [System.Text.Encoding]::UTF8.GetBytes(($result.body | ConvertTo-Json -Compress))
    $res = $ctx.Response
    $res.StatusCode = $result.status
    $res.ContentType = 'application/json'
    $res.Headers['Access-Control-Allow-Origin'] = '*'
    $res.OutputStream.Write($bytes, 0, $bytes.Length)
    $res.Close()
}
