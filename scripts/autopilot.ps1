[CmdletBinding()]
param(
    [switch]$ListAutopilotDevices,
    [switch]$ListManagedDevices,
    [switch]$ListCompliantDevices,
    [switch]$ListNonCompliantDevices,
    [switch]$ListDevicesWithoutUser,
    [string]$SerialNumber,
    [int]$Top = 25,
    [switch]$Table,
    [switch]$Export
)

$scriptRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $scriptRoot 'common.ps1')
. (Join-Path $scriptRoot 'config.ps1')

if (-not (Test-CommandAvailable -Name 'Get-MgContext')) {
    throw 'Microsoft Graph is not connected. Run connect.ps1 first.'
}

$results = $null
$view = @()

# ✅ Autopilot devices
if ($ListAutopilotDevices -or $SerialNumber) {
    Write-Step 'Getting Windows Autopilot device identities'

    $params = @{
        All      = $true
        Property = @(
            'displayName',
            'serialNumber',
            'manufacturer',
            'model',
            'groupTag',
            'deploymentProfileAssignmentStatus',
            'lastContactedDateTime'
        )
    }

    if ($SerialNumber) {
        $params.Filter = "contains(serialNumber,'$SerialNumber')"
    }

    $results = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity @params |
        Select-Object DisplayName, SerialNumber, Manufacturer, Model, GroupTag, DeploymentProfileAssignmentStatus, LastContactedDateTime |
        Select-Object -First $Top

    $view = @(
        'DisplayName',
        'SerialNumber',
        'Manufacturer',
        'Model',
        'GroupTag',
        'DeploymentProfileAssignmentStatus',
        'LastContactedDateTime'
    )
}

# ✅ Managed devices
elseif ($ListManagedDevices) {
    Write-Step 'Getting Intune managed devices'

    $results = Get-MgDeviceManagementManagedDevice -All -Property @(
        'deviceName',
        'operatingSystem',
        'complianceState',
        'userPrincipalName',
        'lastSyncDateTime',
        'id'
    ) |
    Select-Object DeviceName, OperatingSystem, ComplianceState, UserPrincipalName, LastSyncDateTime, Id |
    Select-Object -First $Top

    $view = @(
        'DeviceName',
        'OperatingSystem',
        'ComplianceState',
        'UserPrincipalName',
        'LastSyncDateTime',
        'Id'
    )
}

# ✅ Compliant devices
elseif ($ListCompliantDevices) {
    Write-Step 'Getting compliant devices'

    $results = Get-MgDeviceManagementManagedDevice -Filter "complianceState eq 'compliant'" -All -Property @(
        'deviceName',
        'operatingSystem',
        'userPrincipalName',
        'lastSyncDateTime',
        'id'
    ) |
    Select-Object DeviceName, OperatingSystem, UserPrincipalName, LastSyncDateTime, Id |
    Select-Object -First $Top

    $view = @(
        'DeviceName',
        'OperatingSystem',
        'UserPrincipalName',
        'LastSyncDateTime',
        'Id'
    )
}

# ✅ Non-compliant devices
elseif ($ListNonCompliantDevices) {
    Write-Step 'Getting non-compliant devices'

    $results = Get-MgDeviceManagementManagedDevice -Filter "complianceState ne 'compliant'" -All -Property @(
        'deviceName',
        'operatingSystem',
        'complianceState',
        'userPrincipalName',
        'lastSyncDateTime',
        'id'
    ) |
    Select-Object DeviceName, OperatingSystem, ComplianceState, UserPrincipalName, LastSyncDateTime, Id |
    Select-Object -First $Top

    $view = @(
        'DeviceName',
        'OperatingSystem',
        'ComplianceState',
        'UserPrincipalName',
        'LastSyncDateTime',
        'Id'
    )
}

# ✅ Devices without user
elseif ($ListDevicesWithoutUser) {
    Write-Step 'Getting devices without assigned user'

    $results = Get-MgDeviceManagementManagedDevice -All -Property @(
        'deviceName',
        'operatingSystem',
        'userPrincipalName',
        'lastSyncDateTime',
        'id'
    ) |
    Where-Object { -not $_.UserPrincipalName } |
    Select-Object DeviceName, OperatingSystem, LastSyncDateTime, Id |
    Select-Object -First $Top

    $view = @(
        'DeviceName',
        'OperatingSystem',
        'LastSyncDateTime',
        'Id'
    )
}

else {
    Write-WarnLine 'No action selected. Use -ListAutopilotDevices, -ListManagedDevices, -ListCompliantDevices, -ListNonCompliantDevices, -ListDevicesWithoutUser or -SerialNumber.'
    return
}

# ✅ Central output
Show-ToolkitOutput -Data $results -View $view -Table:$Table

# ✅ Export
if ($Export) {
    Export-ToolkitCsv -InputObject $results -Name 'autopilot-devices' -ScriptName 'autopilot'
}