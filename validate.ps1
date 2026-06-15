[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptRoot 'common.ps1')
. (Join-Path $scriptRoot 'config.ps1')

Write-Host ''
Write-Step 'Running validation'
Write-Host ''

# Exchange
Write-Info 'Exchange validation'

if (Test-CommandAvailable -Name 'Get-AdminAuditLogConfig') {
    $audit = Get-AdminAuditLogConfig
    Write-Ok 'Exchange connected'
    $audit | Select-Object UnifiedAuditLogIngestionEnabled
}
else {
    Write-WarnLine 'Exchange cmdlets are not available in this session.'
}

Write-Host ''

# Graph
Write-Info 'Graph validation'

if (Test-CommandAvailable -Name 'Get-MgContext') {
    $ctx = Get-MgContext
    if ($ctx -and $ctx.Account) {
        Write-Ok "Graph connected as $($ctx.Account)"
        $ctx | Select-Object TenantId, Account, AppName, AuthType
    }
    else {
        Write-WarnLine 'Graph context is not properly initialized.'
    }
}
else {
    Write-WarnLine 'Graph cmdlets are not available in this session.'
}

Write-Host ''

# Teams
Write-Info 'Teams validation'

if (Test-CommandAvailable -Name 'Get-CsTenant') {
    $tenant = Get-CsTenant
    if ($tenant) {
        Write-Ok "Teams connected: $($tenant.DisplayName)"
        $tenant | Select-Object DisplayName, TenantId
    }
    else {
        Write-WarnLine 'Teams connection could not be verified.'
    }
}
else {
    Write-WarnLine 'Teams cmdlets are not available in this session.'
}

Write-Host ''

# PnP
Write-Step 'PnP validation'

try {
    $context = Get-PnPContext -ErrorAction Stop

    if (-not $context) {
        Write-WarnLine 'PnP is not connected.'
        Write-Host 'Action: Run ./connect.ps1' -ForegroundColor DarkYellow
    }
    else {
        $web = Get-PnPWeb -ErrorAction SilentlyContinue

        if (-not $web) {
            Write-WarnLine 'PnP is connected, but no site context is set.'
            Write-Host 'Action: Run ./scripts/sharepoint.ps1 -Reconnect -SiteUrl <your-site-url>' -ForegroundColor DarkYellow
        }
        else {
            Write-Ok "PnP connected to site: $($web.Url)"
        }
    }
}
catch {
    Write-WarnLine 'PnP validation failed.'
    Write-Host $_ -ForegroundColor DarkYellow
}

Write-Host ''
Write-Ok 'Validation completed'
Write-Host ''
