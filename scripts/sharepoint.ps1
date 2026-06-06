[CmdletBinding()]
param(
    [string]$SiteUrl,
    [switch]$ShowWeb,
    [switch]$Reconnect,
    [switch]$Export
)

$scriptRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $scriptRoot 'common.ps1')
. (Join-Path $scriptRoot 'config.ps1')

if (-not (Test-CommandAvailable -Name 'Get-PnPWeb')) {
    throw 'PnP PowerShell cmdlets are not available. Run connect.ps1 first.'
}

if ($Reconnect) {
    if ([string]::IsNullOrWhiteSpace($SiteUrl)) {
        throw 'Provide -SiteUrl when using -Reconnect.'
    }
    if ([string]::IsNullOrWhiteSpace($Script:ToolkitConfig.PnPClientId)) {
        throw 'PnPClientId is missing in config.ps1.'
    }
    Connect-PnPOnline -Url $SiteUrl -ClientId $Script:ToolkitConfig.PnPClientId -Interactive
}

if ($ShowWeb) {
    $result = Get-PnPWeb | Select-Object Title, Url, Description, WebTemplate
    $result | Format-Table -AutoSize
    if ($Export) {
        Export-ToolkitCsv -InputObject $result -Name 'sharepoint-web'
    }
}
else {
    Write-WarnLine 'No action selected. Use -ShowWeb or -Reconnect with -SiteUrl.'
}
