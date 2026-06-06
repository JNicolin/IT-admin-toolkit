[CmdletBinding()]
param()

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptRoot 'common.ps1')
. (Join-Path $scriptRoot 'config.ps1')

Write-Step 'Running validation'

if (Test-CommandAvailable -Name 'Get-AdminAuditLogConfig') {
    Write-Info 'Exchange validation'
    Get-AdminAuditLogConfig | Select-Object UnifiedAuditLogIngestionEnabled
} else {
    Write-WarnLine 'Exchange cmdlets are not available in this session.'
}

if (Test-CommandAvailable -Name 'Get-MgContext') {
    Write-Info 'Graph validation'
    Get-MgContext | Select-Object TenantId, Account, AppName, AuthType
} else {
    Write-WarnLine 'Graph cmdlets are not available in this session.'
}

if (Test-CommandAvailable -Name 'Get-CsTenant') {
    Write-Info 'Teams validation'
    Get-CsTenant | Select-Object DisplayName, TenantId
} else {
    Write-WarnLine 'Teams cmdlets are not available in this session.'
}

if (Test-CommandAvailable -Name 'Get-PnPWeb') {
    Write-Info 'PnP validation'
    try {
        Get-PnPWeb | Select-Object Title, Url
    }
    catch {
        Write-WarnLine 'PnP connection is not ready or site context is missing.'
    }
} else {
    Write-WarnLine 'PnP cmdlets are not available in this session.'
}

Write-Ok 'Validation completed'
