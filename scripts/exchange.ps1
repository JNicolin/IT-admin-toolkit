[CmdletBinding()]
param(
    [switch]$ShowAuditStatus,
    [switch]$EnableUnifiedAuditLog
)

$scriptRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $scriptRoot 'common.ps1')
. (Join-Path $scriptRoot 'config.ps1')

if (-not (Test-CommandAvailable -Name 'Get-AdminAuditLogConfig')) {
    throw 'Exchange Online cmdlets are not available. Run connect.ps1 first.'
}

if ($EnableUnifiedAuditLog) {
    Write-Step 'Enabling unified audit log ingestion'
    Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true
    Write-Ok 'Unified audit log ingestion enabled'
}

if ($ShowAuditStatus -or -not $EnableUnifiedAuditLog) {
    Get-AdminAuditLogConfig | Select-Object UnifiedAuditLogIngestionEnabled
}
