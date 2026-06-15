[CmdletBinding()]
param(
    [switch]$IncludeAzAccounts,
    [switch]$IncludeBetaGraph,
    [switch]$ResetGraphModules
)

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptRoot 'common.ps1')
. (Join-Path $scriptRoot 'config.ps1')

Write-Info 'Starting bootstrap'
Write-Info "PowerShell version: $($PSVersionTable.PSVersion)"
Write-Info "User: $([Environment]::UserName)"
Write-Info "Host OS: $([System.Runtime.InteropServices.RuntimeInformation]::OSDescription)"

if ($ResetGraphModules) {
    Write-Step 'Resetting installed Microsoft Graph modules'

    $graphModuleNames = @(
        'Microsoft.Graph',
        'Microsoft.Graph.Authentication',
        'Microsoft.Graph.Users',
        'Microsoft.Graph.Groups',
        'Microsoft.Graph.Identity.DirectoryManagement',
        'Microsoft.Graph.DeviceManagement',
        'Microsoft.Graph.DeviceManagement.Enrollment',
        'Microsoft.Graph.Identity.SignIns'
    )

    foreach ($moduleName in $graphModuleNames) {
        $installed = Get-InstalledModule -Name $moduleName -ErrorAction SilentlyContinue
        if ($installed) {
            try {
                Uninstall-Module -Name $moduleName -AllVersions -Force -ErrorAction Stop
                Write-Ok "Removed module: $moduleName"
            }
            catch {
                Write-WarnLine "Could not remove $moduleName. Continuing. $_"
            }
        }
    }
}

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

Write-Ok 'Bootstrap completed, all required modules are installed and imported.'