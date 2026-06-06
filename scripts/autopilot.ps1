[CmdletBinding()]
param(
    [switch]$ListAutopilotDevices,
    [switch]$ListManagedDevices,
    [string]$SerialNumber,
    [int]$Top = 25,
    [switch]$Export
)

$scriptRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
. (Join-Path $scriptRoot 'common.ps1')
. (Join-Path $scriptRoot 'config.ps1')

if (-not (Test-CommandAvailable -Name 'Get-MgContext')) {
    throw 'Microsoft Graph is not connected. Run connect.ps1 first.'
}

$results = $null

if ($ListAutopilotDevices -or $SerialNumber) {
    Write-Step 'Getting Windows Autopilot device identities'
    $params = @{
        All      = $true
        Property = @('id','serialNumber','manufacturer','model','groupTag','deploymentProfileAssignmentStatus','lastContactedDateTime','managedDeviceId','displayName')
    }
    if ($SerialNumber) {
        $params.Filter = "contains(serialNumber,'$SerialNumber')"
    }

    $results = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity @params |
        Select-Object DisplayName, SerialNumber, Manufacturer, Model, GroupTag, DeploymentProfileAssignmentStatus, ManagedDeviceId, LastContactedDateTime |
        Select-Object -First $Top
}
elseif ($ListManagedDevices) {
    Write-Step 'Getting Intune managed devices'
    $results = Get-MgDeviceManagementManagedDevice -All -Property 'id,deviceName,operatingSystem,complianceState,userPrincipalName,lastSyncDateTime' |
        Select-Object DeviceName, OperatingSystem, ComplianceState, UserPrincipalName, LastSyncDateTime, Id |
        Select-Object -First $Top
}
else {
    Write-WarnLine 'No action selected. Use -ListAutopilotDevices, -ListManagedDevices or -SerialNumber.'
    return
}

$results | Format-Table -AutoSize

if ($Export) {
    Export-ToolkitCsv -InputObject $results -Name 'autopilot-devices'
}
