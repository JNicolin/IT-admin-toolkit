[CmdletBinding()]
param(
    [switch]$IncludeAzAccounts,
    [switch]$IncludeBetaGraph
)

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptRoot 'common.ps1')
. (Join-Path $scriptRoot 'config.ps1')

Write-Info 'Starting bootstrap'
Write-Info "PowerShell version: $($PSVersionTable.PSVersion)"
Write-Info "User: $([Environment]::UserName)"
Write-Info "Host OS: $([System.Runtime.InteropServices.RuntimeInformation]::OSDescription)"

$coreModules = @(
    @{ Name = 'ExchangeOnlineManagement'; AllowClobber = $true },
    @{ Name = 'Microsoft.Graph.Authentication' },
    @{ Name = 'Microsoft.Graph.Users' },
    @{ Name = 'Microsoft.Graph.Groups' },
    @{ Name = 'Microsoft.Graph.Identity.DirectoryManagement' },
    @{ Name = 'Microsoft.Graph.DeviceManagement' },
    @{ Name = 'Microsoft.Graph.DeviceManagement.Enrollment' },
    @{ Name = 'Microsoft.Graph.Identity.SignIns' },
    @{ Name = 'MicrosoftTeams'; AllowClobber = $true },
    @{ Name = 'PnP.PowerShell' }
)

foreach ($module in $coreModules) {
    Ensure-Module @module
}

if ($IncludeAzAccounts) {
    Ensure-Module -Name 'Az.Accounts'
}

if ($IncludeBetaGraph) {
    Ensure-Module -Name 'Microsoft.Graph.Beta.DeviceManagement.Enrollment'
}

Write-Ok 'Bootstrap completed'
