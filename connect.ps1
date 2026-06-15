[CmdletBinding()]
param(
    [switch]$SkipExchange,
    [switch]$SkipGraph,
    [switch]$SkipTeams,
    [switch]$SkipPnP,
    [switch]$ShowCommands
)

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $scriptRoot 'common.ps1')
. (Join-Path $scriptRoot 'config.ps1')

Assert-ConfigLoaded

Import-ToolkitModule -Name 'Microsoft.Graph.Authentication'
Import-ToolkitModule -Name 'ExchangeOnlineManagement'
Import-ToolkitModule -Name 'MicrosoftTeams'

if (-not $SkipGraph -and $Script:ToolkitConfig.ConnectGraph) {
    Write-Step 'Connecting to Microsoft Graph'

    if ($IsMacOS -or $IsLinux) {
        Connect-MgGraph -Scopes $Script:ToolkitConfig.GraphScopes -UseDeviceCode -NoWelcome -ContextScope Process
    }
    else {
        Connect-MgGraph -Scopes $Script:ToolkitConfig.GraphScopes -NoWelcome -ContextScope Process
    }

    Write-Ok 'Microsoft Graph connected'
}

if (-not $SkipExchange -and $Script:ToolkitConfig.ConnectExchange) {
    Write-Step 'Connecting to Exchange Online'

    if ($IsMacOS -or $IsLinux) {
        Connect-ExchangeOnline -UserPrincipalName $Script:ToolkitConfig.AdminUpn -Device -ShowBanner:$false
    }
    else {
        Connect-ExchangeOnline -UserPrincipalName $Script:ToolkitConfig.AdminUpn -ShowBanner:$false
    }

    Write-Ok 'Exchange Online connected'
}

if (-not $SkipTeams -and $Script:ToolkitConfig.ConnectTeams) {
    Write-Step 'Connecting to Microsoft Teams'

    if ($IsMacOS -or $IsLinux) {
        Connect-MicrosoftTeams -UseDeviceAuthentication -AccountId $Script:ToolkitConfig.AdminUpn
    }
    else {
        Connect-MicrosoftTeams -AccountId $Script:ToolkitConfig.AdminUpn
    }

    Write-Ok 'Microsoft Teams connected'
}

if (-not $SkipPnP -and $Script:ToolkitConfig.ConnectPnP) {
    Import-ToolkitModule -Name 'PnP.PowerShell'

    Write-Step 'Connecting to SharePoint via PnP PowerShell'

    if ([string]::IsNullOrWhiteSpace($Script:ToolkitConfig.PnPClientId)) {
        Write-WarnLine 'PnPClientId is not set in config.ps1. Add your Entra app registration client ID before using PnP.'
    }
    else {
        Connect-PnPOnline -Url $Script:ToolkitConfig.SharePointAdminUrl -ClientId $Script:ToolkitConfig.PnPClientId -Interactive
        Write-Ok 'PnP PowerShell connected'
    }
}

if ($ShowCommands) {
    Write-Host ''
    Write-Info 'Useful next commands'
    Write-Host 'pwsh ./validate.ps1'
    Write-Host 'pwsh ./scripts/autopilot.ps1 -ListAutopilotDevices'
    Write-Host 'pwsh ./scripts/entra.ps1 -ListUsers -Top 10'
    Write-Host 'pwsh ./scripts/exchange.ps1 -ShowAuditStatus'
    Write-Host 'pwsh ./scripts/sharepoint.ps1 -ShowWeb'
}