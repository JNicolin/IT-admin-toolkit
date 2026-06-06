# Copy to config.ps1 and adjust values for your tenant.
# Do not commit config.ps1.

$Script:ToolkitConfig = [ordered]@{
    TenantName         = 'yieldit'
    TenantId           = ''
    AdminUpn           = 'adm_johnic@yieldit.se'
    SharePointAdminUrl = 'https://yieldit-admin.sharepoint.com'
    SharePointRootUrl  = 'https://yieldit.sharepoint.com'

    InstallForCurrentUser = $true
    UpdateExistingModules = $false

    ConnectExchange = $true
    ConnectGraph    = $true
    ConnectTeams    = $true
    ConnectPnP      = $true

    GraphScopes = @(
        'User.Read.All'
        'Group.Read.All'
        'Directory.Read.All'
        'Device.Read.All'
        'DeviceManagementManagedDevices.Read.All'
        'DeviceManagementConfiguration.Read.All'
        'DeviceManagementServiceConfig.Read.All'
        'AuditLog.Read.All'
        'Organization.Read.All'
    )

    # PnP requires your own Entra app registration for interactive auth.
    PnPClientId = ''

    DefaultExportPath = './output'
}
